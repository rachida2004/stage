import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/all_blocs.dart';
import '../theme/app_theme.dart';
import '../models/models.dart'; 
import 'dashboard_screen.dart';
import 'invitations_screen.dart';
import 'tickets_screen.dart';
import 'notifications_screen.dart';
import 'admin_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotifBloc>().add(LoadNotifs());
    });
  }

  // 🛠️ FONCTION POUR AFFICHER LES INFORMATIONS DE L'UTILISATEUR
  void _showUserProfile(BuildContext context, AuthState authState) {
    String nom = "Utilisateur";
    String initiales = "KO";
    String role = "Agent";

    if (authState is AuthOk) {
      nom = authState.userNom;
      initiales = authState.initiales.isNotEmpty ? authState.initiales : 'KO';
      // Si ton application gère des rôles administratifs (ex: admin2)
      if (nom.toLowerCase().contains('admin')) {
        role = "Administrateur Système";
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8,
          child: Container(
            padding: const EdgeInsets.all(24),
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar avec Initiales
                CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color.fromARGB(255, 10, 206, 62),
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
                    const Text("DSI Ministère — Burkina Faso", style: TextStyle(fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 24),
                // Bouton Fermer
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 10, 206, 62),
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
          return Scaffold(
            body: Row(children: [
              NavigationRail(
                selectedIndex: _currentIndex,
                onDestinationSelected: (i) => setState(() => _currentIndex = i),
                labelType: NavigationRailLabelType.all,
                backgroundColor: const Color.fromARGB(255, 10, 206, 62),
                selectedIconTheme: const IconThemeData(color: Colors.white),
                unselectedIconTheme: const IconThemeData(color: Colors.white70),
                selectedLabelTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                unselectedLabelTextStyle: const TextStyle(color: Colors.white70),
                leading: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white, size: 24),
                    // 🎯 LE BOUTON DÉCLENCHE MAINTENANT L'AFFICHAGE DU PROFIL
                    onPressed: () => _showUserProfile(context, authState),
                  ),
                ),
                trailing: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: PopupMenuButton<String>(
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
                  ),
                ),
                destinations: [
                  const NavigationRailDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard),
                    label: Text('Tableau de bord'),
                  ),
                  const NavigationRailDestination(
                    icon: Icon(Icons.mail_outline),
                    selectedIcon: Icon(Icons.mail),
                    label: Text('Invitations'),
                  ),
                  const NavigationRailDestination(
                    icon: Icon(Icons.confirmation_number_outlined),
                    selectedIcon: Icon(Icons.confirmation_number),
                    label: Text('Tickets'),
                  ),
                  NavigationRailDestination(
                    icon: BlocBuilder<NotifBloc, NotifState>(
                      builder: (_, s) {
                        int unread = 0;
                        if (s is NotifsLoaded) {
                          final List<dynamic> rawList = s.list;
                          unread = rawList.where((n) {
                            if (n == null) return false;
                            if (n is NotificationModel) return !n.isRead;
                            try { return n.isRead == false; } catch (_) { return false; }
                          }).length;
                        }
                        return Badge(
                          label: Text('$unread'),
                          isLabelVisible: unread > 0,
                          child: const Icon(Icons.notifications_outlined),
                        );
                      },
                    ),
                    selectedIcon: const Icon(Icons.notifications),
                    label: const Text('Alertes'),
                  ),
                  const NavigationRailDestination(
                    icon: Icon(Icons.settings_outlined),
                    selectedIcon: Icon(Icons.settings),
                    label: Text('Admin'),
                  ),
                ],
              ),
              const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFB0BEC5)),
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: const [
                    DashboardScreen(),
                    InvitationsScreen(),
                    TicketsScreen(),
                    NotificationsScreen(),
                    AdminScreen(),
                  ],
                ),
              ),
            ]),
          );
        },
      ),
    );
  }
}