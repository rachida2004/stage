import 'dart:convert';

// ════════════════════════════════════════════════════════════════════
// INVITATION MODELE
// ════════════════════════════════════════════════════════════════════

enum InvitationStatus { enAttente, planifiee, enCours, terminee, nonTraitee }

extension InvitationStatusExt on InvitationStatus {
  String get label {
    switch (this) {
      case InvitationStatus.enAttente:  return 'En attente';
      case InvitationStatus.planifiee:  return 'Planifiée';
      case InvitationStatus.enCours:    return 'En cours';
      case InvitationStatus.terminee:   return 'Terminée';
      case InvitationStatus.nonTraitee: return 'Non traitée';
    }
  }

  // Valeur envoyée à PostgreSQL (via les enums Java @Enumerated(EnumType.STRING))
  String get apiValue {
    switch (this) {
      case InvitationStatus.enAttente:  return 'EN_ATTENTE';
      case InvitationStatus.planifiee:  return 'PLANIFIEE';
      case InvitationStatus.enCours:    return 'EN_COURS';
      case InvitationStatus.terminee:   return 'TERMINEE';
      case InvitationStatus.nonTraitee: return 'NON_TRAITEE';
    }
  }

  static InvitationStatus fromApi(String? v) {
    switch (v) {
      case 'PLANIFIEE':   return InvitationStatus.planifiee;
      case 'EN_COURS':    return InvitationStatus.enCours;
      case 'TERMINEE':    return InvitationStatus.terminee;
      case 'NON_TRAITEE': return InvitationStatus.nonTraitee;
      default:            return InvitationStatus.enAttente;
    }
  }
}

class Invitation {
  final String id; // Gère les formats numériques ou UUID de PostgreSQL
  final String objet;
  final String structureEmettrice;
  final DateTime dateDebut;
  final DateTime dateFin;
  final int nombreParticipants;
  final String? lieu;
  final String? description;
  final InvitationStatus status;
  final List<AppUser> agentsAffectes;
  final List<String> files; 

  Invitation({
    required this.id,
    required this.objet,
    required this.structureEmettrice,
    required this.dateDebut,
    required this.dateFin,
    this.nombreParticipants = 0,
    this.lieu,
    this.description,
    required this.status,
    this.agentsAffectes = const [],
    this.files = const [],
  });

  factory Invitation.fromJson(Map<String, dynamic> j) => Invitation(
    id:                 j['id']?.toString() ?? '',
    objet:              j['objet'] ?? '',
    structureEmettrice: j['structureEmettrice'] ?? '',
    // ✅ CORRECTION : Sécurisation du parsing des dates pour éviter un crash si le format change
    dateDebut:          j['dateDebut'] != null ? (DateTime.tryParse(j['dateDebut'].toString()) ?? DateTime.now()) : DateTime.now(),
    dateFin:            j['dateFin'] != null ? (DateTime.tryParse(j['dateFin'].toString()) ?? DateTime.now()) : DateTime.now(),
    nombreParticipants: j['nombreParticipants'] ?? 0,
    lieu:               j['lieu'],
    description:        j['description'],
    status:             InvitationStatusExt.fromApi(j['status']),
    agentsAffectes: (j['agentsAffectes'] as List<dynamic>? ?? [])
        .map((e) => AppUser.fromJson(e)).toList(),
    // ✅ CORRECTION CRITIQUE : Extrait l'URL de l'objet pièce jointe (Map) au lieu de faire un .toString() brut
    files: (j['files'] as List<dynamic>? ?? j['piecesJointes'] as List<dynamic>? ?? [])
        .map((e) {
          if (e is Map) {
            return e['url']?.toString() ?? '';
          }
          return e.toString();
        })
        .where((url) => url.isNotEmpty)
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'objet': objet,
    'structureEmettrice': structureEmettrice,
    'dateDebut': '${dateDebut.year}-${dateDebut.month.toString().padLeft(2,'0')}-${dateDebut.day.toString().padLeft(2,'0')}',
    'dateFin':   '${dateFin.year}-${dateFin.month.toString().padLeft(2,'0')}-${dateFin.day.toString().padLeft(2,'0')}',
    'nombreParticipants': nombreParticipants,
    if (lieu != null) 'lieu': lieu,
    if (description != null) 'description': description,
    'status': status.apiValue,
    'files': files,
  };
}

