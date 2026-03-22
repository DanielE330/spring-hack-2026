class ApiConstants {
  ApiConstants._();

  static const String baseUrl =
      String.fromEnvironment('BASE_URL', defaultValue: 'http://194.113.106.32');

  static const int connectTimeoutMs = 15000;
  static const int receiveTimeoutMs = 30000;
  static const int sendTimeoutMs = 30000;

  // Endpoints — Auth
  static const String login           = '/auth/login/';
  static const String logout          = '/auth/logout/';
  static const String firstAdmin      = '/auth/first-admin/';
  static const String createUser      = '/auth/create-user/';
  static const String passwordReset   = '/auth/password-reset/';

  // Endpoints — User
  static const String me        = '/users/me/';
  static const String myAvatar  = '/users/me/avatar/';
  static const String myDevices = '/users/me/devices/';
  static String deviceById(String id) => '/users/me/devices/$id/';

  // Endpoints — Admin
  static String adminDeviceById(String id) => '/admin/devices/$id/';

  // Endpoints — QR
  static const String qrGenerate = '/qr/generate/';
  static const String qrValidate = '/qr/validate/';

  // Endpoints — Reports
  static const String reportsAttendance = '/reports/attendance/';
}
  