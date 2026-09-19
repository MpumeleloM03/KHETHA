import 'package:flutter_test/flutter_test.dart';
import 'package:khetha_ncap/services/id_validator.dart';

/// Tests for South African ID number validation.
///
/// The check digit is the point of this: a learner who transposes two digits
/// on an application finds out months later, and the number itself carries
/// enough structure to catch it at capture time.
void main() {
  /// Builds a structurally valid ID number with a correct Luhn check digit, so
  /// the tests do not hardcode a real person's number.
  String buildId(String first12) {
    var sum = 0;
    var shouldDouble = true; // position 13 is the check digit
    for (var i = first12.length - 1; i >= 0; i--) {
      var value = int.parse(first12[i]);
      if (shouldDouble) {
        value *= 2;
        if (value > 9) value -= 9;
      }
      sum += value;
      shouldDouble = !shouldDouble;
    }
    final check = (10 - (sum % 10)) % 10;
    return '$first12$check';
  }

  group('well-formed numbers', () {
    test('accepts a valid number and reads the date of birth', () {
      final id = SaIdNumber.parse(buildId('070315' '5' '234' '08'));
      expect(id.isValid, isTrue, reason: id.problems.join(' '));
      expect(id.dateOfBirth?.month, 3);
      expect(id.dateOfBirth?.day, 15);
    });

    test('reads gender from the sequence block', () {
      expect(SaIdNumber.parse(buildId('070315523408')).gender, 'Male');
      expect(SaIdNumber.parse(buildId('070315123408')).gender, 'Female');
    });

    test('reads citizenship from digit eleven', () {
      expect(SaIdNumber.parse(buildId('070315523408')).isCitizen, isTrue);
      expect(SaIdNumber.parse(buildId('070315523418')).isCitizen, isFalse);
    });

    test('ignores spaces and dashes', () {
      final raw = buildId('070315523408');
      final spaced = '${raw.substring(0, 6)} ${raw.substring(6, 10)} ${raw.substring(10)}';
      expect(SaIdNumber.parse(spaced).isValid, isTrue);
    });
  });

  group('rejections', () {
    test('rejects the wrong length and says so plainly', () {
      final id = SaIdNumber.parse('123456789');
      expect(id.isValid, isFalse);
      expect(id.problems.single, contains('13 digits'));
    });

    test('catches a transposed digit through the check digit', () {
      final valid = buildId('070315523408');
      final swapped = valid.replaceRange(
        2,
        4,
        '${valid[3]}${valid[2]}',
      );
      if (swapped == valid) return; // digits were identical; nothing to catch
      final id = SaIdNumber.parse(swapped);
      expect(id.isValid, isFalse);
    });

    test('rejects an impossible month', () {
      final id = SaIdNumber.parse(buildId('071515523408'));
      expect(id.isValid, isFalse);
      expect(id.problems.any((p) => p.contains('month')), isTrue);
    });

    test('rejects a date that does not exist', () {
      final id = SaIdNumber.parse(buildId('070231523408'));
      expect(id.isValid, isFalse);
      expect(id.problems.any((p) => p.contains('does not exist')), isTrue);
    });

    test('rejects an out-of-range citizenship digit', () {
      final id = SaIdNumber.parse(buildId('070315523478'));
      expect(id.isValid, isFalse);
      expect(id.problems.any((p) => p.contains('Digit 11')), isTrue);
    });
  });
}
