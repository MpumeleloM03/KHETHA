// Core data models for Khetha Go.
//
// The shapes here deliberately mirror the public structures NCAP already
// publishes (occupations, qualifications, learning providers) and the national
// frameworks that sit behind them - OFO codes, NQF levels and SAQA IDs - so a
// record from a DHET feed can be mapped onto these classes without a redesign.

/// The six Holland (RIASEC) interest dimensions. Using an established,
/// published instrument rather than an invented scale means results are
/// interpretable by career practitioners and comparable across tools.
enum Riasec { realistic, investigative, artistic, social, enterprising, conventional }

extension RiasecMeta on Riasec {
  String get code => switch (this) {
        Riasec.realistic => 'R',
        Riasec.investigative => 'I',
        Riasec.artistic => 'A',
        Riasec.social => 'S',
        Riasec.enterprising => 'E',
        Riasec.conventional => 'C',
      };

  String get label => switch (this) {
        Riasec.realistic => 'Realistic',
        Riasec.investigative => 'Investigative',
        Riasec.artistic => 'Artistic',
        Riasec.social => 'Social',
        Riasec.enterprising => 'Enterprising',
        Riasec.conventional => 'Conventional',
      };

  /// Plain-language gloss, written for a Grade 9 reading level.
  String get plain => switch (this) {
        Riasec.realistic => 'Doers: practical, hands-on, like working with tools, machines or outdoors',
        Riasec.investigative => 'Thinkers: curious, like research, analysis and figuring things out',
        Riasec.artistic => 'Creators: imaginative, like design, writing, music and self-expression',
        Riasec.social => 'Helpers: enjoy teaching, caring for and working with people',
        Riasec.enterprising => 'Persuaders: like leading, selling, starting things and taking charge',
        Riasec.conventional => 'Organisers: like structure, accuracy, data and clear procedures',
      };
}

/// How strongly the labour market currently needs this occupation.
/// Mirrors the signal DHET publishes on its national scarce-skills lists.
enum Demand { high, moderate, stable }

extension DemandMeta on Demand {
  String get label => switch (this) {
        Demand.high => 'High demand',
        Demand.moderate => 'Growing',
        Demand.stable => 'Stable',
      };
}

class Career {
  final String id;
  final String title;

  /// Organising Framework for Occupations code - the national standard DHET
  /// and the QCTO use to identify an occupation. Kept on the record so the
  /// app can reconcile against government datasets rather than free text.
  final String ofoCode;
  final String description;

  /// A day in the life, in the learner's language.
  final String dayInTheLife;
  final String sector;
  final List<String> requiredSubjects;
  final List<String> helpfulSubjects;
  final List<String> traits;
  final Map<Riasec, double> riasec;
  final String studyPathway;
  final String minQualification;
  final String nqfLevel;
  final String entrySalaryBand;
  final String experiencedSalaryBand;
  final Demand demand;

  /// Whether the occupation appears on the national list of occupations in
  /// high demand - a strong signal for a learner weighing options.
  final bool scarceSkill;
  final List<String> relatedCareerIds;

  const Career({
    required this.id,
    required this.title,
    required this.ofoCode,
    required this.description,
    required this.dayInTheLife,
    required this.sector,
    required this.requiredSubjects,
    this.helpfulSubjects = const [],
    required this.traits,
    required this.riasec,
    required this.studyPathway,
    required this.minQualification,
    required this.nqfLevel,
    required this.entrySalaryBand,
    required this.experiencedSalaryBand,
    this.demand = Demand.stable,
    this.scarceSkill = false,
    this.relatedCareerIds = const [],
  });
}

/// A subject condition on a qualification's entry requirements.
///
/// Expressed as "one of these subjects, at this mark" so that a real rule like
/// "Mathematics 60%, or Technical Mathematics 70%" survives intact instead of
/// being flattened into prose the app cannot check against.
class SubjectRequirement {
  final List<String> anyOf;
  final int minPercent;

  /// False for a subject that strengthens an application without gating it.
  final bool mandatory;

  const SubjectRequirement(this.anyOf, this.minPercent, {this.mandatory = true});

  String get label => anyOf.join(' or ');
  String get description => '$label at $minPercent%';
}

/// The NSC pass a qualification needs before any APS or subject rule applies.
/// This is the first gate a learner hits and the one most often missed.
enum PassRequirement { higherCertificate, diploma, bachelor }

extension PassRequirementMeta on PassRequirement {
  String get label => switch (this) {
        PassRequirement.higherCertificate => 'Higher Certificate pass',
        PassRequirement.diploma => 'Diploma pass',
        PassRequirement.bachelor => 'Bachelor\u2019s pass',
      };

  int get rank => switch (this) {
        PassRequirement.higherCertificate => 1,
        PassRequirement.diploma => 2,
        PassRequirement.bachelor => 3,
      };
}

class Qualification {
  final String id;
  final String title;

  /// SAQA registration ID. Real qualifications carry one; showing it lets a
  /// learner verify the programme on the national register before enrolling.
  final String saqaId;
  final String field;
  final String nqfLevel;
  final String duration;
  final String providerType;
  final String minimumRequirements;
  final List<String> leadsToCareerIds;

