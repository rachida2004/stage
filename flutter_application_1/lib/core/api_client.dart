import 'package:dio/dio.dart';
import '../core/api_constants.dart';
import '../services/storage_service.dart';

class ApiClient {
  late final Dio dio;
  final StorageService _storage;

  // Injection du StorageService dans le constructeur et configuration globale de Dio
  ApiClient(this._storage) {
    dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(milliseconds: ApiConstants.connectTimeout),
      receiveTimeout: const Duration(milliseconds: ApiConstants.receiveTimeout),
      responseType: ResponseType.json,
      headers: {'Accept': 'application/json'},
    ));

    // Ajout de l'intercepteur JWT personnalisé
    dio.interceptors.add(_JwtInterceptor(_storage));
    
    // Ajout du Logging pour le debug (affiche les requêtes et les réponses dans la console)
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      requestHeader: true,
    ));
  }

  // =========================================================================
  // ── MÉTHODES POUR LES TICKETS (LIEN AVEC TICKETCONTROLLER)
  // =========================================================================

  /// 1. RÉCUPÉRER TOUS LES TICKETS (Pagination et Filtres)
  /// Correspond à : GET /api/tickets
  Future<Response> getTickets({
    int page = 0,
    int size = 20,
    String? search,
    String? statut,
    String? priorite,
  }) async {
    try {
      return await dio.get(
        '/api/tickets',
        queryParameters: {
          'page': page,
          'size': size,
          if (search != null && search.isNotEmpty) 'search': search,
          if (statut != null) 'statut': statut,
          if (priorite != null) 'priorite': priorite,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 2. RÉCUPÉRER UN TICKET PAR SON ID
  /// Correspond à : GET /api/tickets/{id}
  Future<Response> getTicketById(int id) async {
    try {
      return await dio.get('/api/tickets/$id');
    } catch (e) {
      rethrow;
    }
  }

  /// 3. ENVOYER UN MESSAGE (Résout l'erreur 400 Bad Request)
  /// Correspond à : POST /api/tickets/{ticketId}/messages
  /// Les paramètres sont transmis dans le corps JSON (data) conformément au @RequestBody attendu
  Future<Response> envoyerMessage({
    required int ticketId,
    required String message,
    required int auteurId,
  }) async {
    try {
      return await dio.post(
        '/api/tickets/$ticketId/messages',
        data: {
          'message': message,
          'auteurId': auteurId, 
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 4. MODIFIER LE STATUT D'UN TICKET (Mettre en pause, Résolu, Fermé)
  /// Correspond à : PUT /api/tickets/{id}/statut
  Future<Response> changerStatut({
    required int ticketId,
    required String statut, // ex: "EN_PAUSE", "RESOLU", "FERME"
    String? solution,
  }) async {
    try {
      final Map<String, String> body = {'statut': statut};
      if (solution != null) body['solution'] = solution;

      return await dio.put(
        '/api/tickets/$ticketId/statut',
        data: body,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 5. CRÉER UN TICKET (Gère le format JSON ou Multipart si un fichier est présent)
  /// Correspond à : POST /api/tickets
  Future<Response> creerTicketMultipart({
    required String description,
    String? structure,
    required String priority, // ex: "FAIBLE", "MOYENNE", "ELEVEE"
    List<int>? fileBytes,
    String? fileName,
    int? createurId,
  }) async {
    try {
      final Map<String, dynamic> formDataMap = {
        'description': description,
        'priority': priority,
      };

      if (structure != null && structure.isNotEmpty) {
        formDataMap['structure'] = structure;
      }
      if (createurId != null) {
        formDataMap['createurId'] = createurId;
      }

      // Si un fichier est joint (sélectionné depuis FilePicker)
      if (fileBytes != null && fileName != null) {
        formDataMap['file'] = MultipartFile.fromBytes(
          fileBytes,
          filename: fileName,
        );
      }

      final formData = FormData.fromMap(formDataMap);

      return await dio.post(
        '/api/tickets',
        data: formData, // Dio configure automatiquement le Content-Type en multipart/form-data
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 6. AFFECTER UN AGENT À UN TICKET
  /// Correspond à : POST /api/tickets/{ticketId}/affecter/{agentId}
  Future<Response> affecterAgent({required int ticketId, required int agentId}) async {
    try {
      return await dio.post('/api/tickets/$ticketId/affecter/$agentId');
    } catch (e) {
      rethrow;
    }
  }

  /// 7. SUPPRIMER UN TICKET
  /// Correspond à : DELETE /api/tickets/{id}
  Future<Response> supprimerTicket(int id) async {
    try {
      return await dio.delete('/api/tickets/$id');
    } catch (e) {
      rethrow;
    }
  }
}

// =========================================================================
// ── INTERCEPTEUR JWT DE SÉCURITÉ
// =========================================================================
class _JwtInterceptor extends Interceptor {
  final StorageService _storage;
  _JwtInterceptor(this._storage);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Récupération automatique du token depuis le stockage local
    final token = await _storage.token; 
    
    if (token != null && token.isNotEmpty) {
      // Injection du token dans l'en-tête de chaque requête sortante
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Si l'API retourne un code 401 ou 403, la session a expiré ou est invalide
    if (err.response?.statusCode == 403 || err.response?.statusCode == 401) {
      await _storage.clearSession(); // Nettoyer les données locales (déconnexion)
    }
    handler.next(err);
  }
}