class InvitationPage {
  final List<Invitation> items;
  final int totalElements;
  final int totalPages;
  final int currentPage;

  InvitationPage({
    required this.items,
    this.totalElements = 0,
    this.totalPages = 1,
    this.currentPage = 0,
  });

  factory InvitationPage.fromJson(dynamic json) {
    if (json is List) {
      final items = json.map((e) => Invitation.fromJson(e)).toList();
      return InvitationPage(items: items, totalElements: items.length);
    }
    final list = (json['content'] as List<dynamic>? ?? json as List<dynamic>? ?? [])
        .map((e) => Invitation.fromJson(e)).toList();
    return InvitationPage(
      items: list,
      totalElements: json['totalElements'] ?? list.length,
      totalPages: json['totalPages'] ?? 1,
      currentPage: json['number'] ?? 0,
    );
  }
}
// ════════════════════════════════════════════════════════════════════
// TICKET MODELE
// ════════════════════════════════════════════════════════════════════

enum TicketStatus   { enAttente, enCours, enPause, resolu, ferme }
enum TicketPriority { haute, normale, basse }

extension TicketStatusExt on TicketStatus {
  String get label {
    switch (this) {
      case TicketStatus.enAttente: return 'En attente';
      case TicketStatus.enCours:   return 'En cours';
      case TicketStatus.enPause:   return 'En pause';
      case TicketStatus.resolu:    return 'Résolu';
      case TicketStatus.ferme:     return 'Fermé';
    }
  }

  String get apiValue {
    switch (this) {
      case TicketStatus.enAttente: return 'EN_ATTENTE';
      case TicketStatus.enCours:   return 'EN_COURS';
      case TicketStatus.enPause:   return 'EN_PAUSE';
      case TicketStatus.resolu:    return 'RESOLU';
      case TicketStatus.ferme:     return 'FERME';
    }
  }

  static TicketStatus fromApi(String? v) {
    switch (v) {
      case 'EN_COURS':   return TicketStatus.enCours;
      case 'EN_PAUSE':   return TicketStatus.enPause;
      case 'RESOLU':     return TicketStatus.resolu;
      case 'FERME':      return TicketStatus.ferme;
      default:           return TicketStatus.enAttente;
    }
  }
}

extension TicketPriorityExt on TicketPriority {
  String get label {
    switch (this) {
      case TicketPriority.haute:   return 'Haute';
      case TicketPriority.normale: return 'Normale';
      case TicketPriority.basse:   return 'Basse';
    }
  }

  String get apiValue {
    switch (this) {
      case TicketPriority.haute:   return 'HAUTE';
      case TicketPriority.normale: return 'NORMALE';
      case TicketPriority.basse:   return 'BASSE';
    }
  }

  static TicketPriority fromApi(String? v) {
    switch (v) {
      case 'HAUTE': return TicketPriority.haute;
      case 'BASSE': return TicketPriority.basse;
      default:      return TicketPriority.normale;
    }
  }
}

class TicketMessage {
  final String auteur;
  final String initiales;
  final String message;
  final DateTime date;
  final bool isSelf;

  const TicketMessage({
    required this.auteur,
    required this.initiales,
    required this.message,
    required this.date,
    this.isSelf = false,
  });

  factory TicketMessage.fromJson(Map<String, dynamic> j, {String? currentUserId}) {
    final String auteurId = j['auteurId']?.toString() ?? '';
    return TicketMessage(
      auteur:    j['auteurNom'] ?? '',
      initiales: j['auteurInitiales'] ?? '',
      message:   j['message'] ?? '',
      date: j['createdAt'] != null ? DateTime.parse(j['createdAt']) : DateTime.now(),
      isSelf: currentUserId != null && auteurId == currentUserId,
    );
  }
}

