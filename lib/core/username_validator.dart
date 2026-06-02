class UsernameValidator {
  UsernameValidator._();

  static const _minLength = 3;
  static const _maxLength = 30;

  static const _reservedWords = {
    'admin',
    'leafmark',
    'support',
    'help',
    'official',
    'moderator',
  };

  // a-z, 0-9, underscores, dots
  static final _validPattern = RegExp(r'^(?!.*\.\.)[a-z0-9._]{3,30}$');

  static String? validate(String? value) {
    if (value == null || value.isEmpty) return 'Username is required';

    final v = value.trim();

    if (v.length < _minLength) return 'At least $_minLength characters';
    if (v.length > _maxLength) return 'Max $_maxLength characters';
    if (!_validPattern.hasMatch(v)) {
      return 'Only lowercase letters, numbers, . and _ (no consecutive dots)';
    }
    if (_reservedWords.contains(v)) return 'This username is not available';

    return null;
  }
}
