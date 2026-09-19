// Models for the application pack a learner builds and submits.

enum DocumentKind { identity, results, proofOfResidence, incomeProof, photo }

extension DocumentKindMeta on DocumentKind {
  String get label => switch (this) {
        DocumentKind.identity => 'ID document or birth certificate',
        DocumentKind.results => 'Latest results statement',
        DocumentKind.proofOfResidence => 'Proof of residence',
        DocumentKind.incomeProof => 'Household income proof',
        DocumentKind.photo => 'Passport photograph',
      };

  String get why => switch (this) {
        DocumentKind.identity =>
          'Every institution requires it, and it must match the name on your results.',
        DocumentKind.results =>
          'Your latest available results. A Grade 11 or term report is accepted while you wait for finals.',
        DocumentKind.proofOfResidence =>
          'A municipal bill or an affidavit from your ward councillor if bills are not in your name.',
        DocumentKind.incomeProof =>
          'Needed for NSFAS funding, not for admission. Payslips, a SASSA letter, or an affidavit.',
        DocumentKind.photo =>
          'Required by some institutions for the student card.',
      };

  /// Whether an application can be submitted without it.
  bool get required => switch (this) {
        DocumentKind.identity => true,
        DocumentKind.results => true,
        DocumentKind.proofOfResidence => true,
        DocumentKind.incomeProof => false,
        DocumentKind.photo => false,
      };
}

/// A captured document and what checking it turned up.
class ApplicationDocument {
  final DocumentKind kind;
  final String fileName;
  final DateTime capturedAt;

  /// Problems found when the file was checked - an unreadable scan, a name
  /// that does not match, an expired document.
  final List<String> issues;

  /// True when the checks the app can run all passed. This is a completeness
  /// and legibility check, not verification against Home Affairs or Umalusi.
  final bool passedChecks;

  const ApplicationDocument({
    required this.kind,
    required this.fileName,
    required this.capturedAt,
    this.issues = const [],
    this.passedChecks = true,
  });

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'fileName': fileName,
        'capturedAt': capturedAt.toIso8601String(),
        'issues': issues,
        'passedChecks': passedChecks,
      };

  static ApplicationDocument? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final kindName = raw['kind'];
    final kind = DocumentKind.values.where((k) => k.name == kindName);
    if (kind.isEmpty) return null;
    final captured = raw['capturedAt'];
    return ApplicationDocument(
      kind: kind.first,
      fileName: raw['fileName'] is String ? raw['fileName'] as String : 'Document',
      capturedAt: captured is String
          ? (DateTime.tryParse(captured) ?? DateTime.now())
          : DateTime.now(),
      issues: (raw['issues'] as List?)?.whereType<String>().toList() ?? const [],
      passedChecks: raw['passedChecks'] != false,
    );
  }
}

enum ApplicationState {
  draft,
  submitted,
  underReview,
  offered,
  waitlisted,
  declined,
}

extension ApplicationStateMeta on ApplicationState {
  String get label => switch (this) {
        ApplicationState.draft => 'Not sent',
        ApplicationState.submitted => 'Submitted',
        ApplicationState.underReview => 'Under review',
        ApplicationState.offered => 'Offer received',
        ApplicationState.waitlisted => 'Waiting list',
        ApplicationState.declined => 'Not successful',
      };

  bool get isFinal =>
      this == ApplicationState.offered ||
      this == ApplicationState.waitlisted ||
      this == ApplicationState.declined;
}

/// One application, to one programme, at one institution.
class InstitutionApplication {
  final String providerId;
  final String qualificationId;
  final ApplicationState state;
  final String? reference;
  final DateTime updatedAt;
  final String? note;

  const InstitutionApplication({
    required this.providerId,
    required this.qualificationId,
    required this.state,
    required this.updatedAt,
    this.reference,
    this.note,
  });

  String get key => '$providerId::$qualificationId';

  InstitutionApplication copyWith({
    ApplicationState? state,
    String? reference,
    String? note,
    DateTime? updatedAt,
  }) =>
      InstitutionApplication(
        providerId: providerId,
        qualificationId: qualificationId,
        state: state ?? this.state,
        reference: reference ?? this.reference,
        note: note ?? this.note,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'providerId': providerId,
        'qualificationId': qualificationId,
        'state': state.name,
        'reference': reference,
        'note': note,
        'updatedAt': updatedAt.toIso8601String(),
      };

  static InstitutionApplication? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final providerId = raw['providerId'];
    final qualificationId = raw['qualificationId'];
    if (providerId is! String || qualificationId is! String) return null;

    final stateName = raw['state'];
    final state = ApplicationState.values.where((s) => s.name == stateName);
    final updated = raw['updatedAt'];

    return InstitutionApplication(
      providerId: providerId,
      qualificationId: qualificationId,
      state: state.isEmpty ? ApplicationState.draft : state.first,
      reference: raw['reference'] is String ? raw['reference'] as String : null,
      note: raw['note'] is String ? raw['note'] as String : null,
      updatedAt: updated is String
          ? (DateTime.tryParse(updated) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}
