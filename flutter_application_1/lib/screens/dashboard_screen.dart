import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/bloc/all_blocs.dart';
import 'package:flutter_application_1/models/models.dart';
import 'package:flutter_application_1/theme/app_theme.dart';
import 'package:flutter_application_1/widget/shared_widget.dart';
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Déclencher le chargement dès que l'écran s'affiche
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardBloc>().add(LoadDashboard());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state is DashboardLoading || state is DashboardInitial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (state is DashboardError) {
          return Scaffold(
            appBar: AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tableau de bord',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  Text('Erreur de connexion — réessayez',
                      style: TextStyle(fontSize: 11, color: AppColors.warning)),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_outlined, size: 20),
                  tooltip: 'Réessayer',
                  onPressed: () => context.read<DashboardBloc>().add(LoadDashboard()),
                ),
              ],
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Impossible de charger les données',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Text('${state.message}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.read<DashboardBloc>().add(LoadDashboard()),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          );
        }
      
        if (state is DashboardLoaded) {
          return _buildContent(
            context,
            stats: state.stats,
            invitations: state.recentInvitations,
            tickets: state.recentTickets,
          );
        }
        return const Scaffold(body: SizedBox());
      },
    );
  }

  // Déplacé à l'intérieur de la classe State pour correspondre à ton implémentation
  Widget _buildContent(BuildContext context, {
    required DashboardStats stats,
    required List<Invitation> invitations,
    required List<Ticket> tickets,
    bool offline = false,
  }) {
    final authState = context.read<AuthBloc>().state;
    final nom = authState is AuthOk ? authState.userNom : '';

    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Bonjour${nom.isNotEmpty ? ', $nom' : ''}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          Text(
            offline ? 'Mode hors-ligne — données de démonstration' : 'DSI Ministère — Burkina Faso',
            style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w400,
              color: offline ? AppColors.warning : AppColors.muted,
            ),
          ),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined, size: 20),
            tooltip: 'Actualiser',
            onPressed: () => context.read<DashboardBloc>().add(LoadDashboard()),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: UserAvatar(initials: 'KO', size: 32),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => context.read<DashboardBloc>().add(LoadDashboard()),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // KPI row 1
            Row(children: [
              Expanded(child: _KpiCard(
                value: '${stats.totalInvitations}', label: 'Invitations',
                delta: '${stats.invitationsEnAttente} en attente',
                deltaPositive: stats.invitationsEnAttente == 0,
                icon: Icons.mail_outline,
                bg: const Color(0xFFEFF6FF), iconColor: const Color(0xFF2563EB), valueColor: const Color(0xFF1D4ED8),
              )),
              const SizedBox(width: 10),
              Expanded(child: _KpiCard(
                value: '${stats.ticketsOuverts}', label: 'Tickets ouverts',
                delta: '${stats.totalTickets} au total', deltaPositive: false,
                icon: Icons.confirmation_number_outlined,
                bg: const Color(0xFFFFF7ED), iconColor: const Color(0xFFEA580C), valueColor: const Color(0xFFC2410C),
              )),
            ]),
            const SizedBox(height: 10),
            // KPI row 2
            Row(children: [
              Expanded(child: _KpiCard(
                value: '${stats.invitationsTerminees}', label: 'Traitées',
                delta: '${stats.invitationsPlanifiees} planifiées', deltaPositive: true,
                icon: Icons.trending_up_outlined,
                bg: const Color(0xFFF0FDF4), iconColor: const Color(0xFF16A34A), valueColor: const Color(0xFF15803D),
              )),
              const SizedBox(width: 10),
              Expanded(child: _KpiCard(
                value: '${stats.totalUsers}', label: 'Utilisateurs',
                delta: 'Agents actifs', deltaPositive: true,
                icon: Icons.people_outline,
                bg: const Color(0xFFF5F3FF), iconColor: const Color(0xFF7C3AED), valueColor: const Color(0xFF6D28D9),
              )),
            ]),
            const SizedBox(height: 16),

            const SectionHeader(title: 'Invitations récentes'),
            const SizedBox(height: 8),
            invitations.isEmpty
                ? const AppCard(child: Center(child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Aucune invitation', style: TextStyle(color: AppColors.muted)))))
                : AppCard(child: Column(
                    children: invitations.take(3).toList().asMap().entries.map((e) =>
                      _InvitationListTile(inv: e.value, isLast: e.key == (invitations.take(3).length - 1))
                    ).toList(),
                  )),
            const SizedBox(height: 16),

            const SectionHeader(title: 'Tickets récents'),
            const SizedBox(height: 8),
            tickets.isEmpty
                ? const AppCard(child: Center(child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Aucun ticket', style: TextStyle(color: AppColors.muted)))))
                : AppCard(child: Column(
                    children: tickets.take(3).toList().asMap().entries.map((e) =>
                      _TicketListTile(ticket: e.value, isLast: e.key == (tickets.take(3).length - 1))
                    ).toList(),
                  )),
            const SizedBox(height: 16),

            const SectionHeader(title: 'Répartition des invitations par statut'),
            const SizedBox(height: 8),
            AppCard(child: Column(children: [
              BarChartRow(label: 'En attente',  value: stats.invitationsEnAttente,    total: stats.totalInvitations, color: const Color(0xFFEF9F27)),
              BarChartRow(label: 'Planifiée',   value: stats.invitationsPlanifiees,   total: stats.totalInvitations, color: AppColors.primary),
              BarChartRow(label: 'En cours',    value: stats.invitationsEnCours,      total: stats.totalInvitations, color: const Color(0xFF1D9E75)),
              BarChartRow(label: 'Terminée',    value: stats.invitationsTerminees,    total: stats.totalInvitations, color: const Color(0xFF639922)),
              BarChartRow(label: 'Non traitée', value: stats.invitationsNonTraitees,  total: stats.totalInvitations, color: AppColors.danger),
            ])),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
} // <--- ACCOLADE AJOUTÉE ICI : Ferme proprement la classe _DashboardScreenState

// ════════════════════════════════════════════════════════════════════
// WIDGETS PRIVÉS (Déclarés hors de la classe du State)
// ════════════════════════════════════════════════════════════════════

class _KpiCard extends StatelessWidget {
  final String value, label, delta;
  final bool deltaPositive;
  final IconData icon;
  final Color bg, iconColor, valueColor;
  const _KpiCard({
    required this.value, required this.label, required this.delta,
    required this.deltaPositive, required this.icon,
    required this.bg, required this.iconColor, required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withOpacity(0.2), width: 0.8),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: iconColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: valueColor, height: 1.1)),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(delta, style: TextStyle(fontSize: 10, color: deltaPositive ? const Color(0xFF16A34A) : const Color(0xFFDC2626))),
          ],
        )),
      ]),
    );
  }
}

class _InvitationListTile extends StatelessWidget {
  final Invitation inv;
  final bool isLast;
  const _InvitationListTile({required this.inv, this.isLast = false});
  String _fmt(DateTime d) => '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.mail_outline, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(inv.objet, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('${inv.structureEmettrice} · ${_fmt(inv.dateDebut)}', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          ])),
          StatusBadge.fromInvStatus(inv.status),
        ]),
      ),
      if (!isLast) const Divider(height: 0),
    ]);
  }
}

class _TicketListTile extends StatelessWidget {
  final Ticket ticket;
  final bool isLast;
  const _TicketListTile({required this.ticket, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    Color iconBg;
    switch (ticket.priority) {
      case TicketPriority.haute:   iconBg = AppColors.dangerLight;  break;
      case TicketPriority.normale: iconBg = AppColors.warningLight; break;
      case TicketPriority.basse:   iconBg = AppColors.successLight; break;
    }
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text('#${ticket.id}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.muted))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(ticket.description, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(ticket.agentAssigneNom != null ? 'Agent: ${ticket.agentAssigneNom}' : 'Non affecté', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          ])),
          StatusBadge.fromTicketStatus(ticket.status),
        ]),
      ),
      if (!isLast) const Divider(height: 0),
    ]);
  }
}