  /// Admission Point Score the programme asks for. Zero means the programme
  /// admits on pass type and subjects alone, which is common at TVET colleges.
  final int apsRequired;
  final PassRequirement passRequired;
  final List<SubjectRequirement> requirements;

  /// Qualifications this one articulates into. This is what makes a bridging
  /// route computable rather than hand-written: a Higher Certificate that
  /// articulates to a Diploma that articulates to a Degree is a path the app
  /// can find on its own.
  final List<String> articulatesTo;

  /// An extended curriculum programme: the same degree delivered over an extra
  /// year, with a lower APS, funded by DHET. Often the single most useful
  /// answer for a learner who missed the cut, and the one least likely to be
  /// known to them.
  final bool isExtendedProgramme;

  /// Institutions offering it, by provider id. Empty means every institution
  /// that offers the field.
  final List<String> offeredBy;

  const Qualification({
    required this.id,
    required this.title,
    required this.saqaId,
    required this.field,
    required this.nqfLevel,
    required this.duration,
    required this.providerType,
    required this.minimumRequirements,
    this.leadsToCareerIds = const [],
    this.apsRequired = 0,
    this.passRequired = PassRequirement.diploma,
    this.requirements = const [],
    this.articulatesTo = const [],
    this.isExtendedProgramme = false,
    this.offeredBy = const [],
  });
}

/// A tutor listing, shown to a learner whose marks are standing between them
/// and the career they have set their mind on.
class Tutor {
  final String id;
  final String name;
  final List<String> subjects;
  final String province;
  final String town;
  final String mode;
  final String rate;
  final String credential;
  final int learnersHelped;
  final double rating;

  const Tutor({
    required this.id,
    required this.name,
    required this.subjects,
    required this.province,
    required this.town,
    required this.mode,
    required this.rate,
    required this.credential,
    required this.learnersHelped,
    required this.rating,
  });
}

class LearningProvider {
  final String id;
  final String name;
  final String province;
  final String town;
  final String type;
  final List<String> offeredFields;
  final bool nsfasAccredited;
  final String website;
  final String? abbreviation;
  final String? description;
  final String? email;
  final String? phone;
  final int? totalStudents;
  final String? imageUrl;
  final String? logoUrl;
  final String? heroImageUrl;

  const LearningProvider({
    required this.id,
    required this.name,
    required this.province,
    required this.town,
    required this.type,
    required this.offeredFields,
    this.nsfasAccredited = true,
    this.website = '',
    this.abbreviation,
    this.description,
    this.email,
    this.phone,
    this.totalStudents,
    this.imageUrl,
    this.logoUrl,
    this.heroImageUrl,
  });
}

class QuizQuestion {
  final String id;
  final String question;
  final String? helper;
  final List<QuizOption> options;

  /// For a Likert item, the single RIASEC dimension it loads on.
  ///
  /// Null on the older categorical questions, whose options each carry their
  /// own spread of dimensions instead.
  final Riasec? dimension;

  /// Which block of the long instrument this item belongs to, for progress and
  /// save-and-resume. Null for single-section questionnaires.
  final int? section;

  const QuizQuestion({
    required this.id,
    required this.question,
    this.helper,
    required this.options,
    this.dimension,
    this.section,
  });
}

class QuizOption {
  final String label;
  final List<String> traits;
  final Map<Riasec, double> riasec;

  /// Response intensity, 0..1.
  ///
  /// Likert items set this per anchor ("would hate it" = 0, "would love it" =
  /// 1). The older categorical questions leave it at 1.0, so they score exactly
  /// as they did before this field existed.
  final double weight;

  const QuizOption({
    required this.label,
    this.traits = const [],
    this.riasec = const {},
    this.weight = 1.0,
  });
}

/// A contactable human or channel. The brief requires in-app access to a real
/// career practitioner - this is the record behind that.
class AdviceChannel {
  final String id;
  final String name;
  final String description;

  /// One of: phone, whatsapp, sms, email, web, ussd.
  final String kind;
  final String value;
  final String availability;

  /// True when the channel costs the caller nothing - the deciding factor for
  /// a learner on a limited airtime budget.
  final bool freeToUse;

  const AdviceChannel({
    required this.id,
    required this.name,
    required this.description,
    required this.kind,
    required this.value,
    required this.availability,
    this.freeToUse = false,
  });
}

class CareerEvent {
  final String id;
  final String title;
  final String host;
  final String location;
  final String province;
  final String date;
  final String description;

  const CareerEvent({
    required this.id,
    required this.title,
    required this.host,
    required this.location,
    required this.province,
    required this.date,
    required this.description,
  });
}

/// Everything the app knows about the person using it.
///
/// This object is the whole of the user's personal data. It never leaves the
/// device: it is serialised to the app's private storage and nowhere else,
/// which is what makes the privacy claim in Settings verifiable rather than
/// aspirational.
class UserProfile {
  String? displayName;
  String? grade;
  String? province;
  String? interestField;
  List<String> chosenSubjects;
  Map<String, int> traitScores;
  Map<Riasec, double> riasecScores;
  List<String> savedFavourites;
  List<String> completedTools;
  DateTime? lastUpdated;

