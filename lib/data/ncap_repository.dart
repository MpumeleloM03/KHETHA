import '../models/career_models.dart';
import 'seed_careers.dart' as careers_src;
import 'seed_directory.dart' as dir_src;
import 'seed_quizzes.dart' as quiz_src;
import 'seed_support.dart' as support_src;
import 'seed_tutors.dart' as tutor_src;

/// Where the app's content comes from.
///
/// Every screen talks to this interface and never to a data file directly.
/// That is the whole point: the prototype ships with [LocalSeedSource], and
/// pointing the app at DHET's live NCAP feed means writing one new
/// implementation of this class and changing one line in `main()`. No screen,
/// no widget and no model changes.
///
/// The methods are async even though the local implementation answers
/// instantly, so that swapping in a network source does not force a rewrite of
/// every caller into an asynchronous shape later.
abstract class NcapDataSource {
  String get sourceName;
  String get sourceDescription;
  bool get isOffline;

  Future<List<Career>> careers();
  Future<List<Qualification>> qualifications();
  Future<List<LearningProvider>> providers();
  Future<List<QuizQuestion>> jobFitQuestions();
  Future<List<QuizQuestion>> careerChoiceQuestions();
  Future<List<AdviceChannel>> adviceChannels();
  Future<List<CareerEvent>> events();
  Future<Map<String, List<String>>> subjectsByField();
  Future<List<Tutor>> tutors();
}

/// The offline-first implementation used for the prototype.
///
/// Content is compiled into the binary, which is what lets every feature —
/// questionnaires, matching, directories - work with the phone in aeroplane
/// mode. For a learner paying for data by the megabyte, that is not a
/// nice-to-have.
class LocalSeedSource implements NcapDataSource {
  const LocalSeedSource();

  @override
  String get sourceName => 'On-device NCAP content set';

  @override
  String get sourceDescription =>
      'Career, qualification and provider records structured to match the National Career Advice Portal, bundled with the app so every feature works without a connection.';

  @override
  bool get isOffline => true;

  @override
  Future<List<Career>> careers() async => careers_src.careers;

  @override
  Future<List<Qualification>> qualifications() async => dir_src.qualifications;

  @override
  Future<List<LearningProvider>> providers() async => dir_src.providers;

  @override
  Future<List<QuizQuestion>> jobFitQuestions() async => quiz_src.jobFitQuestions;

  @override
  Future<List<QuizQuestion>> careerChoiceQuestions() async =>
      quiz_src.careerChoiceQuestions;

  @override
  Future<List<AdviceChannel>> adviceChannels() async => support_src.adviceChannels;

  @override
  Future<List<CareerEvent>> events() async => support_src.careerEvents;

  @override
  Future<Map<String, List<String>>> subjectsByField() async =>
      dir_src.subjectRecommendations;

  @override
  Future<List<Tutor>> tutors() async => tutor_src.tutors;
}

/// A single place to read content synchronously once it has been loaded.
///
/// Screens read from here rather than awaiting the data source on every
/// rebuild. [Ncap.load] is called once at startup.
class Ncap {
  static late List<Career> careers;
  static late List<Qualification> qualifications;
  static late List<LearningProvider> providers;
  static late List<QuizQuestion> jobFit;
  static late List<QuizQuestion> careerChoice;
  static late List<AdviceChannel> channels;
  static late List<CareerEvent> events;
  static late Map<String, List<String>> subjects;
  static late List<Tutor> tutors;
  static late NcapDataSource source;

  static Future<void> load(NcapDataSource s) async {
    source = s;
    careers = await s.careers();
    qualifications = await s.qualifications();
    providers = await s.providers();
    jobFit = await s.jobFitQuestions();
    careerChoice = await s.careerChoiceQuestions();
    channels = await s.adviceChannels();
    events = await s.events();
    subjects = await s.subjectsByField();
    tutors = await s.tutors();
  }

  /// Tutors covering a subject, nearest province first.
  static List<Tutor> tutorsFor(String subject, {String? province}) {
    final matches = tutors
        .where((t) => t.subjects.any(
            (s) => s.toLowerCase().contains(subject.toLowerCase())))
        .toList();

    matches.sort((a, b) {
      if (province != null) {
        final aLocal = a.province == province || a.province == 'All provinces';
        final bLocal = b.province == province || b.province == 'All provinces';
        if (aLocal != bLocal) return aLocal ? -1 : 1;
      }
      return b.rating.compareTo(a.rating);
    });
    return matches;
  }

  static Career? careerById(String id) {
    for (final c in careers) {
      if (c.id == id) return c;
    }
    return null;
  }

  static Qualification? qualificationById(String id) {
    for (final q in qualifications) {
      if (q.id == id) return q;
    }
    return null;
  }

  /// Qualifications that lead to a given occupation - the link that turns
  /// "this career suits you" into "here is what to study for it".
  static List<Qualification> qualificationsFor(String careerId) =>
      qualifications.where((q) => q.leadsToCareerIds.contains(careerId)).toList();

  /// Institutions that offer the field a career sits in, optionally narrowed
  /// to the learner's province so the answer is actually reachable for them.
  ///
  /// A null [province] means "no filter", not "no province" - callers that have
  /// not asked the learner where they live must not pass null and then present
  /// the result as local.
  static List<LearningProvider> providersFor(String sector, {String? province}) =>
      providers
          .where((p) =>
              p.offeredFields.contains(sector) &&
              (province == null || p.province == province))
          .toList();

  static List<String> get allSectors {
    final set = <String>{};
    for (final c in careers) {
      set.add(c.sector);
    }
    final list = set.toList()..sort();
    return list;
  }
}
