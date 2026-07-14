import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  ApiConstants._();

  // 🎯 Pour tester sur un téléphone physique (pas l'émulateur), lance l'app avec :
  //   flutter run --dart-define=API_HOST=192.168.1.42
  // en remplaçant par l'IP locale de ton PC sur le même Wi-Fi que le téléphone
  // (visible via `ipconfig` sous Windows, ligne "Adresse IPv4").
  // Sans ce paramètre, le comportement par défaut ne change pas :
  // web -> localhost, émulateur Android -> 10.0.2.2.
  static const String _apiHost = String.fromEnvironment('API_HOST', defaultValue: '');

  static String get baseUrl {
    if (_apiHost.isNotEmpty) return 'http://$_apiHost:8085';
    if (kIsWeb) return 'http://localhost:8085';
    return 'http://10.0.2.2:8085'; // Émulateur Android uniquement
  }

  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;
  static const int pageSize       = 20;

  // Préfixez toutes les routes avec /api ici
  static const String login          = '/api/auth/login';
  static const String register       = '/api/auth/register';
  static const String logout         = '/api/auth/logout';
  static const String forgotPassword = '/api/auth/mot-de-passe-oublie';

  static const String dashStats   = '/api/dashboard/stats';
  static const String invitations = '/api/invitations';
  static const String tickets     = '/api/tickets';
  static const String users       = '/api/users';
  static const String adminUsers  = '/api/admin/users';
}