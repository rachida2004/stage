import 'dart:typed_data';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../core/api_constants.dart';
import '../core/api_client.dart';
import '../models/models.dart';
import 'storage_service.dart';

// ════════════════════════════════════════════════════════════════════
// SERVICE LOCATOR
// ════════════════════════════════════════════════════════════════════

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
    storage       = StorageService(secure: secure);
    apiClient     = ApiClient(storage);
    auth          = AuthService(apiClient, storage);
    dashboard     = DashboardService(apiClient);
    invitations   = InvitationService(apiClient);
    tickets       = TicketService(apiClient);
    notifications = NotificationService(apiClient, storage);
    admin         = AdminService(apiClient);
  }

  T call<T>() {
    if (T == AdminService)        return admin as T;
    if (T == AuthService)         return auth as T;
    if (T == DashboardService)    return dashboard as T;
    if (T == InvitationService)   return invitations as T;
    if (T == TicketService)       return tickets as T;
    if (T == NotificationService) return notifications as T;
    if (T == StorageService)      return storage as T;
    if (T == ApiClient)           return apiClient as T;
    throw Exception("Service $T non enregistré dans SL.");
  }
}

SL get sl => SL.instance;
// ════════════════════════════════════════════════════════════════════
// INVITATION SERVICE
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

  // 🎯 AJOUT : Récupération des invitations reçues depuis Spring Boot
  Future<InvitationPage> getInvitationsRecues() async {
    try {
      // Modifie '${ApiConstants.invitations}/recues' si ta route Spring Boot est différente
      final res = await _api.dio.get('${ApiConstants.invitations}/recues');
      return InvitationPage.fromJson(res.data);
    } on DioException catch (e) { 
      throw ApiException.fromDio(e); 
    }
  }

  Future<Invitation> getById(String id) async {
    try { return Invitation.fromJson((await _api.dio.get('${ApiConstants.invitations}/$id')).data); }
    on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  Future<Invitation> create(Map<String, dynamic> data,
      {List<MapEntry<String, Uint8List>> fileBytes = const []}) async {
    try {
      final payload = <String, dynamic>{
        'objet':               data['objet'] ?? '',
        'nombreParticipants':  data['nombreParticipants'] ?? 0,
        'visibilite':          data['visibilite'] ?? 'PUBLIC',
        'lieu':                data['lieu'] ?? '',
      };
      if (data['nomStructure'] != null && data['nomStructure'].toString().isNotEmpty)
        payload['nomStructure'] = data['nomStructure'];
      if (data['dateDebut'] != null) payload['dateDebut'] = data['dateDebut'];
      if (data['dateFin'] != null)   payload['dateFin']   = data['dateFin'];
      if (data['structureEmettriceId'] != null) payload['structureEmettriceId'] = data['structureEmettriceId'];
      if (fileBytes.isNotEmpty) {
        payload['files'] = fileBytes.map((f) =>
          MultipartFile.fromBytes(f.value, filename: f.key)).toList();
      }
      final res = await _api.dio.post(ApiConstants.invitations, data: FormData.fromMap(payload));
      return Invitation.fromJson(res.data);
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  Future<Invitation> update(String id, Map<String, dynamic> data) async {
    print("--- DÉBUT DE LA REQUÊTE ---");
    print("URL: ${ApiConstants.invitations}/$id");
    print("DATA: $data");
    try { 
      final res = await _api.dio.put('${ApiConstants.invitations}/$id', data: data);
      print("--- SUCCÈS: ${res.statusCode} ---");
      return Invitation.fromJson(res.data);
    } on DioException catch (e) {
      print("--- ERREUR DIO ---");
      print("Message: ${e.message}");
      print("Response: ${e.response?.data}"); 
      throw ApiException.fromDio(e); 
    }
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

  Future<Invitation> affecterAgents(String invId, List<String> agentIds, {String? responsableId}) async {
    try {
      final parsedIds = agentIds.map((id) => int.tryParse(id)).whereType<int>().toList();
      final parsedResp = responsableId != null ? int.tryParse(responsableId) : null;
      final res = await _api.dio.post(
        '${ApiConstants.invitations}/$invId/affecter',
        data: {'agentIds': parsedIds, 'responsableId': parsedResp},
      );
      return Invitation.fromJson(res.data);
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }
}

/// ════════════════════════════════════════════════════════════════════
// TICKET SERVICE COMPLET
// ════════════════════════════════════════════════════════════════════

class TicketService {
  final ApiClient _api;
  TicketService(this._api);

  Future<TicketPage> getAll({
    int page = 0, 
    String? search,
    TicketStatus? status, 
    TicketPriority? priority, 
    String? currentUserId
  }) async {
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
      final res = await _api.getTicketById(int.parse(id));
      return Ticket.fromJson(res.data, currentUserId: currentUserId);
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  // 🎯 Reçoit proprement la liste multiFiles préparée par le Bloc
  Future<Ticket> create(
    Map<String, dynamic> data, {
    Uint8List? fileBytes, 
    List<MapEntry<String, Uint8List>> multiFiles = const []
  }) async {
    try {
      final res = await _api.creerTicketMultipart(
        description: data['description'] ?? '',
        structure: data['structure'],
        priority: data['priority'] ?? 'MOYENNE',
        fileBytes: fileBytes,
        fileName: data['attachmentName'],
        // On repasse la liste nettoyée et typée à ton ApiClient (Dio)
        multiFiles: multiFiles.map((e) => MapEntry(e.key, e.value.toList())).toList(),
        createurId: data['createurId'] != null ? int.tryParse(data['createurId'].toString()) : null,
        whatsapp: data['whatsapp'],
      );
      return Ticket.fromJson(res.data);
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  Future<void> delete(String id) async {
    try { await _api.dio.delete('/api/tickets/$id'); }
    on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  Future<List<Structure>> getStructures() async {
    try {
      final res = await _api.dio.get('/api/structures');
      return (res.data as List).map((s) => Structure.fromJson(s)).toList();
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  Future<List<Service>> getServices({int? structureId}) async {
    try {
      final params = structureId != null ? {'structureId': structureId} : null;
      final res = await _api.dio.get('/api/services', queryParameters: params);
      return (res.data as List).map((s) => Service.fromJson(s)).toList();
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  Future<Ticket> updateStatut(
    String id, 
    TicketStatus statut, {
    String? solution, 
    String? currentUserId
  }) async {
    try {
      final res = await _api.changerStatut(
        ticketId: int.parse(id),
        statut: statut.apiValue,
        solution: solution,
      );
      return Ticket.fromJson(res.data, currentUserId: currentUserId);
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  Future<Ticket> affecterAgent(String id, String agentId, {String? currentUserId}) async {
    try {
      final res = await _api.affecterAgent(ticketId: int.parse(id), agentId: int.parse(agentId));
      return Ticket.fromJson(res.data, currentUserId: currentUserId);
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  Future<Ticket> envoyerMessage(String ticketId, String message, {String? currentUserId}) async {
    try {
      if (currentUserId == null || currentUserId.isEmpty) {
        throw Exception("ID utilisateur manquant pour l'envoi du message.");
      }
      final res = await _api.envoyerMessage(
        ticketId: int.parse(ticketId),
        message: message,
        auteurId: int.parse(currentUserId),
      );
      return Ticket.fromJson(res.data, currentUserId: currentUserId);
    } on DioException catch (e) { throw ApiException.fromDio(e); }
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
      final res = await _api.dio.post(ApiConstants.login, data: {'email': email, 'password': password});
      final auth = AuthResponse.fromJson(res.data);
      await _storage.saveSession(
        accessToken: auth.accessToken, refreshToken: auth.refreshToken,
        userId: auth.userId, userNom: '${auth.nom} ${auth.prenom}',
        userRole: auth.role, initiales: auth.initiales,
      );
      return auth;
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  Future<AuthResponse> register(Map<String, dynamic> data) async {
    try {
      final res = await _api.dio.post(ApiConstants.register, data: data);
      final auth = AuthResponse.fromJson(res.data);
      await _storage.saveSession(
        accessToken: auth.accessToken, refreshToken: auth.refreshToken,
        userId: auth.userId, userNom: '${auth.nom} ${auth.prenom}',
        userRole: auth.role, initiales: auth.initiales,
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

  Future<void> resetPassword(String code, String nouveauMotDePasse) async {
    try {
      await _api.dio.post('/api/auth/reinitialiser-mot-de-passe',
        data: {'code': code, 'nouveauMotDePasse': nouveauMotDePasse});
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  Future<bool> isLoggedIn()            => _storage.isLoggedIn();
  Future<String?> get currentUserId    => _storage.userId;
  Future<String?> get currentUserNom   => _storage.userNom;
  Future<String?> get currentInitiales => _storage.initiales;
}

// ════════════════════════════════════════════════════════════════════
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
      final res  = await _api.dio.get(ApiConstants.invitations, queryParameters: {'page': 0, 'size': 5});
      final data = res.data;
      if (data is Map && data.containsKey('content'))
        return (data['content'] as List).map((e) => Invitation.fromJson(e)).toList();
      if (data is List) return data.map((e) => Invitation.fromJson(e)).toList();
      return [];
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  Future<List<Ticket>> getRecentTickets() async {
    try {
      final res  = await _api.dio.get(ApiConstants.tickets, queryParameters: {'page': 0, 'size': 5});
      final data = res.data;
      if (data is Map && data.containsKey('content'))
        return (data['content'] as List).map((e) => Ticket.fromJson(e)).toList();
      if (data is List) return data.map((e) => Ticket.fromJson(e)).toList();
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
      if (res.data is List)
        return (res.data as List).map((e) => NotificationModel.fromJson(e)).toList();
      return [];
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  Future<void> markAsRead(String id) async {
    try { await _api.dio.put('/api/notifications/$id/lire'); }
    on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  Future<void> markAllAsRead() async {
    try { await _api.dio.put('/api/notifications/lire-tout'); }
    on DioException catch (e) { throw ApiException.fromDio(e); }
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
// ADMIN SERVICE — avec CRUD complet Structure et Service
// ════════════════════════════════════════════════════════════════════

class AdminService {
  final ApiClient _api;
  AdminService(this._api);

  // ── Utilisateurs ─────────────────────────────────────────────────

Future<List<AppUser>> getUsers() async {
    try {
      final res = await _api.dio.get(ApiConstants.adminUsers);
      
      // On affiche le JSON reçu pour être sûr
      print("JSON REÇU : ${res.data}");

      final List<dynamic> raw = (res.data is List) ? res.data : [];
      
      // On retire le try-catch pour voir l'erreur si elle existe
      return raw.map((u) => AppUser.fromJson(u)).toList();
      
    } on DioException catch (e) { 
      throw ApiException.fromDio(e); 
    }
  }

  Future<AppUser> createUser(Map<String, dynamic> data) async {
    try { return AppUser.fromJson((await _api.dio.post('/api/auth/register', data: data)).data); }
    on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  Future<AppUser> updateUser(String id, Map<String, dynamic> data) async {
    try { return AppUser.fromJson((await _api.dio.put('${ApiConstants.adminUsers}/$id', data: data)).data); }
    on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  Future<void> toggleUser(String id) async {
    try { await _api.dio.patch('${ApiConstants.adminUsers}/$id/toggle'); }
    on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  Future<List<AppUser>> getAgents() async {
    try {
      final res  = await _api.dio.get('/api/agents');
      final data = res.data;
      final raw  = data is List ? data as List
          : data is Map && data.containsKey('content') ? data['content'] as List : [];
      return raw.map((u) => AppUser.fromJson(u)).where((u) => u.isActive).toList();
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  // ── Paramètres ───────────────────────────────────────────────────

  Future<Map<String, dynamic>> getSettings() async {
    try {
      final res    = await _api.dio.get('/api/admin/settings');
      final remote = Map<String, dynamic>.from(res.data);
      final s      = SL.instance.storage;
      remote.forEach((k, v) => s.write('settings_$k', v.toString()));
      return remote;
    } catch (_) {
      final s = SL.instance.storage;
      return {
        'notificationsEmail':    (await s.read('settings_notificationsEmail')) != 'false',
        'notificationsInternes': (await s.read('settings_notificationsInternes')) != 'false',
        'delaiMaxSansAffectation': await s.read('settings_delaiMaxSansAffectation') ?? '48h',
        'langue': await s.read('settings_langue') ?? 'Français',
      };
    }
  }

  Future<void> saveSettings(Map<String, dynamic> data) async {
    try {
      await _api.dio.post('/api/admin/settings', data: data);
      final s = SL.instance.storage;
      for (final e in data.entries) await s.write('settings_${e.key}', e.value.toString());
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  // ── Structures — CRUD complet ────────────────────────────────────

  Future<List<Structure>> getStructures() async {
    try {
      final res = await _api.dio.get('/api/structures');
      return (res.data as List).map((s) => Structure.fromJson(s)).toList();
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  Future<Structure> createStructure(Map<String, dynamic> data) async {
    try {
      final res = await _api.dio.post('/api/structures', data: data);
      return Structure.fromJson(res.data);
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  Future<Structure> updateStructure(int id, Map<String, dynamic> data) async {
    try {
      final res = await _api.dio.put('/api/structures/$id', data: data);
      return Structure.fromJson(res.data);
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  Future<void> deleteStructure(int id) async {
    try { await _api.dio.delete('/api/structures/$id'); }
    on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  // ── Services — CRUD complet ──────────────────────────────────────

  Future<List<Service>> getServices({int? structureId}) async {
    try {
      final params = structureId != null ? {'structureId': structureId} : null;
      final res = await _api.dio.get('/api/services', queryParameters: params);
      return (res.data as List).map((s) => Service.fromJson(s)).toList();
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  Future<Service> createService(Map<String, dynamic> data) async {
    try {
      final res = await _api.dio.post('/api/services', data: data);
      return Service.fromJson(res.data);
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  Future<Service> updateService(int id, Map<String, dynamic> data) async {
    try {
      final res = await _api.dio.put('/api/services/$id', data: data);
      return Service.fromJson(res.data);
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  Future<void> deleteService(int id) async {
    try { await _api.dio.delete('/api/services/$id'); }
    on DioException catch (e) { throw ApiException.fromDio(e); }
  }
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