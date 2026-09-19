import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/application_models.dart';
import '../models/career_models.dart';
import '../models/funding_models.dart';
import '../models/results_models.dart';
import '../services/notification_service.dart';

enum AppearanceMode { system, light, dark }

/// Language codes the interface is available in. Content translation beyond
/// the interface is staged, and the app says so rather than implying full
/// coverage it does not have.
enum AppLanguage { en, zu, xh, st, af }

extension AppLanguageMeta on AppLanguage {
  String get nativeName => switch (this) {
        AppLanguage.en => 'English',
        AppLanguage.zu => 'isiZulu',
        AppLanguage.xh => 'isiXhosa',
        AppLanguage.st => 'Sesotho',
        AppLanguage.af => 'Afrikaans',
      };
}

/// Application state and the single owner of everything persisted.
///
/// All of it lives in the app's private storage on the device. There is no
/// account, no server and no analytics endpoint - which is what lets the
/// Privacy screen make a claim that can actually be verified.
class AppState extends ChangeNotifier {
  AppState(this._prefs) {
    _restore();
  }

  final SharedPreferences _prefs;

  UserProfile profile = UserProfile();
  AppearanceMode appearance = AppearanceMode.light;
  AppLanguage language = AppLanguage.en;

  /// In-app text size multiplier, on top of the system Dynamic Type setting.
  /// Present because a learner on a shared or older phone may not know how to
  /// change the system setting, and readability should not depend on that.
  double textScale = 1.0;

  /// Turns off blur, gradients and ambient layers. Named for what it buys the
  /// user - fewer GPU cycles and a longer battery on an entry-level device —
  /// rather than for the effect it disables.
  bool lowBandwidthMode = false;

  bool remindersEnabled = false;

  // ---- Supabase auth ----------------------------------------------------
  bool _supabaseAuthenticated = false;
  bool get isSupabaseAuthenticated => _supabaseAuthenticated;
  void setSupabaseAuthenticated(bool v) {
    _supabaseAuthenticated = v;
    if (v) _prefs.setBool('supabaseAuthenticated', true);
    notifyListeners();
  }

  // ---- Security --------------------------------------------------------
  String? _pin;
  bool get hasPin => _pin != null;
  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;
  set isAuthenticated(bool v) {
    if (_isAuthenticated == v) return;
    _isAuthenticated = v;
    notifyListeners();
  }
  bool biometricEnabled = false;

  static final _localAuth = LocalAuthentication();

