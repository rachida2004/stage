import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import '../bloc/all_blocs.dart';
import '../theme/app_theme.dart';
import '../models/models.dart'; 
import 'dashboard_screen.dart';
import 'invitations_screen.dart';
import 'tickets_screen.dart';
import 'notifications_screen.dart';
import 'solution_screen.dart';
import 'admin_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  Timer? _notifPollingTimer;

  // 🎯 Onglet 0 (Tableau de bord) toujours visité au départ. Les autres
  // écrans (Invitations, Tickets, Alertes, Admin) ne sont construits — et
  // ne déclenchent donc leurs appels API — qu'à la première visite réelle.
  // Avant ce correctif, l'IndexedStack construisait les 5 écrans d'un coup
  // dès la connexion, donc un USAGER/AGENT déclenchait silencieusement des
  // appels en arrière-plan (parfois refusés, 403) sans même avoir cliqué
  // sur l'onglet concerné.
  final Set<int> _ongletsVisites = {0};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotifBloc>().add(LoadNotifs());
    });

    // 🎯 Rafraîchissement automatique du badge de notifications (toutes les 30s),
    // pour refléter sans action manuelle les nouveaux tickets/invitations enregistrées.
    _notifPollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) context.read<NotifBloc>().add(LoadNotifs());
    });
  }

  @override
  void dispose() {
    _notifPollingTimer?.cancel();
    super.dispose();
  }

  // 🎯 Avant ce correctif, l'IndexedStack gardait chaque écran d'onglet en
  // mémoire (BON pour les perfs) mais ne le rechargeait JAMAIS après sa
  // toute première construction : en revenant sur "Tickets" après avoir
  // consulté un autre onglet, la liste restait figée avec d'anciennes
  // données tant qu'on ne faisait pas un rafraîchissement manuel (bouton
  // ou pull-to-refresh). On redéclenche maintenant le chargement à CHAQUE
  // sélection d'onglet, pas seulement à la première visite.
  void _rafraichirOnglet(int index) {
    switch (index) {
      case 0:
        context.read<DashboardBloc>().add(LoadDashboard());
        break;
      case 1:
        context.read<InvitationBloc>().add(LoadInvitations());
        break;
      case 2:
        context.read<TicketBloc>().add(LoadTickets());
        break;
      case 3:
        context.read<NotifBloc>().add(LoadNotifs());
        break;
      // 4 (Tickets résolus, USAGER) et 5 (Admin) gèrent leur propre
      // rechargement en interne — pas de bloc partagé à rafraîchir ici.
    }
  }

  // 🛠️ FONCTION POUR AFFICHER LES INFORMATIONS DE L'UTILISATEUR
  void _showUserProfile(BuildContext context, AuthState authState) {
    String nom = "Utilisateur";
    String initiales = "KO";
    String role = "Usager";

    if (authState is AuthOk) {
      nom = authState.userNom;
      initiales = authState.initiales.isNotEmpty ? authState.initiales : 'KO';
      // 🎯 Avant : le rôle affiché était deviné grossièrement à partir du nom
      // ("admin" dans le nom => "Agent" sinon) — donc tout non-admin voyait
      // toujours "Agent", même un usager ou un superviseur. On utilise
      // maintenant le vrai rôle renvoyé par le backend à la connexion.
      role = _libelleRole(authState.role);
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8,
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 320),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar avec Initiales
                CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color.fromARGB(255, 3, 67, 20),
                  child: Text(
                    initiales,
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                // Nom de la personne connectée
                Text(
  nom,
  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                // Rôle ou département
                Text(
                  role,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                // Petite information contextuelle sur la session
                Row(
                  children: [
                    Icon(Icons.domain, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 12),
                    const Text("DSI MESFPT — Burkina Faso", style: TextStyle(fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 24),
                // Bouton Fermer
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 6, 70, 23),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Fermer", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _libelleRole(String role) {
    switch (role) {
      case 'ADMIN':       return 'Administrateur';
      case 'AGENT_DSI':   return 'Agent DSI';
      case 'SUPERVISEUR': return 'Superviseur';
      case 'SECRETAIRE':  return 'Secrétaire';
      case 'USAGER':      return 'Usager';
      default: return role.isEmpty ? 'Usager' : role;
    }
  }

  // 🎯 Compteurs de notifications non lues, partagés entre le rail (desktop)
  // et la barre de navigation du bas (mobile) pour éviter la duplication.
  int _nonLuesInvitations(NotifState s) =>
      s is NotifsLoaded ? s.list.where((n) => n.category == NotifCategory.invitation && !n.isRead).length : 0;

  int _nonLuesTickets(NotifState s) =>
      s is NotifsLoaded ? s.list.where((n) => n.category == NotifCategory.ticket && !n.isRead).length : 0;

  int _nonLuesTotal(NotifState s) {
    if (s is! NotifsLoaded) return 0;
    final List<dynamic> rawList = s.list;
    return rawList.where((n) {
      if (n == null) return false;
      if (n is NotificationModel) return !n.isRead;
      try { return n.isRead == false; } catch (_) { return false; }
    }).length;
  }

  Widget _badgeIcon(IconData icon, int Function(NotifState) compteur) {
    return BlocBuilder<NotifBloc, NotifState>(
      builder: (_, s) {
        final n = compteur(s);
        return Badge(label: Text('$n'), isLabelVisible: n > 0, child: Icon(icon));
      },
    );
  }

  static const Color _navColor = Color.fromARGB(255, 3, 71, 21);

  // 🎯 Indices absolus (alignés sur l'IndexedStack de _buildContent) des
  // onglets visibles selon le rôle. Un USAGER a Tickets (2), Alertes (3), et
  // le nouvel écran "Mes tickets" avec solutions (4). Les autres rôles
  // gardent Tableau de bord + Invitations + Tickets + Alertes, et ADMIN a
  // en plus l'onglet Admin (désormais à l'index 5).
  List<int> _indicesVisibles(AuthState authState) {
    final role = authState is AuthOk ? authState.role : '';
    if (role == 'USAGER') return [2, 3, 4];
    if (role == 'ADMIN') return [0, 1, 2, 3, 5];
    return [0, 1, 2, 3];
  }

  // 🎯 Index réellement affiché : si un USAGER se retrouve encore sur l'index
  // par défaut (0, Tableau de bord — masqué pour lui), on retombe sur Tickets (2).
  int _indexEffectif(AuthState authState) {
    final visibles = _indicesVisibles(authState);
    if (!visibles.contains(_currentIndex)) return visibles.first;
    return _currentIndex;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthOut) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final initiales = authState is AuthOk ? authState.initiales : '';

          // 🎯 Sous les ~600px de largeur (téléphone), on bascule sur une barre
          // de navigation en bas d'écran — le NavigationRail vertical est pensé
          // par Flutter pour tablette/desktop et grignote trop d'espace utile
          // sur un petit écran.
          return LayoutBuilder(builder: (context, constraints) {
            final estMobile = constraints.maxWidth < 600;
            return estMobile
                ? _buildMobileLayout(context, authState, initiales)
                : _buildDesktopLayout(context, authState, initiales);
          });
        },
      ),
    );
  }

  // ── Layout DESKTOP / TABLETTE — NavigationRail vertical ─────────────
  Widget _buildDesktopLayout(BuildContext context, AuthState authState, String initiales) {
    final visibles = _indicesVisibles(authState);
    final indexEffectif = _indexEffectif(authState);
    _ongletsVisites.add(indexEffectif);

    // 🎯 Toutes les destinations possibles, indexées par leur position
    // absolue dans l'IndexedStack (0..4) — on ne garde ensuite que celles
    // dont l'index est dans `visibles` pour ce rôle.
    final Map<int, NavigationRailDestination> toutes = {
      0: const NavigationRailDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: Text('Tableau de bord'),
      ),
      1: NavigationRailDestination(
        icon: _badgeIcon(Icons.mail_outline, _nonLuesInvitations),
        selectedIcon: const Icon(Icons.mail),
        label: const Text('Invitations'),
      ),
      2: NavigationRailDestination(
        icon: _badgeIcon(Icons.confirmation_number_outlined, _nonLuesTickets),
        selectedIcon: const Icon(Icons.confirmation_number),
        label: const Text('Tickets'),
      ),
      3: NavigationRailDestination(
        icon: _badgeIcon(Icons.notifications_outlined, _nonLuesTotal),
        selectedIcon: const Icon(Icons.notifications),
        label: const Text('Alertes'),
      ),
      4: const NavigationRailDestination(
        icon: Icon(Icons.fact_check_outlined),
        selectedIcon: Icon(Icons.fact_check),
        label: Text('Résolus'),
      ),
      5: const NavigationRailDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings),
        label: Text('Admin'),
      ),
    };

    return Scaffold(
      body: Row(children: [
        NavigationRail(
          selectedIndex: visibles.indexOf(indexEffectif),
          onDestinationSelected: (i) => setState(() {
            _currentIndex = visibles[i];
            _ongletsVisites.add(_currentIndex);
            _rafraichirOnglet(_currentIndex);
          }),
          labelType: NavigationRailLabelType.all,
          backgroundColor: _navColor,
          selectedIconTheme: const IconThemeData(color: Colors.white),
          unselectedIconTheme: const IconThemeData(color: Colors.white70),
          selectedLabelTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          unselectedLabelTextStyle: const TextStyle(color: Colors.white70),
          leading: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: IconButton(
              icon: const Icon(Icons.menu, color: Colors.white, size: 24),
              onPressed: () => _showUserProfile(context, authState),
            ),
          ),
          trailing: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _avatarMenu(initiales),
          ),
          destinations: [for (final i in visibles) toutes[i]!],
        ),
        const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFB0BEC5)),
        Expanded(child: _buildContent()),
      ]),
    );
  }

  // ── Layout MOBILE — barre de navigation en bas d'écran ──────────────
  Widget _buildMobileLayout(BuildContext context, AuthState authState, String initiales) {
    final visibles = _indicesVisibles(authState);
    final indexEffectif = _indexEffectif(authState);
    _ongletsVisites.add(indexEffectif);

    final Map<int, String> tousLesTitres = {
      0: 'Tableau de bord', 1: 'Invitations', 2: 'Tickets', 3: 'Alertes', 4: 'Tickets résolus', 5: 'Admin',
    };
    final Map<int, NavigationDestination> toutes = {
      0: const NavigationDestination(
        icon: Icon(Icons.dashboard_outlined, color: Colors.white70),
        selectedIcon: Icon(Icons.dashboard, color: Colors.white),
        label: 'Accueil',
      ),
      1: NavigationDestination(
        icon: _badgeIcon(Icons.mail_outline, _nonLuesInvitations),
        selectedIcon: const Icon(Icons.mail, color: Colors.white),
        label: 'Invitations',
      ),
      2: NavigationDestination(
        icon: _badgeIcon(Icons.confirmation_number_outlined, _nonLuesTickets),
        selectedIcon: const Icon(Icons.confirmation_number, color: Colors.white),
        label: 'Tickets',
      ),
      3: NavigationDestination(
        icon: _badgeIcon(Icons.notifications_outlined, _nonLuesTotal),
        selectedIcon: const Icon(Icons.notifications, color: Colors.white),
        label: 'Alertes',
      ),
      4: const NavigationDestination(
        icon: Icon(Icons.fact_check_outlined, color: Colors.white70),
        selectedIcon: Icon(Icons.fact_check, color: Colors.white),
        label: 'Résolus',
      ),
      5: const NavigationDestination(
        icon: Icon(Icons.settings_outlined, color: Colors.white70),
        selectedIcon: Icon(Icons.settings, color: Colors.white),
        label: 'Admin',
      ),
    };

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _navColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _showUserProfile(context, authState),
        ),
        title: Text(tousLesTitres[indexEffectif]!, style: const TextStyle(fontSize: 16)),
        actions: [_avatarMenu(initiales), const SizedBox(width: 8)],
      ),
      body: _buildContent(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: visibles.indexOf(indexEffectif),
        onDestinationSelected: (i) => setState(() {
          _currentIndex = visibles[i];
          _ongletsVisites.add(_currentIndex);
          _rafraichirOnglet(_currentIndex);
        }),
        backgroundColor: _navColor,
        indicatorColor: Colors.white24,
        labelTextStyle: MaterialStateProperty.all(const TextStyle(color: Colors.white, fontSize: 11)),
        destinations: [for (final i in visibles) toutes[i]!],
      ),
    );
  }

  Widget _avatarMenu(String initiales) {
    return PopupMenuButton<String>(
      onSelected: (v) {
        if (v == 'logout') context.read<AuthBloc>().add(LogoutRequested());
      },
      child: CircleAvatar(
        backgroundColor: Colors.white24,
        child: Text(
          initiales.isNotEmpty ? initiales : 'KO',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'logout',
          child: Row(children: [
            Icon(Icons.logout, size: 16),
            SizedBox(width: 8),
            Text('Déconnexion'),
          ]),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (_, authState) {
        final estAdmin = authState is AuthOk && authState.role == 'ADMIN';
        final indexEffectif = _indexEffectif(authState);
        // 🎯 Un onglet non encore visité reste un simple SizedBox — aucun de
        // ses appels API (LoadTickets, LoadInvitationsRecues, LoadNotifs...)
        // n'est déclenché tant que l'utilisateur n'a pas cliqué dessus.
        Widget tab(int index, Widget Function() builder) =>
            _ongletsVisites.contains(index) ? builder() : const SizedBox.shrink();

        return IndexedStack(
          index: indexEffectif,
          children: [
            tab(0, () => const DashboardScreen()),
            tab(1, () => const InvitationsScreen()),
            tab(2, () => const TicketsScreen()),
            tab(3, () => const NotificationsScreen()),
            tab(4, () => const MesTicketsSolutionsScreen()),
            estAdmin
                ? tab(5, () => const AdminScreen())
                : _AccesRefuse(role: authState is AuthOk ? authState.role : ''),
          ],
        );
      },
    );
  }
}

/// Écran affiché à la place d'Admin pour tout utilisateur non-ADMIN qui
/// arriverait sur cet onglet (normalement caché de la navigation, mais on
/// garde ce garde-fou si l'index est atteint autrement).
class _AccesRefuse extends StatelessWidget {
  final String role;
  const _AccesRefuse({required this.role});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.lock_outline, size: 48, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              "Accès non autorisé",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              "Seul un administrateur peut accéder à cette section.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ]),
        ),
      ),
    );
  }
}