class Ticket {
  final String id;
  final String description;
  final String structure;
  final TicketStatus status;
  final TicketPriority priority;
  final DateTime createdAt;
  final AppUser? agentAssigne;
  final AppUser? createur;
  final String? attachmentUrl; 
  final List<TicketMessage> messages;

  Ticket({
    required this.id,
    required this.description,
    required this.structure,
    required this.status,
    required this.priority,
    required this.createdAt,
    this.agentAssigne,
    this.createur,
    this.attachmentUrl, 
    this.messages = const [],
  });

  // 🛠️ AJOUT PASSERELLE : Crée un alias automatique pour éviter les erreurs de compilation 
  // si le code de ton UI appelle "communications" au lieu de "messages"
  List<TicketMessage> get communications => messages;

  String? get agentAssigneNom => agentAssigne != null
      ? '${agentAssigne!.nom} ${agentAssigne!.prenom ?? ''}'.trim()
      : null;

  factory Ticket.fromJson(Map<String, dynamic> j, {String? currentUserId}) => Ticket(
    id:          j['id']?.toString() ?? '',
    description: j['description'] ?? '',
    structure:   j['structure'] ?? '',
    status:      TicketStatusExt.fromApi(j['status']),
    priority:    TicketPriorityExt.fromApi(j['priority']),
    createdAt: j['createdAt'] != null ? DateTime.parse(j['createdAt']) : DateTime.now(),
    agentAssigne: j['agentAssigne'] != null ? AppUser.fromJson(j['agentAssigne']) : null,
    createur:     j['createur'] != null ? AppUser.fromJson(j['createur']) : null,
    attachmentUrl: j['attachmentUrl'] ?? j['pieceJointeUrl'], 
    messages: (j['messages'] as List<dynamic>? ?? j['communications'] as List<dynamic>? ?? [])
        .map((m) => TicketMessage.fromJson(m, currentUserId: currentUserId)).toList(),
  );

  Map<String, dynamic> toJson() => {
    'description': description,
    'structure':   structure,
    'status':      status.apiValue,
    'priority':    priority.apiValue,
    if (agentAssigne != null) 'agentId': agentAssigne!.id,
    if (createur != null) 'createurId': createur!.id,
    if (attachmentUrl != null) 'attachmentUrl': attachmentUrl, 
  };
}

class TicketPage {
  final List<Ticket> items;
  final int totalElements;
  final int totalPages;
  final int currentPage;

  TicketPage({required this.items, this.totalElements = 0, this.totalPages = 1, this.currentPage = 0});

