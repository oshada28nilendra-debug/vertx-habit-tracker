abstract final class AuthValidation {
  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Enter your email address.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  static String? name(String? value) =>
      value == null || value.trim().isEmpty ? 'Enter your name.' : null;
  static String? signInPassword(String? value) =>
      value == null || value.isEmpty ? 'Enter your password.' : null;
  static String? newPassword(String? value) {
    if (value == null || value.isEmpty) return 'Enter a password.';
    if (value.length < 6) return 'Use at least 6 characters.';
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Include an uppercase letter.';
    }
    if (!value.contains(RegExp(r'[0-9]'))) return 'Include a number.';
    return null;
  }
}