  Future<bool> get canUseBiometrics async {
    try {
      final available = await _localAuth.canCheckBiometrics;
      final deviceSupported = await _localAuth.isDeviceSupported();
      return available && deviceSupported;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      final success = await _localAuth.authenticate(
        localizedReason: 'Unlock Khetha Go with biometrics',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      if (success) isAuthenticated = true;
      return success;
    } catch (_) {
      return false;
    }
  }

  Future<void> setBiometricEnabled(bool v) async {
    biometricEnabled = v;
    await _prefs.setBool('biometricEnabled', v);
    notifyListeners();
  }

  bool verifyPin(String pin) {
    if (_pin == null) return false;
    final matches = _pin == pin;
    if (matches) isAuthenticated = true;
    return matches;
  }

  Future<void> setPin(String pin) async {
    _pin = pin;
    isAuthenticated = true;
    await _prefs.setString('pin', pin);
    notifyListeners();
  }

  Future<void> removePin() async {
    _pin = null;
    isAuthenticated = true;
    biometricEnabled = false;
    await _prefs.remove('pin');
    await _prefs.setBool('biometricEnabled', false);
    notifyListeners();
  }

  // ---- Consent ---------------------------------------------------------
  /// Explicit, separable consent per purpose, as POPIA requires. Each one is
  /// off until the person turns it on, and turning one off takes effect
  /// immediately rather than at next launch.
  bool consentStoreProfile = false;
  bool consentReminders = false;
  bool consentPersonalisation = false;
  bool hasSeenWelcome = false;

  /// Acceptance of the terms and the privacy notice. Recorded separately from
  /// onboarding completion so a change to the terms can ask again without
  /// putting the learner back through the whole introduction.
  bool acceptedTerms = false;
  bool hasCompletedOnboarding = false;

  // ---- Results and applications -----------------------------------------
  MatricResults? results;
  String? idNumber;
  List<ApplicationDocument> documents = [];
  List<InstitutionApplication> applications = [];

  // ---- Funding -----------------------------------------------------------
  NsfasApplication? nsfasApplication;
  List<BursaryApplication> bursaryApplications = [];

  String? heroBannerUrl;

  bool get visualEffectsEnabled => !lowBandwidthMode;

  Brightness? get forcedBrightness => switch (appearance) {
        AppearanceMode.system => null,
        AppearanceMode.light => Brightness.light,
        AppearanceMode.dark => Brightness.dark,
      };

  // ---- Restore / persist ------------------------------------------------
  void _restore() {
    _supabaseAuthenticated = _prefs.getBool('supabaseAuthenticated') ?? false;
    _pin = _prefs.getString('pin');
    biometricEnabled = _prefs.getBool('biometricEnabled') ?? false;
    hasSeenWelcome = _prefs.getBool('hasSeenWelcome') ?? false;
    consentStoreProfile = _prefs.getBool('consentStoreProfile') ?? false;
    consentReminders = _prefs.getBool('consentReminders') ?? false;
    consentPersonalisation = _prefs.getBool('consentPersonalisation') ?? false;
    remindersEnabled = _prefs.getBool('remindersEnabled') ?? false;
    lowBandwidthMode = _prefs.getBool('lowBandwidthMode') ?? false;
    textScale = _prefs.getDouble('textScale') ?? 1.0;

    final appearanceIndex = _prefs.getInt('appearance') ?? 1;
    appearance = AppearanceMode.values[
        appearanceIndex.clamp(0, AppearanceMode.values.length - 1)];

    final langIndex = _prefs.getInt('language') ?? 0;
    language =
        AppLanguage.values[langIndex.clamp(0, AppLanguage.values.length - 1)];

    acceptedTerms = _prefs.getBool('acceptedTerms') ?? false;
    hasCompletedOnboarding = _prefs.getBool('hasCompletedOnboarding') ?? false;

    // The profile is only read back if the person consented to it being kept.
    if (consentStoreProfile) {
      final raw = _prefs.getString('profile');
      if (raw != null) {
        try {
          profile = UserProfile.fromJson(
              jsonDecode(raw) as Map<String, dynamic>);
        } catch (_) {
          profile = UserProfile();
        }
      }

      results = _decode('results', MatricResults.fromJson);
      idNumber = _prefs.getString('idNumber');
      documents = _decodeList('documents', ApplicationDocument.fromJson);
      applications = _decodeList('applications', InstitutionApplication.fromJson);
      nsfasApplication = _decode('nsfasApplication', NsfasApplication.fromJson);
      bursaryApplications = _decodeList('bursaryApplications', BursaryApplication.fromJson);
    }
  }

  T? _decode<T>(String key, T? Function(Object?) parse) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      return parse(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  List<T> _decodeList<T>(String key, T? Function(Object?) parse) {
    final raw = _prefs.getString(key);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded.map(parse).whereType<T>().toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _persistApplications() async {
    if (!consentStoreProfile) return;
    await _prefs.setString('documents',
        jsonEncode(documents.map((d) => d.toJson()).toList()));
    await _prefs.setString('applications',
        jsonEncode(applications.map((a) => a.toJson()).toList()));
    if (idNumber != null) await _prefs.setString('idNumber', idNumber!);
    if (nsfasApplication != null) {
      await _prefs.setString(
          'nsfasApplication', jsonEncode(nsfasApplication!.toJson()));
    }
    await _prefs.setString('bursaryApplications',
        jsonEncode(bursaryApplications.map((b) => b.toJson()).toList()));
  }

  Future<void> _persistProfile() async {
    if (!consentStoreProfile) return;
    profile.lastUpdated = DateTime.now();
    await _prefs.setString('profile', jsonEncode(profile.toJson()));
  }

  // ---- Settings mutations ------------------------------------------------
  Future<void> setAppearance(AppearanceMode m) async {
    appearance = m;
    await _prefs.setInt('appearance', m.index);
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage l) async {
    language = l;
    await _prefs.setInt('language', l.index);
    notifyListeners();
  }

  Future<void> setTextScale(double s) async {
    textScale = s;
    await _prefs.setDouble('textScale', s);
    notifyListeners();
  }

  Future<void> setLowBandwidth(bool v) async {
    lowBandwidthMode = v;
    await _prefs.setBool('lowBandwidthMode', v);
    notifyListeners();
  }

  Future<void> completeWelcome() async {
    hasSeenWelcome = true;
    await _prefs.setBool('hasSeenWelcome', true);
    notifyListeners();
  }

  // ---- Consent -----------------------------------------------------------
  Future<void> setConsentStoreProfile(bool v) async {
    consentStoreProfile = v;
    await _prefs.setBool('consentStoreProfile', v);
    if (v) {
      await _persistProfile();
    } else {
      // Withdrawing consent deletes what was kept, immediately. Consent that
      // only stops future collection is not really withdrawable - and that has
      // to include the results and documents, not just the questionnaire.
      await _prefs.remove('profile');
      await _prefs.remove('results');
      await _prefs.remove('idNumber');
      await _prefs.remove('documents');
      await _prefs.remove('applications');
      await _prefs.remove('nsfasApplication');
      await _prefs.remove('bursaryApplications');

      // The in-memory copies have to go too. Clearing only the stored keys
      // left the data live in this session, so toggling the switch back on
      // called _persistProfile() and wrote back exactly what the learner had
      // just withdrawn. The app tells them withdrawal deletes what was kept;
      // this is what makes that true rather than nearly true.
      profile = UserProfile();
      results = null;
      idNumber = null;
      documents = [];
      applications = [];
      nsfasApplication = null;
      bursaryApplications = [];
    }
    notifyListeners();
  }

  Future<void> setConsentReminders(bool v) async {
    consentReminders = v;
    await _prefs.setBool('consentReminders', v);
    if (!v) {
      remindersEnabled = false;
      await _prefs.setBool('remindersEnabled', false);
      await NotificationService.instance.cancelAll();
    }
    notifyListeners();
  }

  Future<void> setConsentPersonalisation(bool v) async {
    consentPersonalisation = v;
    await _prefs.setBool('consentPersonalisation', v);
    notifyListeners();
  }

  Future<bool> setRemindersEnabled(bool v) async {
    if (v) {
      final granted = await NotificationService.instance.requestPermission();
      if (!granted) return false;
      await NotificationService.instance.scheduleJourneyReminders(profile);
    } else {
      await NotificationService.instance.cancelAll();
    }
    remindersEnabled = v;
    await _prefs.setBool('remindersEnabled', v);
    notifyListeners();
    return true;
  }

  // ---- Profile mutations --------------------------------------------------
  Future<void> setIdentity({String? name, String? grade, String? province}) async {
    if (name != null) profile.displayName = name.trim().isEmpty ? null : name.trim();
    if (grade != null) profile.grade = grade;
    if (province != null) profile.province = province;
    await _persistProfile();
    notifyListeners();
  }

  Future<void> setSubjects(String field, List<String> subjects) async {
    profile.interestField = field;
    profile.chosenSubjects = List<String>.from(subjects);
    if (!profile.completedTools.contains('subjects')) {
      profile.completedTools.add('subjects');
    }
    await _persistProfile();
    await _refreshReminders();
    notifyListeners();
  }

  Future<void> applyJobFitResult(Map<String, int> traits,
      Map<Riasec, double> riasec) async {
    profile.traitScores = traits;
    _mergeRiasec(riasec);
    if (!profile.completedTools.contains('job_fit')) {
      profile.completedTools.add('job_fit');
    }
    await _persistProfile();
    await _refreshReminders();
    notifyListeners();
  }

  Future<void> applyCareerChoiceResult(Map<Riasec, double> riasec) async {
    _mergeRiasec(riasec);
    if (!profile.completedTools.contains('career_choice')) {
      profile.completedTools.add('career_choice');
    }
    await _persistProfile();
    await _refreshReminders();
    notifyListeners();
  }

  Future<void> setProfileImage(String path) async {
    profile.profileImagePath = path;
    await _persistProfile();
    notifyListeners();
  }

  Future<void> setInterests(List<String> interests) async {
    profile.interests = List<String>.from(interests);
    await _persistProfile();
    notifyListeners();
  }

  /// Both questionnaires contribute to the same interest profile. Averaging
  /// rather than overwriting means the two instruments reinforce each other
  /// instead of the second one erasing the first.
  void _mergeRiasec(Map<Riasec, double> incoming) {
    if (profile.riasecScores.isEmpty) {
      profile.riasecScores = Map<Riasec, double>.from(incoming);
      return;
    }
    for (final entry in incoming.entries) {
      final existing = profile.riasecScores[entry.key];
      profile.riasecScores[entry.key] =
          existing == null ? entry.value : (existing + entry.value) / 2;
    }
  }

  bool isFavourite(String careerId) =>
      profile.savedFavourites.contains(careerId);

  Future<void> toggleFavourite(String careerId) async {
    if (profile.savedFavourites.remove(careerId)) {
      // removed
    } else {
      profile.savedFavourites.add(careerId);
    }
    await _persistProfile();
    await _refreshReminders();
    notifyListeners();
  }

  Future<void> _refreshReminders() async {
    if (remindersEnabled && consentReminders) {
      await NotificationService.instance.scheduleJourneyReminders(profile);
    }
  }

  Future<void> acceptTerms() async {
    acceptedTerms = true;
    await _prefs.setBool('acceptedTerms', true);
    notifyListeners();
  }

  // ---- Results ------------------------------------------------------------
  Future<void> setResults(MatricResults value) async {
    results = value;
    if (!profile.completedTools.contains('results')) {
      profile.completedTools.add('results');
    }
    if (consentStoreProfile) {
      await _prefs.setString('results', jsonEncode(value.toJson()));
    }
    await _persistProfile();
    await _refreshReminders();
    notifyListeners();
  }

  Future<void> clearResults() async {
    results = null;
    profile.completedTools.remove('results');
    await _prefs.remove('results');
    await _persistProfile();
    notifyListeners();
  }

  // ---- Application pack ----------------------------------------------------
  Future<void> setIdNumber(String? value) async {
    idNumber = (value == null || value.trim().isEmpty) ? null : value.trim();
    if (idNumber == null) {
      await _prefs.remove('idNumber');
    } else {
      await _persistApplications();
    }
    notifyListeners();
  }

  Future<void> addDocument(ApplicationDocument document) async {
    documents.removeWhere((d) => d.kind == document.kind);
    documents.add(document);
    await _persistApplications();
    notifyListeners();
  }

  Future<void> removeDocument(DocumentKind kind) async {
    documents.removeWhere((d) => d.kind == kind);
    await _persistApplications();
    notifyListeners();
  }

  bool hasDocument(DocumentKind kind) =>
      documents.any((d) => d.kind == kind);

  /// Everything an application needs before it can be sent.
  List<DocumentKind> get missingRequiredDocuments => DocumentKind.values
      .where((k) => k.required && !hasDocument(k))
      .toList();

  Future<void> addApplication(InstitutionApplication application) async {
    if (applications.any((a) => a.key == application.key)) return;
    applications.add(application);
    await _persistApplications();
    notifyListeners();
  }

  Future<void> removeApplication(String key) async {
    applications.removeWhere((a) => a.key == key);
    await _persistApplications();
    notifyListeners();
  }

  Future<void> updateApplication(InstitutionApplication application) async {
    final index = applications.indexWhere((a) => a.key == application.key);
    if (index == -1) return;
    applications[index] = application;
    await _persistApplications();
    notifyListeners();
  }

  List<InstitutionApplication> get draftApplications =>
      applications.where((a) => a.state == ApplicationState.draft).toList();

  // ---- NSFAS ---------------------------------------------------------------
  Future<void> setNsfasApplication(NsfasApplication application) async {
    nsfasApplication = application;
    await _persistApplications();
    notifyListeners();
  }

  Future<void> clearNsfasApplication() async {
    nsfasApplication = null;
    await _prefs.remove('nsfasApplication');
    notifyListeners();
  }

  // ---- Bursaries -----------------------------------------------------------
  Future<void> addBursaryApplication(BursaryApplication application) async {
    bursaryApplications.removeWhere((b) => b.bursaryId == application.bursaryId);
    bursaryApplications.add(application);
    await _persistApplications();
    notifyListeners();
  }

  Future<void> updateBursaryApplication(BursaryApplication application) async {
    final index =
        bursaryApplications.indexWhere((b) => b.bursaryId == application.bursaryId);
    if (index == -1) return;
    bursaryApplications[index] = application;
    await _persistApplications();
    notifyListeners();
  }

  Future<void> removeBursaryApplication(String bursaryId) async {
    bursaryApplications.removeWhere((b) => b.bursaryId == bursaryId);
    await _persistApplications();
    notifyListeners();
  }

  BursaryApplication? bursaryApplicationFor(String bursaryId) {
    for (final b in bursaryApplications) {
      if (b.bursaryId == bursaryId) return b;
    }
    return null;
  }

  // ---- Onboarding ---------------------------------------------------------
  Future<void> setOnboardingPreferences({
    required String favouriteSubjectType,
    required List<String> careerGoals,
  }) async {
    profile.favouriteSubjectType = favouriteSubjectType;
    profile.careerGoals = List<String>.from(careerGoals);
    await _persistProfile();
    notifyListeners();
  }

  Future<void> setOnboardingAcademicProfile({
    required String gradeLevel,
    required Map<String, int> subjectMarks,
    required int aps,
  }) async {
    profile.grade = gradeLevel;
    profile.onboardingMarks = Map<String, int>.from(subjectMarks);
    profile.onboardingAps = aps;
    await _persistProfile();
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    hasCompletedOnboarding = true;
    await _prefs.setBool('hasCompletedOnboarding', true);
    notifyListeners();
  }

  // ---- Data rights --------------------------------------------------------
  /// Everything held about the person, as readable JSON. POPIA gives a data
  /// subject the right to know what is held; this is that right, implemented.
  String exportProfileJson() {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert({
      'exportedAt': DateTime.now().toIso8601String(),
      'app': 'Khetha Go',
      'storageLocation': 'This device only, never transmitted',
      'settings': {
        'language': language.name,
        'appearance': appearance.name,
        'textScale': textScale,
        'lowBandwidthMode': lowBandwidthMode,
        'remindersEnabled': remindersEnabled,
      },
      'consent': {
        'storeProfile': consentStoreProfile,
        'reminders': consentReminders,
        'personalisation': consentPersonalisation,
        'acceptedTerms': acceptedTerms,
      },
      'profile': profile.toJson(),
      'idNumber': idNumber,
      'results': results?.toJson(),
      'documents': documents.map((d) => d.toJson()).toList(),
      'applications': applications.map((a) => a.toJson()).toList(),
      'nsfasApplication': nsfasApplication?.toJson(),
      'bursaryApplications':
          bursaryApplications.map((b) => b.toJson()).toList(),
    });
  }

  Future<void> deleteAllData() async {
    profile = UserProfile();
    results = null;
    idNumber = null;
    documents = [];
    applications = [];
    nsfasApplication = null;
    bursaryApplications = [];
    await _prefs.remove('profile');
    await _prefs.remove('results');
    await _prefs.remove('idNumber');
    await _prefs.remove('documents');
    await _prefs.remove('applications');
    await _prefs.remove('nsfasApplication');
    await _prefs.remove('bursaryApplications');
    await NotificationService.instance.cancelAll();
    remindersEnabled = false;
    await _prefs.setBool('remindersEnabled', false);
    notifyListeners();
  }
}

/// Makes [AppState] available to the widget tree and rebuilds dependents when
/// it changes. Deliberately built on Flutter's own primitives rather than a
/// state-management package - one less third-party dependency for a government
/// codebase to carry and keep patched.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({
    super.key,
    required AppState state,
    required super.child,
  }) : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope is missing from the widget tree');
    return scope!.notifier!;
  }

  /// Read without subscribing - for callbacks that mutate state but do not
  /// need to rebuild when it changes.
  static AppState read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope is missing from the widget tree');
    return scope!.notifier!;
  }
}
