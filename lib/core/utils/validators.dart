/// Shared form validators.
class AppValidators {
  AppValidators._();

  /// Optional mobile: empty OK, otherwise exactly 10 digits.
  static String? mobileOptional(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    if (v.length != 10 || !RegExp(r'^\d{10}$').hasMatch(v)) {
      return 'Mobile number must be exactly 10 digits';
    }
    return null;
  }

  /// Required mobile: exactly 10 digits.
  static String? mobileRequired(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Mobile number is required';
    if (v.length != 10 || !RegExp(r'^\d{10}$').hasMatch(v)) {
      return 'Mobile number must be exactly 10 digits';
    }
    return null;
  }
}