  String? favouriteSubjectType;
  List<String> careerGoals;
  Map<String, int> onboardingMarks;
  int? onboardingAps;

  String? profileImagePath;
  List<String> interests;

  UserProfile({
    this.displayName,
    this.grade,
    this.province,
    this.interestField,
    List<String>? chosenSubjects,
    Map<String, int>? traitScores,
    Map<Riasec, double>? riasecScores,
    List<String>? savedFavourites,
    List<String>? completedTools,
    this.lastUpdated,
    this.favouriteSubjectType,
    List<String>? careerGoals,
    Map<String, int>? onboardingMarks,
    this.onboardingAps,
    this.profileImagePath,
    List<String>? interests,
  })  : chosenSubjects = chosenSubjects ?? [],
        traitScores = traitScores ?? {},
        riasecScores = riasecScores ?? {},
        savedFavourites = savedFavourites ?? [],
        completedTools = completedTools ?? [],
        careerGoals = careerGoals ?? [],
        onboardingMarks = onboardingMarks ?? {},
        interests = interests ?? [];

  bool get hasJobFit => completedTools.contains('job_fit');
  bool get hasCareerChoice => completedTools.contains('career_choice');
  bool get hasSubjects => chosenSubjects.isNotEmpty;

  /// How far through the guided journey the learner is, 0..1.
  double get journeyProgress {
    var done = 0;
    if (hasSubjects) done++;
    if (hasJobFit) done++;
    if (hasCareerChoice) done++;
    if (savedFavourites.isNotEmpty) done++;
    return done / 4;
  }

  /// The learner's three strongest interest dimensions, highest first —
  /// the standard way a Holland code is reported.
  String get hollandCode {
    if (riasecScores.isEmpty) return '-';
    final sorted = riasecScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(3).map((e) => e.key.code).join();
  }

  Map<String, dynamic> toJson() => {
        'displayName': displayName,
        'grade': grade,
        'province': province,
        'interestField': interestField,
        'chosenSubjects': chosenSubjects,
        'traitScores': traitScores,
        'riasecScores':
            riasecScores.map((k, v) => MapEntry(k.name, v)),
        'savedFavourites': savedFavourites,
        'completedTools': completedTools,
        'lastUpdated': lastUpdated?.toIso8601String(),
        'favouriteSubjectType': favouriteSubjectType,
        'careerGoals': careerGoals,
        'onboardingMarks': onboardingMarks,
        'onboardingAps': onboardingAps,
        'profileImagePath': profileImagePath,
        'interests': interests,
      };

  /// Rebuilds a profile from stored JSON.
  ///
  /// Every field is read defensively. Stored data can be from an older build of
  /// the app, or simply corrupt, and a learner losing their journey is far
  /// better than the app refusing to open.
  static UserProfile fromJson(Map<String, dynamic> j) {
    final riasec = <Riasec, double>{};
    final rawRiasec = j['riasecScores'];
    if (rawRiasec is Map) {
      for (final entry in rawRiasec.entries) {
        final match = Riasec.values.where((r) => r.name == entry.key);
        final value = entry.value;
        if (match.isNotEmpty && value is num) {
          riasec[match.first] = value.toDouble();
        }
      }
    }

    final traits = <String, int>{};
    final rawTraits = j['traitScores'];
    if (rawTraits is Map) {
      for (final entry in rawTraits.entries) {
        final key = entry.key;
        final value = entry.value;
        if (key is String && value is num) traits[key] = value.toInt();
      }
    }

    List<String> stringList(Object? raw) =>
        raw is List ? raw.whereType<String>().toList() : <String>[];

    final rawDate = j['lastUpdated'];

    final onboardingMarks = <String, int>{};
    final rawOnboardingMarks = j['onboardingMarks'];
    if (rawOnboardingMarks is Map) {
      for (final entry in rawOnboardingMarks.entries) {
        if (entry.key is String && entry.value is num) {
          onboardingMarks[entry.key as String] = (entry.value as num).toInt();
        }
      }
    }

    return UserProfile(
      displayName: j['displayName'] is String ? j['displayName'] as String : null,
      grade: j['grade'] is String ? j['grade'] as String : null,
      province: j['province'] is String ? j['province'] as String : null,
      interestField:
          j['interestField'] is String ? j['interestField'] as String : null,
      chosenSubjects: stringList(j['chosenSubjects']),
      traitScores: traits,
      riasecScores: riasec,
      savedFavourites: stringList(j['savedFavourites']),
      completedTools: stringList(j['completedTools']),
      lastUpdated: rawDate is String ? DateTime.tryParse(rawDate) : null,
      favouriteSubjectType: j['favouriteSubjectType'] is String
          ? j['favouriteSubjectType'] as String
          : null,
      careerGoals: stringList(j['careerGoals']),
      onboardingMarks: onboardingMarks,
      onboardingAps: j['onboardingAps'] is int ? j['onboardingAps'] as int : null,
      profileImagePath: j['profileImagePath'] is String ? j['profileImagePath'] as String : null,
      interests: stringList(j['interests']),
    );
  }
}
