/// Validation for a South African identity number.
///
/// Worth doing properly rather than checking the length: a transposed digit in
/// an application is the kind of error that surfaces months later as a rejected
/// application, and the number carries enough structure to catch most of them
/// before anything is submitted.
class SaIdNumber {
  final String digits;
  final bool isValid;
  final List<String> problems;
  final DateTime? dateOfBirth;
  final String? gender;
  final bool? isCitizen;

  const SaIdNumber._({
    required this.digits,
    required this.isValid,
    required this.problems,
    this.dateOfBirth,
    this.gender,
    this.isCitizen,
  });

  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    var years = now.year - dateOfBirth!.year;
    final hadBirthday = now.month > dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day >= dateOfBirth!.day);
    if (!hadBirthday) years--;
    return years;
  }

  static SaIdNumber parse(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    final problems = <String>[];

    if (digits.length != 13) {
      return SaIdNumber._(
        digits: digits,
        isValid: false,
        problems: [
          digits.length < 13
              ? 'An ID number has 13 digits; this has ${digits.length}.'
              : 'An ID number has 13 digits; this has ${digits.length}.',
        ],
      );
    }

    // YYMMDD. The century is inferred: an ID implying someone not yet born is
    // read as the previous century.
    final yy = int.parse(digits.substring(0, 2));
    final mm = int.parse(digits.substring(2, 4));
    final dd = int.parse(digits.substring(4, 6));

    DateTime? dob;
    if (mm < 1 || mm > 12) {
      problems.add('Digits 3 and 4 are the month, and $mm is not a month.');
    } else if (dd < 1 || dd > 31) {
      problems.add('Digits 5 and 6 are the day, and $dd is not a day.');
    } else {
      final thisYear = DateTime.now().year % 100;
      final century = yy <= thisYear ? 2000 : 1900;
      final candidate = DateTime(century + yy, mm, dd);
      if (candidate.month != mm || candidate.day != dd) {
        problems.add('The date of birth in this number does not exist.');
      } else {
        dob = candidate;
      }
    }

    final sequence = int.parse(digits.substring(6, 10));
    final gender = sequence < 5000 ? 'Female' : 'Male';

    final citizenDigit = int.parse(digits.substring(10, 11));
    if (citizenDigit > 1) {
      problems.add('Digit 11 should be 0 or 1, and it is $citizenDigit.');
    }

    if (!_luhnValid(digits)) {
      problems.add(
        'The check digit does not match. One of the digits has probably been typed wrong.',
      );
    }

    return SaIdNumber._(
      digits: digits,
      isValid: problems.isEmpty,
      problems: problems,
      dateOfBirth: dob,
      gender: gender,
      isCitizen: citizenDigit == 0,
    );
  }

  /// The Luhn checksum that the thirteenth digit encodes.
  static bool _luhnValid(String digits) {
    var sum = 0;
    var double = false;
    for (var i = digits.length - 1; i >= 0; i--) {
      var value = int.parse(digits[i]);
      if (double) {
        value *= 2;
        if (value > 9) value -= 9;
      }
      sum += value;
      double = !double;
    }
    return sum % 10 == 0;
  }
}
