import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:flutter_application_1/models/models.dart';
import 'package:flutter_application_1/services/services.dart';

// ════════════════════════════════════════════════════════════════════
// AUTH BLOC
// ════════════════════════════════════════════════════════════════════

abstract class AuthEvent extends Equatable { @override List<Object?> get props => []; }
class CheckAuth extends AuthEvent {}
class LoginSubmitted extends AuthEvent { final String e, p; LoginSubmitted(this.e, this.p); @override List<Object?> get props => [e, p]; }
class RegisterSubmitted extends AuthEvent { final Map<String, dynamic> data; RegisterSubmitted(this.data); @override List<Object?> get props => [data]; }
class LogoutRequested extends AuthEvent {}
class ForgotPwdSubmitted extends AuthEvent { final String email; ForgotPwdSubmitted(this.email); @override List<Object?> get props => [email]; }
class ResetPwdSubmitted extends AuthEvent {
  final String code, nouveauMotDePasse;
  ResetPwdSubmitted(this.code, this.nouveauMotDePasse);
  @override List<Object?> get props => [code, nouveauMotDePasse];
}

abstract class AuthState extends Equatable { @override List<Object?> get props => []; }
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthOk extends AuthState { final String userNom; final String initiales; AuthOk(this.userNom, {this.initiales = ''}); @override List<Object?> get props => [userNom, initiales]; }
class AuthOut extends AuthState {}
class AuthError extends AuthState { final String msg; AuthError(this.msg); @override List<Object?> get props => [msg]; }
class AuthForgotSent extends AuthState {}
class AuthResetOk extends AuthState {} // Mot de passe réinitialisé avec succès

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _s;
  AuthBloc(this._s) : super(AuthInitial()) {
    on<CheckAuth>((_, emit) async {
      final ok = await _s.isLoggedIn();
      if (ok) {
        final nom = await _s.currentUserNom ?? '';
        final ini = await _s.currentInitiales ?? '';
        emit(AuthOk(nom, initiales: ini));
      } else {
        emit(AuthOut());
      }
    });
    on<LoginSubmitted>((e, emit) async {
      emit(AuthLoading());
      try {
        final r = await _s.login(e.e, e.p);
        emit(AuthOk(r.utilisateur.nom, initiales: r.initiales));
      } catch (err) { emit(AuthError(err.toString())); }
    });
    on<RegisterSubmitted>((e, emit) async {
      emit(AuthLoading());
      try {
        final r = await _s.register(e.data);
        emit(AuthOk(r.utilisateur.nom, initiales: r.initiales));
      } catch (err) { emit(AuthError(err.toString())); }
    });
    on<LogoutRequested>((_, emit) async { await _s.logout(); emit(AuthOut()); });
    on<ForgotPwdSubmitted>((e, emit) async {
      emit(AuthLoading());
      try { await _s.forgotPassword(e.email); emit(AuthForgotSent()); }
      catch (err) { emit(AuthError(err.toString())); }
    });
    on<ResetPwdSubmitted>((e, emit) async {
      emit(AuthLoading());
      try {
        await _s.resetPassword(e.code, e.nouveauMotDePasse);
        emit(AuthResetOk());
      } catch (err) { emit(AuthError(err.toString())); }
    });
  }
}

// ════════════════════════════════════════════════════════════════════
// DASHBOARD BLOC (Vérifie bien que cette section existe désormais !)
// ════════════════════════════════════════════════════════════════════

abstract class DashboardEvent extends Equatable { @override List<Object?> get props => []; }
class LoadDashboard extends DashboardEvent {}

abstract class DashboardState extends Equatable { @override List<Object?> get props => []; }
class DashboardInitial extends DashboardState {}
class DashboardLoading extends DashboardState {}
class DashboardLoaded extends DashboardState {
  final DashboardStats stats;
  final List<Invitation> recentInvitations;
  final List<Ticket> recentTickets;
  DashboardLoaded({required this.stats, required this.recentInvitations, required this.recentTickets});
  @override List<Object?> get props => [stats, recentInvitations, recentTickets];
}
class DashboardError extends DashboardState {
  final String message;
  DashboardError(this.message);
  @override List<Object?> get props => [message];
}

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardService _s;
  DashboardBloc(this._s) : super(DashboardInitial()) {
    on<LoadDashboard>((_, emit) async {
      emit(DashboardLoading());
      try {
        final stats = await _s.getStats();
        List<Invitation> invitations = [];
        List<Ticket> tickets = [];

        try { invitations = await _s.getRecentInvitations(); } catch (_) {}
        try { tickets = await _s.getRecentTickets(); } catch (_) {}

        emit(DashboardLoaded(
          stats: stats,
          recentInvitations: invitations,
          recentTickets: tickets,
        ));
      } catch (err) {
        emit(DashboardError(err.toString()));
      }
    });
  }
}

