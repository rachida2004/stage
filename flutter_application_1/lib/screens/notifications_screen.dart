import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/all_blocs.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widget/shared_widget.dart';
import 'tickets_screen.dart'; // Import nécessaire pour la redirection vers les détails

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override 
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() { 
    super.initState(); 
    context.read<NotifBloc>().add(LoadNotifs()); 
  }

  IconData _iconFor(NotifCategory cat) {
    switch (cat) {
      case NotifCategory.invitation: return Icons.mail_outline;
      case NotifCategory.ticket:     return Icons.confirmation_number_outlined;
      case NotifCategory.admin:      return Icons.settings_outlined;
      case NotifCategory.dashboard:  return Icons.dashboard_outlined;
    }
  }

  String _categoryLabel(NotifCategory cat) {
    switch (cat) {
      case NotifCategory.invitation: return 'Invitations';
      case NotifCategory.ticket:     return 'Tickets';
      case NotifCategory.admin:      return 'Administration';
      case NotifCategory.dashboard:  return 'Tableau de bord';
    }
  }

  String _formatDate(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24)   return 'Il y a ${diff.inHours}h';
    return '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
  }

  /// Gestionnaire d'action dynamique basé sur le type et la ressource ciblée par le backend
  void _handleNotificationAction(BuildContext context, NotificationModel n) {
    // 1. On informe immédiatement le backend via le BLoC que la notification est lue
    if (!n.isRead) {
      context.read<NotifBloc>().add(MarkRead(n.id));
    }

    // 2. Routage dynamique selon les métadonnées fournies par Spring Boot
    if (n.category == NotifCategory.ticket && n.relatedResourceId != null) {
      // Exemple : Redirection vers le détail d'un ticket spécifique
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TicketsScreen(), // Ajuste ici vers ton TicketDetailScreen si accessible directement
        ),
      );
    } else if (n.category == NotifCategory.invitation) {
      // Traitement ou navigation spécifique aux invitations
    }
    // Ajoute d'autres aiguillages ici selon les besoins de ton modèle de données
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotifBloc, NotifState>(
      builder: (context, state) {
        // En production, on s'appuie exclusivement sur les données du State émis par le Bloc connecté à l'API
        List<NotificationModel> notifications = [];
        bool isLoading = state is NotifLoading;

        if (state is NotifsLoaded) {
          notifications = state.list;
        } else if (state is NotifError) {
          // Idéalement, afficher un message d'erreur ou un bouton de rechargement en cas d'échec de l'API
          notifications = [];
        }

        final unread = notifications.where((n) => !n.isRead).length;

        return Scaffold(
          appBar: AppBar(
            title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Notifications'),
              Text('$unread non lue${unread != 1 ? 's' : ''}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.muted)),
            ]),
            actions: [
              if (isLoading) const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
              TextButton(
                onPressed: () => context.read<NotifBloc>().add(MarkAllRead()), 
                child: const Text('Tout lire', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async => context.read<NotifBloc>().add(LoadNotifs()),
            child: notifications.isEmpty && !isLoading
                ? const Center(child: Text('Aucune notification', style: TextStyle(color: AppColors.muted)))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final n = notifications[i];
                      return AppCard(
                        onTap: () => _handleNotificationAction(context, n), // Rendre toute la carte cliquable pour le backend
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Column(children: [
                            Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: n.isRead ? Colors.transparent : AppColors.primary)),
                            const SizedBox(height: 4),
                            Container(width: 34, height: 34, decoration: BoxDecoration(color: n.isRead ? AppColors.surface : AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
                              child: Icon(_iconFor(n.category), size: 16, color: n.isRead ? AppColors.muted : AppColors.primary)),
                          ]),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(n.message, style: TextStyle(fontSize: 13, color: n.isRead ? AppColors.muted : null)),
                            const SizedBox(height: 4),
                            Row(children: [
                              Text(_formatDate(n.date), style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                              const SizedBox(width: 6),
                              Container(width: 3, height: 3, decoration: const BoxDecoration(color: AppColors.muted, shape: BoxShape.circle)),
                              const SizedBox(width: 6),
                              Text(_categoryLabel(n.category), style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                            ]),
                          ])),
                          if (n.actionLabel != null) ...[
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () => _handleNotificationAction(context, n),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary, 
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), 
                                minimumSize: Size.zero, 
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(n.actionLabel!, style: const TextStyle(fontSize: 12)),
                            ),
                          ],
                        ]),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }
}