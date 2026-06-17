class AuthValidators {
  AuthValidators._();

  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
  );

  // Returns null if valid, error message if invalid.
  static String? validateEmail(String value) {
    if (value.trim().isEmpty) return 'Email is required.';
    if (!_emailRegex.hasMatch(value.trim())) return 'Enter a valid email address.';
    return null;
  }

  static String? validatePassword(String value) {
    if (value.isEmpty) return 'Password is required.';
    if (value.length < 8) return 'Password must be at least 8 characters.';
    return null;
  }

  static String? validateConfirmPassword(String password, String confirm) {
    if (confirm.isEmpty) return 'Please confirm your password.';
    if (password != confirm) return 'Passwords do not match.';
    return null;
  }

  static String? validateUsername(String value) {
    if (value.trim().isEmpty) return 'Username is required.';
    if (value.trim().length < 8) return 'Username must be at least 8 characters.';
    return null;
  }

  static String? validateFullName(String value) {
    if (value.trim().isEmpty) return 'Full name is required.';
    return null;
  }
}
