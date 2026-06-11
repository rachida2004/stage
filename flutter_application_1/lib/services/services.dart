import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../core/api_constants.dart';
import '../core/api_client.dart';
import '../models/models.dart';
import 'storage_service.dart';

class SL {
  SL._();
  static final SL _i = SL._();
  static SL get instance => _i;

  late final StorageService storage;
  late final ApiClient apiClient;
  late final AuthService auth;
  late final DashboardService dashboard;
  late final InvitationService invitations;
  late final TicketService tickets;
  late final NotificationService notifications;
  late final AdminService admin;

  Future<void> init() async {
    final secure = kIsWeb ? null : const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true));
    storage = StorageService(secure: secure);
    apiClient     = ApiClient(storage);
    auth          = AuthService(apiClient, storage);
    dashboard     = DashboardService(apiClient);
    invitations   = InvitationService(apiClient);
    tickets       = TicketService(apiClient);
    notifications = NotificationService(apiClient, storage);
    admin         = AdminService(apiClient);
  }

  T call<T>() {
    if (T == AdminService) return admin as T;
    if (T == AuthService) return auth as T;
    if (T == DashboardService) return dashboard as T;
    if (T == InvitationService) return invitations as T;
    if (T == TicketService) return tickets as T;
    if (T == NotificationService) return notifications as T;
    if (T == StorageService) return storage as T;
    if (T == ApiClient) return apiClient as T;
    throw Exception("Le service de type $T n'est pas enregistré dans le Service Locator SL.");
  }
}

SL get sl => SL.instance;

// ════════════════════════════════════════════════════════════════════
// INVITATION SERVICE (MIS À JOUR)
// ════════════════════════════════════════════════════════════════════

class InvitationService {
  final ApiClient _api;
  InvitationService(this._api);

