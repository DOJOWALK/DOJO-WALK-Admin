/// Validates an optional Indian PIN code field.
///
/// Blank is allowed. When provided, the value must contain exactly six digits.
String? validateOptionalIndianPincode(String? value) {
  final pin = value?.trim() ?? '';

  if (pin.isEmpty) return null;
  if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
    return 'Enter a valid 6-digit PIN code or leave it blank';
  }

  return null;
}
