// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Entry Point';

  @override
  String get loginTitle => 'Добро пожаловать';

  @override
  String get loginSubtitle => 'Войдите в свой аккаунт';

  @override
  String get email => 'Email';

  @override
  String get password => 'Пароль';

  @override
  String get name => 'Имя';

  @override
  String get login => 'Войти';

  @override
  String get register => 'Зарегистрироваться';

  @override
  String get logout => 'Выйти';

  @override
  String get forgotPassword => 'Забыли пароль?';

  @override
  String get noAccount => 'Нет аккаунта?';

  @override
  String get items => 'Элементы';

  @override
  String get create => 'Создать';

  @override
  String get edit => 'Редактировать';

  @override
  String get delete => 'Удалить';

  @override
  String get search => 'Поиск...';

  @override
  String get loading => 'Загрузка...';

  @override
  String get emptyList => 'Список пуст';

  @override
  String get retry => 'Повторить';

  @override
  String get profile => 'Профиль';

  @override
  String get theme => 'Тема оформления';

  @override
  String get themeSystem => 'Системная';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get title => 'Заголовок';

  @override
  String get description => 'Описание';

  @override
  String get addImage => 'Добавить изображение';

  @override
  String get camera => 'Камера';

  @override
  String get gallery => 'Галерея';

  @override
  String get save => 'Сохранить';

  @override
  String get cancel => 'Отмена';

  @override
  String get createdAt => 'Создано';

  @override
  String get errorUnknown => 'Неизвестная ошибка.';

  @override
  String get errorNetwork => 'Нет интернет-соединения.';

  @override
  String get errorUnauthorized => 'Необходима авторизация.';

  @override
  String get registrationSuccess => 'Регистрация прошла успешно! Войдите.';
}
