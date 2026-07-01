import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/all_blocs.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widget/shared_widget.dart';
import 'tickets_screen.dart'; // Import nécessaire pour la redirection vers les détails
import 'invitations_screen.dart'; // Import nécessaire pour la redirection vers les détails des invitations

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
      Navigator.push(
      context,
      MaterialPageRoute(
        // Ajuste le nom du widget selon l'écran de destination de tes invitations
        // Si tu as un écran de détail, tu peux lui passer l'ID : n.relatedResourceId
        builder: (_) => const InvitationsScreen(), 
      ),
    );
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
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildSection(
                        context,
                        title: 'Invitations',
                        emptyLabel: 'Aucune notification d\'invitation',
                        items: notifications.where((n) => n.category == NotifCategory.invitation).toList(),
                      ),
                      const SizedBox(height: 16),
                      _buildSection(
                        context,
                        title: 'Tickets',
                        emptyLabel: 'Aucune notification de ticket',
                        items: notifications.where((n) => n.category == NotifCategory.ticket).toList(),
                      ),
                      Builder(builder: (_) {
                        final autres = notifications
                            .where((n) => n.category != NotifCategory.invitation && n.category != NotifCategory.ticket)
                            .toList();
                        if (autres.isEmpty) return const SizedBox.shrink();
                        return Column(children: [
                          const SizedBox(height: 16),
                          _buildSection(context, title: 'Autres', emptyLabel: '', items: autres),
                        ]);
                      }),
                      const SizedBox(height: 16),
                    ],
                  ),
          ),
        );
      },
    );
  }

  /// Section façon "Invitations récentes" / "Tickets récents" du tableau de bord :
  /// une carte regroupant les lignes (icône + titre + sous-titre + pastille),
  /// séparées par un Divider — c'est ce format que Dev a demandé pour les
  /// notifications d'invitation enregistrée / ticket créé.
  Widget _buildSection(BuildContext context, {required String title, required String emptyLabel, required List<NotificationModel> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title),
        const SizedBox(height: 8),
        items.isEmpty
            ? AppCard(child: Center(child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(emptyLabel, style: const TextStyle(color: AppColors.muted)))))
            : AppCard(child: Column(
                children: items.asMap().entries.map((e) => _buildNotifRow(context, e.value, isLast: e.key == items.length - 1)).toList(),
              )),
      ],
    );
  }

  Widget _buildNotifRow(BuildContext context, NotificationModel n, {bool isLast = false}) {
    return Column(children: [
      InkWell(
        onTap: () => _handleNotificationAction(context, n),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: n.isRead ? AppColors.surface : AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_iconFor(n.category), size: 16, color: n.isRead ? const Color.fromARGB(255, 27, 77, 215) : const Color.fromARGB(255, 155, 34, 10)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(n.message,
                  style: TextStyle(fontSize: 13, fontWeight: n.isRead ? FontWeight.w400 : FontWeight.w500, color: n.isRead ? AppColors.muted : null),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(_formatDate(n.date), style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            ])),
            const SizedBox(width: 8),
            n.isRead
                ? const StatusBadge(label: 'Lu', bg: AppColors.surface, fg: Color.fromARGB(255, 24, 49, 139))
                : const StatusBadge(label: 'Nouveau', bg: AppColors.primaryLight, fg: Color.fromARGB(255, 186, 27, 6)),
          ]),
        ),
      ),
      if (!isLast) const Divider(height: 0),
    ]);
  }
}