class Validators {
  Validators._();

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Введите email';
    final re = RegExp(r'^[\w.+-]+@\w+\.\w+$');
    if (!re.hasMatch(value.trim())) return 'Некорректный email';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Введите пароль';
    if (value.length < 6) return 'Минимум 6 символов';
    return null;
  }

  static String? required(String? value, [String label = 'Поле']) {
    if (value == null || value.trim().isEmpty) return '$label обязательно';
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) return 'Введите имя';
    if (value.trim().length < 2) return 'Минимум 2 символа';
    return null;
  }
}