  Future<InvitationPage> getAll({int page = 0, String? search, InvitationStatus? status}) async {
    try {
      final Map<String, dynamic> query = {'page': page, 'size': 10};
      if (search != null && search.isNotEmpty) query['search'] = search;
      if (status != null) query['status'] = status.apiValue;

      final res = await _api.dio.get(ApiConstants.invitations, queryParameters: query);
      return InvitationPage.fromJson(res.data);
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  Future<Invitation> getById(String id) async {
    try { return Invitation.fromJson((await _api.dio.get('${ApiConstants.invitations}/$id')).data); }
    on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  Future<Invitation> create(
    Map<String, dynamic> data, {
    List<MapEntry<String, Uint8List>> fileBytes = const [],
  }) async {
    try {
      final Map<String, dynamic> payload = {};

      // 1. On met à plat les paramètres simples
payload['objet'] = data['objet'] ?? '';
payload['nombreParticipants'] = data['nombreParticipants'] ?? 0;
payload['visibilite'] = data['visibilite'] ?? 'PUBLIC';

// N'envoie la clé QUE si la date est réellement renseignée et non vide
if (data['dateDebut'] != null && data['dateDebut'].toString().isNotEmpty) {
  payload['dateDebut'] = data['dateDebut'];
}
if (data['dateFin'] != null && data['dateFin'].toString().isNotEmpty) {
  payload['dateFin'] = data['dateFin'];
}

if (data['structureEmettriceId'] != null) {
  payload['structureEmettriceId'] = data['structureEmettriceId'];
}
      // 2. On gère les fichiers en respectant scrupuleusement la clé 'files' au pluriel
      if (fileBytes.isNotEmpty) {
        final List<MultipartFile> multipartFiles = [];
        for (final file in fileBytes) {
          multipartFiles.add(
            MultipartFile.fromBytes(
              file.value,
              filename: file.key,
            ),
          );
        }
        // Spring Boot recevra une List<MultipartFile> via la clé "files"
        payload['files'] = multipartFiles;
      }

      final requestData = FormData.fromMap(payload);
      final res = await _api.dio.post(ApiConstants.invitations, data: requestData);
      return Invitation.fromJson(res.data);
    } on DioException catch (e) { 
      throw ApiException.fromDio(e); 
    }
  }

  Future<Invitation> update(String id, Map<String, dynamic> data) async {
    try { return Invitation.fromJson((await _api.dio.put('${ApiConstants.invitations}/$id', data: data)).data); }
    on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  Future<void> delete(String id) async {
    try { await _api.dio.delete('${ApiConstants.invitations}/$id'); }
    on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  Future<Invitation> updateStatus(String id, InvitationStatus status) async {
    try {
      return Invitation.fromJson((await _api.dio.patch(
        '${ApiConstants.invitations}/$id/status',
        queryParameters: {'status': status.apiValue},
      )).data);
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  /// Affecte une liste d'agents à une invitation en un seul appel batch.
  /// Le backend crée les affectations ET les notifications automatiquement.
  /// POST /api/invitations/{invId}/affecter  body: { agentIds: [...], responsableId: ... }
  Future<Invitation> affecterAgents(String invId, List<String> agentIds, {String? responsableId}) async {
    try {
      final res = await _api.dio.post(
        '${ApiConstants.invitations}/$invId/affecter',
        data: {
          'agentIds': agentIds.map((id) => int.tryParse(id) ?? id).toList(),
          'responsableId': responsableId != null ? (int.tryParse(responsableId) ?? responsableId) : null,
        },
      );
      return Invitation.fromJson(res.data);
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }
}

// ════════════════════════════════════════════════════════════════════
// TICKET SERVICE
// ════════════════════════════════════════════════════════════════════

class TicketService {
  final ApiClient _api;
  TicketService(this._api);

  Future<TicketPage> getAll({int page = 0, String? search,
      TicketStatus? status, TicketPriority? priority, String? currentUserId}) async {
    try {
      final res = await _api.getTickets(
        page: page,
        size: 10,
        search: search,
        statut: status?.apiValue,
        priorite: priority?.apiValue,
      );
      return TicketPage.fromJson(res.data, currentUserId: currentUserId);
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  Future<Ticket> getById(String id, {String? currentUserId}) async {
    try { 
      final int ticketId = int.parse(id);
      final res = await _api.getTicketById(ticketId);
      return Ticket.fromJson(res.data, currentUserId: currentUserId); 
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  Future<Ticket> create(Map<String, dynamic> data, {Uint8List? fileBytes}) async {
    try {
      final res = await _api.creerTicketMultipart(
        description: data['description'] ?? '',
        structure: data['structure'],
        priority: data['priority'] ?? 'MOYENNE',
        fileBytes: fileBytes,
        fileName: data['attachmentName'],
        createurId: data['createurId'] != null ? int.tryParse(data['createurId'].toString()) : null,
      );
      return Ticket.fromJson(res.data);
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  Future<Ticket> updateStatut(String id, TicketStatus statut,
      {String? solution, String? currentUserId}) async {
    try {
      final int ticketId = int.parse(id);
      final res = await _api.changerStatut(
        ticketId: ticketId,
        statut: statut.apiValue,
        solution: solution,
      );
      return Ticket.fromJson(res.data, currentUserId: currentUserId);
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  Future<Ticket> affecterAgent(String id, String agentId, {String? currentUserId}) async {
    try {
      final int tId = int.parse(id);
      final int aId = int.parse(agentId);
      final res = await _api.affecterAgent(ticketId: tId, agentId: aId);
      return Ticket.fromJson(res.data, currentUserId: currentUserId);
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  Future<Ticket> envoyerMessage(String ticketId, String message, {String? currentUserId}) async {
    try {
      if (currentUserId == null || currentUserId.isEmpty) {
        throw Exception("Impossible d'envoyer le message : ID utilisateur manquant.");
      }
      
      final int idTicket = int.parse(ticketId);
      final int idAuteur = int.parse(currentUserId);

      final res = await _api.envoyerMessage(
        ticketId: idTicket,
        message: message,
        auteurId: idAuteur,
      );
      
      return Ticket.fromJson(res.data, currentUserId: currentUserId);
    } on DioException catch (e) { 
      throw ApiException.fromDio(e); 
    }
  }
}

// ════════════════════════════════════════════════════════════════════
// AUTH SERVICE
// ════════════════════════════════════════════════════════════════════

class AuthService {
  final ApiClient _api;
  final StorageService _storage;
  AuthService(this._api, this._storage);

  Future<AuthResponse> login(String email, String password) async {
    try {
      final res = await _api.dio.post(ApiConstants.login,
          data: {'email': email, 'password': password});
      final auth = AuthResponse.fromJson(res.data);
      await _storage.saveSession(
        accessToken:  auth.accessToken,
        refreshToken: auth.refreshToken,
        userId:       auth.userId,
        userNom:      '${auth.nom} ${auth.prenom}',
        userRole:     auth.role,
        initiales:    auth.initiales,
      );
      return auth;
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  Future<AuthResponse> register(Map<String, dynamic> data) async {
    try {
      final res = await _api.dio.post(ApiConstants.register, data: data);
      final auth = AuthResponse.fromJson(res.data);
      await _storage.saveSession(
        accessToken:  auth.accessToken,
        refreshToken: auth.refreshToken,
        userId:       auth.userId,
        userNom:      '${auth.nom} ${auth.prenom}',
        userRole:     auth.role,
        initiales:    auth.initiales,
      );
      return auth;
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  Future<void> logout() async {
    try { await _api.dio.post(ApiConstants.logout); } catch (_) {}
    await _storage.clearSession();
  }

  Future<void> forgotPassword(String email) async {
    try { await _api.dio.post(ApiConstants.forgotPassword, data: {'email': email}); }
    on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  /// Étape 2 — Soumet le code reçu par email + le nouveau mot de passe.
  /// POST /api/auth/reinitialiser-mot-de-passe
  Future<void> resetPassword(String code, String nouveauMotDePasse) async {
    try {
      await _api.dio.post(
        '/api/auth/reinitialiser-mot-de-passe',
        data: {'code': code, 'nouveauMotDePasse': nouveauMotDePasse},
      );
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  Future<bool> isLoggedIn()             => _storage.isLoggedIn();
  Future<String?> get currentUserId     => _storage.userId;
  Future<String?> get currentUserNom    => _storage.userNom;
  Future<String?> get currentInitiales  => _storage.initiales;
}

// getagent ══
// DASHBOARD SERVICE
// ════════════════════════════════════════════════════════════════════

class DashboardService {
  final ApiClient _api;
  DashboardService(this._api);

  Future<DashboardStats> getStats() async {
    try { return DashboardStats.fromJson((await _api.dio.get(ApiConstants.dashStats)).data); }
    on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  Future<List<Invitation>> getRecentInvitations() async {
    try {
      final res = await _api.dio.get(ApiConstants.invitations, queryParameters: {'page': 0, 'size': 5});
      final data = res.data;
      if (data is Map && data.containsKey('content')) {
        return (data['content'] as List).map((e) => Invitation.fromJson(e)).toList();
      }
      if (data is List) {
        return data.map((e) => Invitation.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  Future<List<Ticket>> getRecentTickets() async {
    try {
      final res = await _api.dio.get(ApiConstants.tickets, queryParameters: {'page': 0, 'size': 5});
      final data = res.data;
      if (data is Map && data.containsKey('content')) {
        return (data['content'] as List).map((e) => Ticket.fromJson(e)).toList();
      }
      if (data is List) {
        return data.map((e) => Ticket.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }
}

// ════════════════════════════════════════════════════════════════════
// NOTIFICATION SERVICE
// ════════════════════════════════════════════════════════════════════

class NotificationService {
  final ApiClient _api;
  final StorageService _storage;
  NotificationService(this._api, this._storage);

  Future<List<NotificationModel>> getAll() async {
    try {
      final uid = await _storage.userId ?? '';
      final res = await _api.dio.get('/api/notifications/user/$uid');
      if (res.data is List) {
        return (res.data as List).map((e) => NotificationModel.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _api.dio.put('/api/notifications/$id/lire');
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  Future<void> markAllAsRead() async {
    try {
      await _api.dio.put('/api/notifications/lire-tout');
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  Future<int> getUnreadCount() async {
    try {
      final uid = await _storage.userId ?? '';
      final res = await _api.dio.get('/api/notifications/user/$uid/unread-count');
      return res.data['count'] ?? 0;
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

}

// ════════════════════════════════════════════════════════════════════
// ADMIN SERVICE
// ════════════════════════════════════════════════════════════════════

class AdminService {
  final ApiClient _api;
  AdminService(this._api);

  Future<List<AppUser>> getUsers() async {
    try {
      final res = await _api.dio.get(ApiConstants.adminUsers);
      final data = res.data;
      if (data is Map && data.containsKey('content')) {
        return (data['content'] as List).map((u) => AppUser.fromJson(u)).toList();
      }
      if (data is List) {
        return data.map((u) => AppUser.fromJson(u)).toList();
      }
      return [];
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  Future<AppUser> createUser(Map<String, dynamic> data) async {
    try { return AppUser.fromJson((await _api.dio.post('/api/auth/register', data: data)).data); }
    on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  Future<AppUser> updateUser(String id, Map<String, dynamic> data) async {
    try { return AppUser.fromJson((await _api.dio.put('${ApiConstants.users}/$id', data: data)).data); }
    on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  Future<void> toggleUser(String id) async {
    try { await _api.dio.patch('${ApiConstants.adminUsers}/$id/toggle'); }
    on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  // ════════════════════════════════════════════════════════════════════
  // METHODE GET AGENTS OPTIMISÉE
  // ════════════════════════════════════════════════════════════════════
  Future<List<AppUser>> getAgents() async {
    try {
      // 1. On tente d'abord l'appel standard configuré sur ton backend
      final res = await _api.dio.get('/api/agents');
      final data = res.data;
      
      // On extrait la liste proprement, que ce soit un tableau direct ou paginé
      List<dynamic> rawList = [];
      if (data is List) {
        rawList = data;
      } else if (data is Map && data.containsKey('content')) {
        rawList = data['content'] as List;
      }

      // On filtre directement ici pour ne renvoyer QUE les utilisateurs actifs
      return rawList
          .map((u) => AppUser.fromJson(u))
          .where((user) => user.isActive)
          .toList();

    } on DioException catch (e) {
      // Sécurité : Si le préfixe globale engendre une erreur 404 (ex: base URL inclut déjà /api)
      if (e.response?.statusCode == 404) {
        try {
          final fallbackRes = await _api.dio.get('/agents');
          final fallbackData = fallbackRes.data;
          
          List<dynamic> fallbackList = [];
          if (fallbackData is List) {
            fallbackList = fallbackData;
          } else if (fallbackData is Map && fallbackData.containsKey('content')) {
            fallbackList = fallbackData['content'] as List;
          }

          return fallbackList
              .map((u) => AppUser.fromJson(u))
              .where((user) => user.isActive)
              .toList();
        } catch (_) {}
      }
      throw ApiException.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> getSettings() async => {};
  Future<void> saveSettings(Map<String, dynamic> data) async {}
}
// ════════════════════════════════════════════════════════════════════
// API EXCEPTION
// ════════════════════════════════════════════════════════════════════

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  factory ApiException.fromDio(DioException e) {
    final code = e.response?.statusCode;
    final body = e.response?.data;
    String msg;
    if (body is Map && body.containsKey('message')) {
      msg = body['message'];
    } else if (body is String && body.isNotEmpty) {
      msg = body;
    } else {
      msg = e.message ?? 'Erreur réseau';
    }
    return ApiException(msg, statusCode: code);
  }

  @override
  String toString() => message;
}