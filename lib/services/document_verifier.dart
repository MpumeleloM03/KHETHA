import 'dart:io';

import '../data/results_parser.dart';
import '../models/application_models.dart';
import 'id_validator.dart';
import 'text_scanner.dart';

/// Checks a captured document before it goes into an application.
///
/// What this can do: confirm the file is readable, that it contains text at all
/// rather than being a photo of a table, and that the details on it match what
/// the learner told the app. What it cannot do: confirm the document is genuine.
/// Only Home Affairs, Umalusi and the institutions can do that, and the app
/// says so rather than implying a verification it has not performed.
class DocumentVerifier {
  DocumentVerifier._();
  static final instance = DocumentVerifier._();

  Future<ApplicationDocument> check({
    required DocumentKind kind,
    required String path,
    String? expectedIdNumber,
    String? expectedName,
  }) async {
    final file = File(path);
    final fileName = path.split('/').last;
    final issues = <String>[];

    if (!file.existsSync()) {
      return ApplicationDocument(
        kind: kind,
        fileName: fileName,
        capturedAt: DateTime.now(),
        issues: const ['That file could not be opened.'],
        passedChecks: false,
      );
    }

    final bytes = await file.length();
    // A legible photograph of an A4 page is not 30 KB. Below that it is almost
    // always a screenshot thumbnail or a heavily compressed image that an
    // admissions officer will reject.
    if (bytes < 30 * 1024) {
      issues.add(
        'This file is very small, which usually means the image is too low quality to read. Photograph the page again in good light.',
      );
    }
    if (bytes > 12 * 1024 * 1024) {
      issues.add(
        'This file is over 12 MB. Most institutions reject uploads that large.',
      );
    }

    // Read the document and check it says what it should.
    if (TextScanner.instance.isSupported) {
      try {
        final recognised = await TextScanner.instance.recognise(path);
        final text = recognised.lines.join(' ');

        if (recognised.lines.isEmpty) {
          issues.add(
            'No text could be read from this. Make sure the whole page is in frame and in focus.',
          );
        } else {
          issues.addAll(_checkContent(
            kind: kind,
            lines: recognised.lines,
            text: text,
            expectedIdNumber: expectedIdNumber,
            expectedName: expectedName,
          ));
        }
      } on TextScanException {
        // Reading is a bonus check, not a gate. A document that cannot be read
        // here may still be perfectly acceptable to an institution.
      }
    }

    return ApplicationDocument(
      kind: kind,
      fileName: fileName,
      capturedAt: DateTime.now(),
      issues: issues,
      passedChecks: issues.isEmpty,
    );
  }

  List<String> _checkContent({
    required DocumentKind kind,
    required List<String> lines,
    required String text,
    String? expectedIdNumber,
    String? expectedName,
  }) {
    final issues = <String>[];
    final digitsOnly = text.replaceAll(RegExp(r'\D'), '');

    switch (kind) {
      case DocumentKind.identity:
        final found = RegExp(r'\d{13}').allMatches(digitsOnly).map((m) => m.group(0)!);
        if (found.isEmpty) {
          issues.add(
            'No 13-digit ID number could be read on this document. Check that the number is in frame and in focus.',
          );
        } else if (expectedIdNumber != null) {
          final expected = expectedIdNumber.replaceAll(RegExp(r'\D'), '');
          if (!found.contains(expected)) {
            issues.add(
              'The ID number on this document does not match the one you entered. One of the two is wrong, and an institution will reject the application over it.',
            );
          }
        } else {
          // Nothing to compare against, but the number can still be checked on
          // its own terms.
          final parsed = SaIdNumber.parse(found.first);
          if (!parsed.isValid) {
            issues.add(
              'The ID number read from this document does not check out: ${parsed.problems.first}',
            );
          }
        }

      case DocumentKind.results:
        final outcome = ResultsParser.parse(lines, engine: 'verifier', confidence: 1);
        if (outcome.subjects.length < 4) {
          issues.add(
            'This does not look like a results statement - only ${outcome.subjects.length} subjects could be read from it.',
          );
        }

      case DocumentKind.proofOfResidence:
        const markers = ['municipal', 'account', 'affidavit', 'statement', 'address', 'erf'];
        final lower = text.toLowerCase();
        if (!markers.any(lower.contains)) {
          issues.add(
            'This does not look like a proof of residence. A municipal bill, a bank statement or a signed affidavit is what institutions accept.',
          );
        }

      case DocumentKind.incomeProof:
        const markers = ['payslip', 'salary', 'sassa', 'income', 'affidavit', 'grant', 'unemploy'];
        final lower = text.toLowerCase();
        if (!markers.any(lower.contains)) {
          issues.add(
            'This does not look like income proof. NSFAS accepts payslips, a SASSA letter, or an affidavit if nobody in the household is employed.',
          );
        }

      case DocumentKind.photo:
        break;
    }

    if (expectedName != null && expectedName.trim().length > 2) {
      final first = expectedName.trim().split(' ').first.toLowerCase();
      if (first.length > 2 && !text.toLowerCase().contains(first)) {
        issues.add(
          'The name "$expectedName" does not appear on this document. Institutions check that every document is in the same name.',
        );
      }
    }

    return issues;
  }
}
