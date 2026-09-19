// Models for NSFAS applications and bursary tracking.

enum NsfasStatus {
  notApplied,
  applied,
  documentsSubmitted,
  underReview,
  approved,
  declined,
  appealPending,
}

extension NsfasStatusMeta on NsfasStatus {
  String get label => switch (this) {
        NsfasStatus.notApplied => 'Not applied',
        NsfasStatus.applied => 'Application submitted',
        NsfasStatus.documentsSubmitted => 'Documents received',
        NsfasStatus.underReview => 'Under review',
        NsfasStatus.approved => 'Approved',
        NsfasStatus.declined => 'Not approved',
        NsfasStatus.appealPending => 'Appeal pending',
      };

  bool get isFinal =>
      this == NsfasStatus.approved || this == NsfasStatus.declined;

  bool get isPositive => this == NsfasStatus.approved;
}

class NsfasApplication {
  final NsfasStatus status;
  final String? referenceNumber;
  final DateTime appliedAt;
  final DateTime updatedAt;
  final String? declineReason;

  const NsfasApplication({
    required this.status,
    required this.appliedAt,
    required this.updatedAt,
    this.referenceNumber,
    this.declineReason,
  });

  NsfasApplication copyWith({
    NsfasStatus? status,
    String? referenceNumber,
    DateTime? updatedAt,
    String? declineReason,
  }) =>
      NsfasApplication(
        status: status ?? this.status,
        referenceNumber: referenceNumber ?? this.referenceNumber,
        appliedAt: appliedAt,
        updatedAt: updatedAt ?? this.updatedAt,
        declineReason: declineReason ?? this.declineReason,
      );

  Map<String, dynamic> toJson() => {
        'status': status.name,
        'referenceNumber': referenceNumber,
        'appliedAt': appliedAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'declineReason': declineReason,
      };

  static NsfasApplication? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final statusName = raw['status'];
    final status = NsfasStatus.values.where((s) => s.name == statusName);
    if (status.isEmpty) return null;
    final applied = raw['appliedAt'];
    final updated = raw['updatedAt'];
    return NsfasApplication(
      status: status.first,
      referenceNumber:
          raw['referenceNumber'] is String ? raw['referenceNumber'] as String : null,
      appliedAt: applied is String
          ? (DateTime.tryParse(applied) ?? DateTime.now())
          : DateTime.now(),
      updatedAt: updated is String
          ? (DateTime.tryParse(updated) ?? DateTime.now())
          : DateTime.now(),
      declineReason:
          raw['declineReason'] is String ? raw['declineReason'] as String : null,
    );
  }
}

enum BursaryCategory { merit, needBased, fieldSpecific, corporate, government }

extension BursaryCategoryMeta on BursaryCategory {
  String get label => switch (this) {
        BursaryCategory.merit => 'Merit-based',
        BursaryCategory.needBased => 'Need-based',
        BursaryCategory.fieldSpecific => 'Field-specific',
        BursaryCategory.corporate => 'Corporate',
        BursaryCategory.government => 'Government',
      };
}

enum BursaryApplicationStatus {
  saved,
  applied,
  underReview,
  awarded,
  notAwarded,
}

extension BursaryApplicationStatusMeta on BursaryApplicationStatus {
  String get label => switch (this) {
        BursaryApplicationStatus.saved => 'Saved',
        BursaryApplicationStatus.applied => 'Applied',
        BursaryApplicationStatus.underReview => 'Under review',
        BursaryApplicationStatus.awarded => 'Awarded',
        BursaryApplicationStatus.notAwarded => 'Not awarded',
      };

  bool get isFinal =>
      this == BursaryApplicationStatus.awarded ||
      this == BursaryApplicationStatus.notAwarded;

  bool get isPositive => this == BursaryApplicationStatus.awarded;
}

class Bursary {
  final String id;
  final String name;
  final String provider;
  final String description;
  final BursaryCategory category;
  final List<String> fieldsOfStudy;
  final String? minAps;
  final String? maxHouseholdIncome;
  final String closingDate;
  final String? websiteUrl;
  final List<String> requirements;
  final String coverageDescription;

  const Bursary({
    required this.id,
    required this.name,
    required this.provider,
    required this.description,
    required this.category,
    required this.fieldsOfStudy,
    required this.closingDate,
    required this.coverageDescription,
    this.minAps,
    this.maxHouseholdIncome,
    this.websiteUrl,
    this.requirements = const [],
  });
}

class BursaryApplication {
  final String bursaryId;
  final BursaryApplicationStatus status;
  final DateTime updatedAt;
  final String? referenceNumber;

  const BursaryApplication({
    required this.bursaryId,
    required this.status,
    required this.updatedAt,
    this.referenceNumber,
  });

  BursaryApplication copyWith({
    BursaryApplicationStatus? status,
    DateTime? updatedAt,
    String? referenceNumber,
  }) =>
      BursaryApplication(
        bursaryId: bursaryId,
        status: status ?? this.status,
        updatedAt: updatedAt ?? this.updatedAt,
        referenceNumber: referenceNumber ?? this.referenceNumber,
      );

  Map<String, dynamic> toJson() => {
        'bursaryId': bursaryId,
        'status': status.name,
        'updatedAt': updatedAt.toIso8601String(),
        'referenceNumber': referenceNumber,
      };

  static BursaryApplication? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final bursaryId = raw['bursaryId'];
    if (bursaryId is! String) return null;
    final statusName = raw['status'];
    final status =
        BursaryApplicationStatus.values.where((s) => s.name == statusName);
    final updated = raw['updatedAt'];
    return BursaryApplication(
      bursaryId: bursaryId,
      status: status.isEmpty ? BursaryApplicationStatus.saved : status.first,
      updatedAt: updated is String
          ? (DateTime.tryParse(updated) ?? DateTime.now())
          : DateTime.now(),
      referenceNumber:
          raw['referenceNumber'] is String ? raw['referenceNumber'] as String : null,
    );
  }
}