// ════════════════════════════════════════════════════════════════════
// INVITATION BLOC
// ════════════════════════════════════════════════════════════════════

abstract class InvitationEvent extends Equatable { @override List<Object?> get props => []; }
class LoadInvitations extends InvitationEvent { final int page; final String? search; final InvitationStatus? status; LoadInvitations({this.page=0, this.search, this.status}); @override List<Object?> get props => [page, search, status]; }
class LoadInvDetail extends InvitationEvent { final String id; LoadInvDetail(this.id); @override List<Object?> get props => [id]; }
class CreateInvitation extends InvitationEvent {
  final Map<String, dynamic> data;
  final List<String> filePaths;
  final List<MapEntry<String, Uint8List>> fileBytes;
  CreateInvitation(this.data, {this.filePaths = const [], this.fileBytes = const []});
  @override List<Object?> get props => [data, filePaths, fileBytes];
}
class UpdateInvitation extends InvitationEvent { final String id; final Map<String, dynamic> data; UpdateInvitation(this.id, this.data); @override List<Object?> get props => [id, data]; }
class DeleteInvitation extends InvitationEvent { final String id; DeleteInvitation(this.id); @override List<Object?> get props => [id]; }
class AffecterAgentInv extends InvitationEvent { final String invId, agentId; final bool responsable; AffecterAgentInv(this.invId, this.agentId, {this.responsable=false}); @override List<Object?> get props => [invId, agentId, responsable]; }

/// Affecte plusieurs agents à une invitation en un seul appel.
/// Le backend gère affectations + notifications automatiquement.
class AssignerAgentsInvitation extends InvitationEvent {
  final String invId;
  final List<String> agentIds;
  final String? responsableId;
  AssignerAgentsInvitation({
    required this.invId,
    required this.agentIds,
    this.responsableId,
  });
  @override List<Object?> get props => [invId, agentIds, responsableId];
}

abstract class InvitationState extends Equatable { @override List<Object?> get props => []; }
class InvitationInitial extends InvitationState {}
class InvitationLoading extends InvitationState {}
class InvitationsLoaded extends InvitationState { final InvitationPage page; InvitationsLoaded(this.page); @override List<Object?> get props => [page]; }
class InvDetailLoaded extends InvitationState { final Invitation inv; InvDetailLoaded(this.inv); @override List<Object?> get props => [inv]; }
class InvitationSuccess extends InvitationState { final String msg; InvitationSuccess(this.msg); @override List<Object?> get props => [msg]; }
class InvitationError extends InvitationState { final String msg; InvitationError(this.msg); @override List<Object?> get props => [msg]; }

class InvitationBloc extends Bloc<InvitationEvent, InvitationState> {
  final InvitationService _s;
  InvitationBloc(this._s) : super(InvitationInitial()) {
    on<LoadInvitations>((e, emit) async { emit(InvitationLoading()); try { emit(InvitationsLoaded(await _s.getAll(page: e.page, search: e.search, status: e.status))); } catch (err) { emit(InvitationError(err.toString())); } });
    on<LoadInvDetail>((e, emit) async { emit(InvitationLoading()); try { emit(InvDetailLoaded(await _s.getById(e.id))); } catch (err) { emit(InvitationError(err.toString())); } });
    on<CreateInvitation>((e, emit) async {
      emit(InvitationLoading());
      try {
        await _s.create(e.data, fileBytes: e.fileBytes);
        emit(InvitationSuccess('Invitation créée'));
      } catch (err) { emit(InvitationError(err.toString())); }
    });
    on<UpdateInvitation>((e, emit) async { emit(InvitationLoading()); try { await _s.update(e.id, e.data); emit(InvitationSuccess('Invitation mise à jour')); } catch (err) { emit(InvitationError(err.toString())); } });
    on<DeleteInvitation>((e, emit) async { emit(InvitationLoading()); try { await _s.delete(e.id); emit(InvitationSuccess('Invitation supprimée')); } catch (err) { emit(InvitationError(err.toString())); } });
    // Conservé pour compatibilité ascendante (affectation ticket)
    on<AffecterAgentInv>((e, emit) async { emit(InvitationLoading()); try { emit(InvDetailLoaded(await _s.getById(e.invId))); } catch (err) { emit(InvitationError(err.toString())); } });

    on<AssignerAgentsInvitation>((e, emit) async {
      emit(InvitationLoading());
      try {
        // Un seul appel POST — le backend affecte ET notifie
        final inv = await _s.affecterAgents(
          e.invId,
          e.agentIds,
          responsableId: e.responsableId,
        );
        emit(InvDetailLoaded(inv));
      } catch (err) { emit(InvitationError(err.toString())); }
    });
  }
}

// ════════════════════════════════════════════════════════════════════
// TICKET BLOC
// ════════════════════════════════════════════════════════════════════