  factory TicketPage.fromJson(dynamic json, {String? currentUserId}) {
    if (json is List) {
      final items = json.map((e) => Ticket.fromJson(e, currentUserId: currentUserId)).toList();
      return TicketPage(items: items, totalElements: items.length);
    }
    final list = (json['content'] as List<dynamic>? ?? json as List<dynamic>? ?? [])
        .map((e) => Ticket.fromJson(e, currentUserId: currentUserId)).toList();
    return TicketPage(
      items: list,
      totalElements: json['totalElements'] ?? list.length,
      totalPages: json['totalPages'] ?? 1,
      currentPage: json['number'] ?? 0,
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// USER MODELE
// ════════════════════════════════════════════════════════════════════

enum UserRole { admin, agent, superviseur, usager }

extension UserRoleExt on UserRole {
  String get label {
    switch (this) {
      case UserRole.admin:       return 'Administrateur';
      case UserRole.agent:       return 'Agent DSI';
      case UserRole.superviseur: return 'Superviseur';
      case UserRole.usager:      return 'Usager';
    }
  }

  static UserRole fromApi(String? v) {
    switch (v) {
      case 'ADMIN':       return UserRole.admin;
      case 'AGENT_DSI':   return UserRole.agent;
      case 'SUPERVISEUR': return UserRole.superviseur;
      default:            return UserRole.usager;
    }
  }
}

class AppUser {
  final String id; // Tolère les formats numériques convertis proprement en String
  final String nom;
  final String? prenom;
  final String email;
  final UserRole role;
  final String initiales;
  final bool active;
  final String? structure;
  final String? service;

  bool get isActive => active;
  bool get estUnIntervenant => role == UserRole.agent || role == UserRole.admin;

  const AppUser({
    required this.id,
    required this.nom,
    this.prenom,
    required this.email,
    required this.role,
    required this.initiales,
    this.active = true,
    this.structure,
    this.service,
  });

  factory AppUser.fromJson(Map<String, dynamic> j) {
    // ✅ CORRECTION : On force le passage en majuscules pour éviter les ratés de casse
    final roleStr = j['role']?.toString().toUpperCase() ?? '';
    
    return AppUser(
      // ✅ CORRECTION : Gère le passage d'un ID entier numérique (ex: 3) vers un String attendu par l'UI
      id: j['id']?.toString() ?? j['userId']?.toString() ?? '',
      nom: j['nom'] ?? '',
      prenom: j['prenom'],
      email: j['email'] ?? '',
      role: UserRoleExt.fromApi(roleStr),
      initiales: j['initiales'] ?? _computeInitiales(j['nom'], j['prenom']),
      // Tolère 'actif' (venant de la table PG) ou 'active'
      active: j['actif'] ?? j['active'] ?? j['isActive'] ?? true, 
      structure: j['structure'],
      service: j['service'],
    );
  }

  static String _computeInitiales(String? nom, String? prenom) {
    final n = (nom?.isNotEmpty == true) ? nom![0].toUpperCase() : '';
    final p = (prenom?.isNotEmpty == true) ? prenom![0].toUpperCase() : '';
    return '$n$p';
  }
}
// ════════════════════════════════════════════════════════════════════
// AUTH RESPONSE & DASHBOARD & NOTIF
// ════════════════════════════════════════════════════════════════════

class AuthResponse {
  final String token;
  final String type;
  final String userId;
  final String nom;
  final String prenom;
  final String email;
  final String role;
  final String initiales;

  AppUser get utilisateur => AppUser(
    id: userId,
    nom: nom,
    prenom: prenom,
    email: email,
    role: UserRoleExt.fromApi(role),
    initiales: initiales,
  );

  String get accessToken => token;
  String get refreshToken => token;

  AuthResponse({
    required this.token,
    this.type = 'Bearer',
    required this.userId,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.role,
    required this.initiales,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> j) => AuthResponse(
    token:     j['token'] ?? '',
    type:      j['type'] ?? 'Bearer',
    userId:    j['id']?.toString() ?? '',
    nom:       j['nom'] ?? '',
    prenom:    j['prenom'] ?? '',
    email:     j['email'] ?? '',
    role:      j['role'] ?? 'USAGER',
    initiales: j['initiales'] ?? '',
  );
}

class DashboardStats {
  final int totalInvitations;
  final int invitationsEnAttente;
  final int invitationsPlanifiees;
  final int invitationsEnCours;
  final int invitationsTerminees;
  final int invitationsNonTraitees;
  final int totalTickets;
  final int ticketsOuverts;
  final int totalUsers;

  DashboardStats({
    this.totalInvitations = 0,
    this.invitationsEnAttente = 0,
    this.invitationsPlanifiees = 0,
    this.invitationsEnCours = 0,
    this.invitationsTerminees = 0,
    this.invitationsNonTraitees = 0,
    this.totalTickets = 0,
    this.ticketsOuverts = 0,
    this.totalUsers = 0,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> j) => DashboardStats(
    totalInvitations:       j['totalInvitations']      ?? 0,
    invitationsEnAttente:   j['invitationsEnAttente']  ?? 0,
    invitationsPlanifiees:  j['invitationsPlanifiees'] ?? 0,
    invitationsEnCours:     j['invitationsEnCours']    ?? 0,
    invitationsTerminees:   j['invitationsTerminees']  ?? 0,
    invitationsNonTraitees: j['invitationsNonTraitees'] ?? 0,
    totalTickets:           j['totalTickets']          ?? 0,
    ticketsOuverts:         j['ticketsOuverts']        ?? 0,
    totalUsers:             j['totalUsers']            ?? 0,
  );
}

enum NotifCategory { invitation, ticket, admin, dashboard }

extension NotifCategoryExt on NotifCategory {
  static NotifCategory fromApi(String? v) {
    switch (v) {
      case 'TICKET':    return NotifCategory.ticket;
      case 'ADMIN':     return NotifCategory.admin;
      case 'DASHBOARD': return NotifCategory.dashboard;
      default:          return NotifCategory.invitation;
    }
  }
}

class NotificationModel {
  final String id;
  final String message;
  final NotifCategory category;
  final DateTime date;
  final bool isRead;
  final String? actionLabel;
  final String? relatedResourceId; 

  const NotificationModel({
    required this.id,
    required this.message,
    required this.category,
    required this.date,
    this.isRead = false,
    this.actionLabel,
    this.relatedResourceId, 
  });

  factory NotificationModel.fromJson(Map<String, dynamic> j) => NotificationModel(
    id:          j['id']?.toString() ?? '',
    message:     j['message'] ?? '',
    category:    NotifCategoryExt.fromApi(j['category']),
    date: j['createdAt'] != null ? DateTime.parse(j['createdAt']) : DateTime.now(),
    isRead:      j['read'] ?? j['isRead'] ?? false, 
    actionLabel: j['actionLabel'],
    relatedResourceId: j['relatedResourceId']?.toString() ?? j['targetId']?.toString(), 
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'message': message,
    'category': category.toString().split('.').last.toUpperCase(), 
    'createdAt': date.toIso8601String(),
    'read': isRead,
    if (actionLabel != null) 'actionLabel': actionLabel,
    if (relatedResourceId != null) 'relatedResourceId': relatedResourceId,
  };
}

// ════════════════════════════════════════════════════════════════════
// SAMPLE DATA / FALLBACK 
// ════════════════════════════════════════════════════════════════════

class SampleData {
  static List<Invitation> invitations = [
    Invitation(id: 'INV-01', objet: 'Forum sur l\'IA — Dakar', structureEmettrice: 'ANSI', dateDebut: DateTime(2026, 5, 12), dateFin: DateTime(2026, 5, 14), nombreParticipants: 2, status: InvitationStatus.planifiee, files: ['Communique_Officiel.pdf', 'Programme_Dakar.docx']),
    Invitation(id: 'INV-02', objet: 'Séminaire cyber-sécurité', structureEmettrice: 'CERT-BF', dateDebut: DateTime(2026, 5, 20), dateFin: DateTime(2026, 5, 20), status: InvitationStatus.enAttente, files: ['Note_Cadrage_Cyber.pdf']),
    Invitation(id: 'INV-03', objet: 'Atelier open data', structureEmettrice: 'MATD', dateDebut: DateTime(2026, 6, 1), dateFin: DateTime(2026, 6, 2), status: InvitationStatus.enAttente, files: []),
    Invitation(id: 'INV-04', objet: 'Conférence e-gouvernance', structureEmettrice: 'MATD', dateDebut: DateTime(2026, 4, 28), dateFin: DateTime(2026, 4, 28), nombreParticipants: 3, status: InvitationStatus.terminee, files: []),
    Invitation(id: 'INV-05', objet: 'Rencontre DSI régionaux', structureEmettrice: 'Interne', dateDebut: DateTime(2026, 5, 1), dateFin: DateTime(2026, 5, 3), nombreParticipants: 1, status: InvitationStatus.enCours, files: []),
    Invitation(id: 'INV-06', objet: 'Journée numérique BF', structureEmettrice: 'ARCEP', dateDebut: DateTime(2026, 3, 15), dateFin: DateTime(2026, 3, 15), status: InvitationStatus.nonTraitee, files: []),
  ];

  static List<Ticket> tickets = [
    Ticket(id: '034', description: 'Imprimante hors service — Bureau 12', structure: 'DSI', status: TicketStatus.enCours, priority: TicketPriority.haute, createdAt: DateTime(2026, 5, 4), attachmentUrl: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
      messages: [
        TicketMessage(auteur: 'S. Traoré', initiales: 'ST', message: 'J\'ai vérifié. Le problème vient du driver.', date: DateTime(2026, 5, 5, 10, 30)),
        TicketMessage(auteur: 'Koné Oumar', initiales: 'KO', message: 'Merci. Tenez-moi informé.', date: DateTime(2026, 5, 5, 11, 0), isSelf: true),
      ],
    ),
    Ticket(id: '033', description: 'Accès VPN bloqué', structure: 'Finances', status: TicketStatus.enAttente, priority: TicketPriority.haute, createdAt: DateTime(2026, 5, 3)),
    Ticket(id: '031', description: 'Mise à jour antivirus', structure: 'RH', status: TicketStatus.enCours, priority: TicketPriority.normale, createdAt: DateTime(2026, 5, 2)),
    Ticket(id: '028', description: 'Écran PC — direction', structure: 'Direction', status: TicketStatus.enPause, priority: TicketPriority.normale, createdAt: DateTime(2026, 4, 30)),
    Ticket(id: '025', description: 'Installation logiciel comptable', structure: 'Finances', status: TicketStatus.resolu, priority: TicketPriority.basse, createdAt: DateTime(2026, 4, 28)),
  ];

  static List<AppUser> users = [
    const AppUser(id: 'u1', nom: 'Administrateur Système', email: 'admin@dsi.gov', role: UserRole.admin, initiales: 'AD'),
    const AppUser(id: 'u2', nom: 'Sali', prenom: 'Traoré', email: 's.traore@dsi.gov', role: UserRole.agent, initiales: 'ST'),
    const AppUser(id: 'u3', nom: 'Mamadou', prenom: 'Kaboré', email: 'm.kabore@dsi.gov', role: UserRole.agent, initiales: 'MK'),
    const AppUser(id: 'u4', nom: 'Fatou', prenom: 'Ouédraogo', email: 'f.ouedraogo@gov.bf', role: UserRole.usager, initiales: 'FO'),
  ];

  static List<NotificationModel> notifications = [
    NotificationModel(id: 'n1', message: 'Vous avez été affecté à l\'invitation Forum IA — Dakar.', category: NotifCategory.invitation, date: DateTime(2026, 5, 5, 9, 37), actionLabel: 'Voir', relatedResourceId: 'INV-01'),
    NotificationModel(id: 'n2', message: 'Le ticket #034 a été mis à jour par S. Traoré.', category: NotifCategory.ticket, date: DateTime(2026, 5, 5, 9, 0), actionLabel: 'Voir', relatedResourceId: '034'),
    NotificationModel(id: 'n3', message: 'Nouvelle invitation reçue : Atelier open data — MATD.', category: NotifCategory.invitation, date: DateTime(2026, 5, 5, 7, 0), actionLabel: 'Affecter', relatedResourceId: 'INV-03'),
    NotificationModel(id: 'n4', message: 'Le ticket #033 est sans agent depuis 2 jours.', category: NotifCategory.ticket, date: DateTime(2026, 5, 4, 14, 22), actionLabel: 'Affecter', relatedResourceId: '033'),
    NotificationModel(id: 'n5', message: 'Rapport mensuel d\'avril disponible : 87% de taux de traitement.', category: NotifCategory.dashboard, date: DateTime(2026, 5, 4, 9, 0), actionLabel: 'Ouvrir'),
    NotificationModel(id: 'n6', message: 'L\'invitation Conférence e-gouvernance est maintenant Terminée.', category: NotifCategory.invitation, date: DateTime(2026, 4, 30), isRead: true, relatedResourceId: 'INV-04'),
    NotificationModel(id: 'n7', message: 'Nouvel utilisateur créé : Fatou Ouédraogo (usager).', category: NotifCategory.admin, date: DateTime(2026, 4, 28), isRead: true),
  ];
}