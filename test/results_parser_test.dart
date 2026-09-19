import 'package:flutter_test/flutter_test.dart';
import 'package:khetha_ncap/data/results_parser.dart';
import 'package:khetha_ncap/models/results_models.dart';

/// Tests for reading a results statement.
///
/// The realistic input is a phone photograph of a creased page, so these cases
/// are written around what actually comes back: mangled characters, an extra
/// achievement-level column, and page furniture mixed in with the rows.
void main() {
  ScanOutcome parse(List<String> lines, {double confidence = 0.9}) =>
      ResultsParser.parse(lines, engine: 'test', confidence: confidence);

  int? markFor(ScanOutcome outcome, String subject) {
    for (final s in outcome.subjects) {
      if (s.subject == subject) return s.percentage;
    }
    return null;
  }

  group('clean statements', () {
    test('reads a standard subject-percentage-level table', () {
      final outcome = parse([
        'NATIONAL SENIOR CERTIFICATE',
        'STATEMENT OF RESULTS',
        'ENGLISH HOME LANGUAGE            72   6',
        'MATHEMATICS                      64   5',
        'PHYSICAL SCIENCES                58   4',
        'LIFE SCIENCES                    71   6',
        'GEOGRAPHY                        66   5',
        'LIFE ORIENTATION                 80   7',
      ]);

      expect(outcome.subjects.length, 6);
      expect(markFor(outcome, 'English Home Language'), 72);
      expect(markFor(outcome, 'Mathematics'), 64);
      expect(markFor(outcome, 'Physical Sciences'), 58);
      expect(markFor(outcome, 'Life Orientation'), 80);
    });

    test('does not mistake the achievement level for the percentage', () {
      final outcome = parse(['MATHEMATICS 64 5']);
      expect(markFor(outcome, 'Mathematics'), 64);
    });

    test('handles a percent sign and no level column', () {
      final outcome = parse(['Accounting 81%', 'Business Studies 77%']);
      expect(markFor(outcome, 'Accounting'), 81);
      expect(markFor(outcome, 'Business Studies'), 77);
    });
  });

  group('damaged scans', () {
    test('recovers subjects with characters misread', () {
      final outcome = parse([
        'MATHEMAT1CS                      64   5',
        'PHYS1CAL SC1ENCES                58   4',
      ]);
      expect(markFor(outcome, 'Mathematics'), 64);
      expect(markFor(outcome, 'Physical Sciences'), 58);
    });

    test('reads a mark that landed on its own line', () {
      final outcome = parse([
        'GEOGRAPHY',
        '66',
        'HISTORY',
        '58',
      ]);
      expect(markFor(outcome, 'Geography'), 66);
      expect(markFor(outcome, 'History'), 58);
    });

    test('does not read a subject code on the next line as a mark', () {
      final outcome = parse([
        'GEOGRAPHY',
        'CODE GEOG HL 2024',
      ]);
      expect(outcome.subjects, isEmpty);
    });

    test('converts a level-only row into the middle of its band', () {
      final outcome = parse(['TOURISM 6']);
      final mark = markFor(outcome, 'Tourism');
      expect(mark, isNotNull);
      expect(mark! >= 70 && mark <= 79, isTrue,
          reason: 'level 6 should land inside the 70-79 band, got $mark');
    });
  });

  group('separating rows from page furniture', () {
    test('ignores headers and issuing-body text', () {
      final outcome = parse([
        'DEPARTMENT OF BASIC EDUCATION',
        'REPUBLIC OF SOUTH AFRICA',
        'UMALUSI',
        'CANDIDATE NUMBER 1234567890',
        'SUBJECT           PERCENTAGE   LEVEL',
        'MATHEMATICS 64 5',
      ]);
      expect(outcome.subjects.length, 1);
      expect(outcome.unparsedLines, isEmpty);
    });

    test('reports rows it genuinely could not read', () {
      final outcome = parse([
        'MATHEMATICS 64 5',
        'ADVANCED PROGRAMME SOMETHING 55',
      ]);
      expect(outcome.subjects.length, 1);
      expect(outcome.unparsedLines, isNotEmpty);
    });
  });

  group('distinguishing similar subjects', () {
    test('Mathematical Literacy is not read as Mathematics', () {
      final outcome = parse(['MATHEMATICAL LITERACY 72 6']);
      expect(markFor(outcome, 'Mathematical Literacy'), 72);
      expect(markFor(outcome, 'Mathematics'), isNull);
    });

    test('a home language beats a bare language match', () {
      final outcome = parse(['ENGLISH HOME LANGUAGE 68 5']);
      expect(markFor(outcome, 'English Home Language'), 68);
      expect(markFor(outcome, 'English First Additional Language'), isNull);
    });

    test('a repeated subject keeps the later, corrected row', () {
      final outcome = parse([
        'MATHEMATICS 32 2',
        'MATHEMATICS 54 4',
      ]);
      expect(outcome.subjects.length, 1);
      expect(markFor(outcome, 'Mathematics'), 54);
    });
  });

  group('low confidence', () {
    test('rows from a poor scan are flagged for checking', () {
      final outcome = parse(['MATHEMATICS 64 5'], confidence: 0.4);
      expect(outcome.subjects.single.needsChecking, isTrue);
    });

    test('a scan with too few rows is not treated as usable', () {
      expect(parse(['MATHEMATICS 64 5']).isUsable, isFalse);
    });
  });
}
