import 'package:dojo_admin/features/service_location/services/optional_indian_pincode_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validateOptionalIndianPincode', () {
    test('allows an empty optional PIN code', () {
      expect(validateOptionalIndianPincode(null), isNull);
      expect(validateOptionalIndianPincode(''), isNull);
      expect(validateOptionalIndianPincode('   '), isNull);
    });

    test('accepts exactly six digits', () {
      expect(validateOptionalIndianPincode('201009'), isNull);
      expect(validateOptionalIndianPincode(' 201009 '), isNull);
    });

    test('rejects fewer or more than six digits', () {
      expect(validateOptionalIndianPincode('12345'), isNotNull);
      expect(validateOptionalIndianPincode('1234567'), isNotNull);
    });

    test('rejects letters and non-digit characters', () {
      expect(validateOptionalIndianPincode('12A456'), isNotNull);
      expect(validateOptionalIndianPincode('12 456'), isNotNull);
      expect(validateOptionalIndianPincode('-12345'), isNotNull);
    });
  });
}