abstract class TicketEvent extends Equatable { @override List<Object?> get props => []; }

class LoadTickets extends TicketEvent { 
  final int page; 
  final String? search; 
  final TicketStatus? status; 
  final TicketPriority? priority; 
  LoadTickets({this.page=0, this.search, this.status, this.priority}); 
  @override List<Object?> get props => [page, search, status, priority]; 
}

class LoadTicketDetail extends TicketEvent { 
  final String id; 
  LoadTicketDetail(this.id); 
  @override List<Object?> get props => [id]; 
}

class CreateTicket extends TicketEvent {
  final String description;
  final String structure;
  final TicketPriority priority;
  final Uint8List? attachmentBytes;
  final String? attachmentName;
 
  CreateTicket({required this.description, required this.structure, required this.priority, this.attachmentBytes, this.attachmentName});
  @override List<Object?> get props => [description, structure, priority, attachmentBytes, attachmentName];
}

class UpdateStatut extends TicketEvent { 
  final String id; 
  final TicketStatus statut; 
  final String? solution; 
  UpdateStatut(this.id, this.statut, {this.solution}); 
  @override List<Object?> get props => [id, statut, solution]; 
}

class AffecterAgentTkt extends TicketEvent { 
  final String ticketId, agentId; 
  AffecterAgentTkt(this.ticketId, this.agentId); 
  @override List<Object?> get props => [ticketId, agentId]; 
}

class EnvoyerMessage extends TicketEvent { 
  final String ticketId, message; 
  EnvoyerMessage(this.ticketId, this.message); 
  @override List<Object?> get props => [ticketId, message]; 
}

// ════════════════════════════════════════════════════════════════════
// TICKET STATES
// ════════════════════════════════════════════════════════════════════
abstract class TicketState extends Equatable { @override List<Object?> get props => []; }
class TicketInitial extends TicketState {}
class TicketLoading extends TicketState {}
class TicketsLoaded extends TicketState { final TicketPage page; TicketsLoaded(this.page); @override List<Object?> get props => [page]; }
class TicketDetailL extends TicketState { final Ticket ticket; TicketDetailL(this.ticket); @override List<Object?> get props => [ticket]; }
class TicketSuccess extends TicketState { final String msg; TicketSuccess(this.msg); @override List<Object?> get props => [msg]; }
class TicketError extends TicketState { final String msg; TicketError(this.msg); @override List<Object?> get props => [msg]; }

// ════════════════════════════════════════════════════════════════════
// TICKET BLOC MODIFIÉ
// ════════════════════════════════════════════════════════════════════
class TicketBloc extends Bloc<TicketEvent, TicketState> {
  final TicketService _s;
  String? _uid; // mutable — mis à jour après login

  TicketBloc(this._s, {String? currentUserId})
      : _uid = currentUserId,
        super(TicketInitial()) {

    on<LoadTickets>((e, emit) async {
      emit(TicketLoading());
      try {
        emit(TicketsLoaded(await _s.getAll(
            page: e.page, search: e.search, status: e.status,
            priority: e.priority, currentUserId: _uid)));
      } catch (err) { emit(TicketError(err.toString())); }
    });

    on<LoadTicketDetail>((e, emit) async {
      emit(TicketLoading());
      try {
        emit(TicketDetailL(await _s.getById(e.id, currentUserId: _uid)));
      } catch (err) { emit(TicketError(err.toString())); }
    });

    on<CreateTicket>((e, emit) async {
      emit(TicketLoading());
      try {
        final Map<String, dynamic> ticketData = {
          'description': e.description,
          'structure': e.structure,
          'priority': e.priority.apiValue,
          'attachmentName': e.attachmentName,
          if (_uid != null) 'createurId': int.tryParse(_uid!),
        };
        await _s.create(ticketData, fileBytes: e.attachmentBytes);
        emit(TicketSuccess('Ticket créé'));
      } catch (err) { emit(TicketError(err.toString())); }
    });

    on<UpdateStatut>((e, emit) async {
      emit(TicketLoading());
      try {
        emit(TicketDetailL(await _s.updateStatut(e.id, e.statut,
            solution: e.solution, currentUserId: _uid)));
      } catch (err) { emit(TicketError(err.toString())); }
    });

    on<AffecterAgentTkt>((e, emit) async {
      emit(TicketLoading());
      try {
        emit(TicketDetailL(await _s.affecterAgent(e.ticketId, e.agentId,
            currentUserId: _uid)));
      } catch (err) { emit(TicketError(err.toString())); }
    });

    // Pas de emit(TicketLoading()) ici pour ne pas faire disparaître la liste
    // de messages pendant l'envoi
    on<EnvoyerMessage>((e, emit) async {
      try {
        final updatedTicket = await _s.envoyerMessage(e.ticketId, e.message,
            currentUserId: _uid);
        emit(TicketDetailL(updatedTicket));
      } catch (err) { emit(TicketError(err.toString())); }
    });
  }

