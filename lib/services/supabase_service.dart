import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/ncap_repository.dart';
import '../data/seed_careers.dart' as local_careers;
import '../models/career_models.dart';

const _supabaseUrl = 'https://fbirnwlmbvlfqdnbdjpv.supabase.co';
const _supabaseAnonKey = 'sb_publishable_p4Grq0m-AHvuvx2pY1FL_A_lZ50goPE';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> init() async {
    await Supabase.initialize(
      url: _supabaseUrl,
      publishableKey: _supabaseAnonKey,
    );
  }

  static bool get isConfigured =>
      _supabaseUrl != 'YOUR_SUPABASE_URL' &&
      _supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY';

  static String imageUrl(String path) {
    if (!isConfigured) return '';
    return client.storage.from('university-images').getPublicUrl(path);
  }

  // ---- Auth ---------------------------------------------------------------

  static User? get currentUser => client.auth.currentUser;
  static Session? get currentSession => client.auth.currentSession;
  static bool get isSignedIn => currentSession != null;

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String idNumber,
  }) async {
    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'id_number': idNumber,
      },
    );

    if (response.user != null) {
      await upsertProfile(
        userId: response.user!.id,
        fullName: fullName,
        idNumber: idNumber,
        email: email,
      );
    }

    return response;
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  static Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  // ---- Profiles table -----------------------------------------------------

  static Future<void> upsertProfile({
    required String userId,
    required String fullName,
    required String idNumber,
    required String email,
  }) async {
    try {
      await client.from('profiles').upsert({
        'id': userId,
        'full_name': fullName,
        'id_number': idNumber,
        'email': email,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Profile upsert failed: $e');
    }
  }

  static Future<Map<String, dynamic>?> fetchProfile(String userId) async {
    try {
      final data = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return data;
    } catch (e) {
      debugPrint('Profile fetch failed: $e');
      return null;
    }
  }

  static Future<void> updateProfile(
      String userId, Map<String, dynamic> fields) async {
    try {
      await client.from('profiles').update({
        ...fields,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      debugPrint('Profile update failed: $e');
    }
  }
}

class KhethaDatabase {
  static final _client = SupabaseService.client;

  static Future<List<LearningProvider>> fetchProviders({
    String? province,
  }) async {
    var query = _client.from('learning_providers').select();
    if (province != null) query = query.eq('province', province);
    final data = await query.order('name');
    return data.map((r) => _providerFromRow(r)).toList();
  }

  static LearningProvider _providerFromRow(Map<String, dynamic> r) {
    return LearningProvider(
      id: r['id'] as String,
      name: r['name'] as String,
      abbreviation: r['abbreviation'] as String?,
      province: r['province'] as String,
      town: (r['town'] as String?) ?? '',
      type: r['type'] as String,
      description: r['description'] as String?,
      totalStudents: r['total_students'] as int?,
      email: r['email'] as String?,
      phone: r['phone'] as String?,
      website: (r['website'] as String?) ?? '',
      nsfasAccredited: (r['nsfas_accredited'] as bool?) ?? true,
      offeredFields: _strList(r['offered_fields']),
      imageUrl: r['image_url'] as String?,
      logoUrl: r['logo_url'] as String?,
      heroImageUrl: r['hero_image_url'] as String?,
    );
  }

  static Future<List<Map<String, dynamic>>> fetchCareers({
    String? sector,
  }) async {
    var query = _client.from('careers').select();
    if (sector != null) query = query.eq('sector', sector);
    final data = await query.order('title');
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<List<Map<String, dynamic>>> fetchQualifications({
    String? field,
  }) async {
    var query = _client.from('qualifications').select();
    if (field != null) query = query.eq('field', field);
    final data = await query.order('title');
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<List<Map<String, dynamic>>> fetchBursaries({
    bool activeOnly = true,
  }) async {
    var query = _client.from('bursaries').select();
    if (activeOnly) query = query.eq('is_active', true);
    final data = await query.order('closing_date');
    return List<Map<String, dynamic>>.from(data);
  }

  static List<String> _strList(Object? raw) {
    if (raw is List) return raw.cast<String>();
    return [];
  }
}

class SupabaseDataSource implements NcapDataSource {
  const SupabaseDataSource();

  @override
  String get sourceName => 'Khetha Go Cloud Database';

  @override
  String get sourceDescription =>
      'Live data from the Khetha Go Supabase database, updated by the DHET content team.';

  @override
  bool get isOffline => false;

  @override
  Future<List<Career>> careers() async {
    if (!SupabaseService.isConfigured) return local_careers.careers;
    try {
      final data = await KhethaDatabase.fetchCareers();
      if (data.isEmpty) return local_careers.careers;
      return data.map((r) => _careerFromRow(r)).toList();
    } catch (_) {
      return local_careers.careers;
    }
  }

  Career _careerFromRow(Map<String, dynamic> row) {
    final riasecRaw = row['riasec'] as Map<String, dynamic>? ?? {};
    final riasec = <Riasec, double>{};
    for (final r in Riasec.values) {
      final key = r.code;
      if (riasecRaw.containsKey(key)) {
        riasec[r] = (riasecRaw[key] as num).toDouble();
      }
    }

    return Career(
      id: row['id'] as String,
      title: row['title'] as String,
      ofoCode: (row['ofo_code'] as String?) ?? '',
      description: row['description'] as String,
      dayInTheLife: (row['day_in_the_life'] as String?) ?? '',
      sector: row['sector'] as String,
      requiredSubjects: _strList(row['required_subjects']),
      helpfulSubjects: _strList(row['helpful_subjects']),
      traits: _strList(row['traits']),
      riasec: riasec,
      studyPathway: (row['study_pathway'] as String?) ?? '',
      minQualification: (row['min_qualification'] as String?) ?? '',
      nqfLevel: (row['nqf_level'] as String?) ?? '',
      entrySalaryBand: (row['entry_salary_band'] as String?) ?? '',
      experiencedSalaryBand: (row['experienced_salary_band'] as String?) ?? '',
      demand: _parseDemand(row['demand'] as String?),
      scarceSkill: (row['scarce_skill'] as bool?) ?? false,
      relatedCareerIds: _strList(row['related_career_ids']),
    );
  }

  List<String> _strList(Object? raw) {
    if (raw is List) return raw.cast<String>();
    return [];
  }

  Demand _parseDemand(String? s) => switch (s) {
        'high' => Demand.high,
        'moderate' => Demand.moderate,
        _ => Demand.stable,
      };

  @override
  Future<List<Qualification>> qualifications() async =>
      const LocalSeedSource().qualifications();

  @override
  Future<List<LearningProvider>> providers() async {
    if (!SupabaseService.isConfigured) {
      debugPrint('Supabase not configured, using local seed');
      return const LocalSeedSource().providers();
    }
    try {
      final list = await KhethaDatabase.fetchProviders();
      debugPrint('Supabase fetched ${list.length} providers');
      if (list.isEmpty) return const LocalSeedSource().providers();
      return list;
    } catch (e) {
      debugPrint('Supabase provider fetch failed: $e');
      return const LocalSeedSource().providers();
    }
  }

  @override
  Future<List<QuizQuestion>> jobFitQuestions() async =>
      const LocalSeedSource().jobFitQuestions();

  @override
  Future<List<QuizQuestion>> careerChoiceQuestions() async =>
      const LocalSeedSource().careerChoiceQuestions();

  @override
  Future<List<AdviceChannel>> adviceChannels() async =>
      const LocalSeedSource().adviceChannels();

  @override
  Future<List<CareerEvent>> events() async =>
      const LocalSeedSource().events();

  @override
  Future<Map<String, List<String>>> subjectsByField() async =>
      const LocalSeedSource().subjectsByField();

  @override
  Future<List<Tutor>> tutors() async =>
      const LocalSeedSource().tutors();
}
