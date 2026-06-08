import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  ApiConstants._();

  // Utilisez 'localhost' pour le Web, 10.0.2.2 pour Android
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8085'; 
    return 'http://10.0.2.2:8085';
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