  /// Appelé depuis _AppRouter quand l'état AuthOk est reçu.
  /// Met à jour l'userId sans recréer le Bloc.
  void updateUserId(String? userId) {
    _uid = userId;
  }
}
// ════════════════════════════════════════════════════════════════════
// NOTIFICATION BLOC
// ════════════════════════════════════════════════════════════════════

abstract class NotifEvent extends Equatable { @override List<Object?> get props => []; }
class LoadNotifs extends NotifEvent {}
class MarkRead extends NotifEvent { final String id; MarkRead(this.id); @override List<Object?> get props => [id]; }
class MarkAllRead extends NotifEvent {}

abstract class NotifState extends Equatable { @override List<Object?> get props => []; }
class NotifInitial extends NotifState {}
class NotifLoading extends NotifState {}
class NotifsLoaded extends NotifState {
  final List<NotificationModel> list;
  NotifsLoaded(this.list);
  @override List<Object?> get props => [list];
}
class NotifError extends NotifState { final String msg; NotifError(this.msg); @override List<Object?> get props => [msg]; }

class NotifBloc extends Bloc<NotifEvent, NotifState> {
  final NotificationService _s;
  NotifBloc(this._s) : super(NotifInitial()) {
    on<LoadNotifs>((_, emit) async { emit(NotifLoading()); try { emit(NotifsLoaded(await _s.getAll())); } catch (err) { emit(NotifError(err.toString())); } });
    on<MarkRead>((e, emit) async { try { await _s.markAsRead(e.id); add(LoadNotifs()); } catch (_) {} });
    on<MarkAllRead>((_, emit) async { try { await _s.markAllAsRead(); add(LoadNotifs()); } catch (_) {} });
  }
}

// ════════════════════════════════════════════════════════════════════
// ADMIN BLOC
// ════════════════════════════════════════════════════════════════════

abstract class AdminEvent extends Equatable { @override List<Object?> get props => []; }
class LoadUsers extends AdminEvent {}
class CreateUser extends AdminEvent { final Map<String, dynamic> data; CreateUser(this.data); @override List<Object?> get props => [data]; }
class UpdateUser extends AdminEvent { final String id; final Map<String, dynamic> data; UpdateUser(this.id, this.data); @override List<Object?> get props => [id, data]; }
class ToggleUser extends AdminEvent { final String id; ToggleUser(this.id); @override List<Object?> get props => [id]; }
class LoadSettings extends AdminEvent {}
class SaveSettings extends AdminEvent { final Map<String, dynamic> data; SaveSettings(this.data); @override List<Object?> get props => [data]; }

abstract class AdminState extends Equatable { @override List<Object?> get props => []; }
class AdminInitial extends AdminState {}
class AdminLoading extends AdminState {}
class UsersLoaded extends AdminState { final List<AppUser> users; UsersLoaded(this.users); @override List<Object?> get props => [users]; }
class SettingsLoaded extends AdminState { final Map<String, dynamic> settings; SettingsLoaded(this.settings); @override List<Object?> get props => [settings]; }
class AdminSuccess extends AdminState { final String msg; AdminSuccess(this.msg); @override List<Object?> get props => [msg]; }
class AdminError extends AdminState { final String msg; AdminError(this.msg); @override List<Object?> get props => [msg]; }

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final AdminService _s;
  AdminBloc(this._s) : super(AdminInitial()) {
    on<LoadUsers>((_, emit) async { emit(AdminLoading()); try { emit(UsersLoaded(await _s.getUsers())); } catch (err) { emit(AdminError(err.toString())); } });
    on<CreateUser>((e, emit) async { emit(AdminLoading()); try { await _s.createUser(e.data); emit(AdminSuccess('Utilisateur créé')); add(LoadUsers()); } catch (err) { emit(AdminError(err.toString())); } });
    on<UpdateUser>((e, emit) async { emit(AdminLoading()); try { await _s.updateUser(e.id, e.data); emit(AdminSuccess('Utilisateur mis à jour')); add(LoadUsers()); } catch (err) { emit(AdminError(err.toString())); } });
    on<ToggleUser>((e, emit) async { try { await _s.toggleUser(e.id); add(LoadUsers()); } catch (err) { emit(AdminError(err.toString())); } });
    on<LoadSettings>((_, emit) async { emit(AdminLoading()); try { emit(SettingsLoaded(await _s.getSettings())); } catch (err) { emit(AdminError(err.toString())); } });
    on<SaveSettings>((e, emit) async { emit(AdminLoading()); try { await _s.saveSettings(e.data); emit(AdminSuccess('Paramètres sauvegardés')); } catch (err) { emit(AdminError(err.toString())); } });
  }
}