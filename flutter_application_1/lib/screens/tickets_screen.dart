import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widget/shared_widget.dart';
import '../bloc/all_blocs.dart';

// ═══════════════════════════════════════════════════════════════════
// SCREEN PRINCIPAL : Liste des tickets
// ═══════════════════════════════════════════════════════════════════
class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});
  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  String _search = '';
  TicketStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    context.read<TicketBloc>().add(LoadTickets());
    // 🎯 Vide la pastille "Tickets" (notifications liées non lues) à l'ouverture de l'écran.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<NotifBloc>().add(MarkCategoryRead(NotifCategory.ticket));
    });
  }

  List<Ticket> _applyFilters(List<Ticket> all) {
    return all.where((t) {
      final matchSearch = t.description.toLowerCase().contains(_search.toLowerCase()) ||
          t.id.contains(_search);
      final matchStatus = _filterStatus == null || t.status == _filterStatus;
      return matchSearch && matchStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TicketBloc, TicketState>(
      builder: (context, state) {
        List<Ticket> allTickets = [];
        bool isLoading = state is TicketLoading;

        if (state is TicketsLoaded) {
          allTickets = state.page.items;
        } else if (state is TicketError) {
          final pasDeDroits = state.msg.contains('droits nécessaires') || state.msg.contains('session a expiré');
          return Scaffold(
            appBar: AppBar(title: const Text('Tickets')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  state.msg,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: pasDeDroits ? Colors.orange[800] : Colors.red),
                ),
              ),
            ),
          );
        }

        final filtered = _applyFilters(allTickets);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Tickets'),
            actions: [
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              IconButton(
                icon: const Icon(Icons.refresh_outlined, size: 20),
                onPressed: () => context.read<TicketBloc>().add(LoadTickets()),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            heroTag: "fab_tickets",
            onPressed: () => _showCreateTicketSheet(context),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            child: const Icon(Icons.add),
          ),
          body: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(children: [
                AppSearchBar(
                  hint: 'Rechercher un ticket...',
                  onChanged: (v) => setState(() => _search = v),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    _FilterChip(
                      label: 'Tous',
                      selected: _filterStatus == null,
                      onTap: () => setState(() => _filterStatus = null),
                    ),
                    const SizedBox(width: 6),
                    ...TicketStatus.values.map((s) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _FilterChip(
                          label: s.label,
                          selected: _filterStatus == s,
                          onTap: () => setState(() => _filterStatus = _filterStatus == s ? null : s),
                        ),
                      )),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filtered.isEmpty && !isLoading
                  ? const Center(child: Text('Aucun ticket trouvé', style: TextStyle(color: AppColors.muted)))
                  : RefreshIndicator(
                      onRefresh: () async => context.read<TicketBloc>().add(LoadTickets()),
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) => _TicketCard(
                          ticket: filtered[i],
                          onTap: () => Navigator.push(ctx,
                            MaterialPageRoute(builder: (_) => TicketDetailScreen(ticket: filtered[i]))),
                        ),
                      ),
                    ),
            ),
          ]),
        );
      },
    );
  }

  void _showCreateTicketSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => BlocProvider.value(
        value: context.read<TicketBloc>(),
        child: const _CreateTicketSheet(),
      ),
      backgroundColor: Colors.white,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// WIDGET : Chip de filtre
// ═══════════════════════════════════════════════════════════════════
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: 0.5),
        ),
        child: Text(label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
              color: selected ? Colors.white : AppColors.muted)),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// WIDGET : Carte ticket dans la liste
// ═══════════════════════════════════════════════════════════════════
class _TicketCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback onTap;
  const _TicketCard({required this.ticket, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Color iconBg;
    switch (ticket.priority) {
      case TicketPriority.haute: iconBg = AppColors.dangerLight; break;
      case TicketPriority.normale: iconBg = AppColors.warningLight; break;
      case TicketPriority.basse: iconBg = AppColors.successLight; break;
    }
    return AppCard(
      onTap: onTap,
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
          child: Center(child: Text('#${ticket.id}',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.muted))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(ticket.description,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Text(
              ticket.agentAssigneNom != null ? 'Agent: ${ticket.agentAssigneNom}' : 'Non affecté',
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
            const SizedBox(height: 6),
            Row(children: [
              StatusBadge.fromTicketStatus(ticket.status),
              const SizedBox(width: 8),
              PriorityBadge(priority: ticket.priority),
            ]),
          ]),
        ),
        const Icon(Icons.chevron_right, size: 18, color: AppColors.muted),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// SCREEN : Détail d'un ticket
// ═══════════════════════════════════════════════════════════════════
class TicketDetailScreen extends StatefulWidget {
  final Ticket ticket;
  const TicketDetailScreen({super.key, required this.ticket});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<TicketBloc>().add(LoadTicketDetail(widget.ticket.id));
  }

  void _showDeleteConfirmationDialog(BuildContext context, String ticketId) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Supprimer le ticket ?'),
          content: const Text('Êtes-vous sûr de vouloir supprimer définitivement ce ticket ? Cette action est irréversible.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                context.read<TicketBloc>().add(DeleteTicket(ticketId));
                Navigator.pop(dialogContext);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }

  // 🎯 Le backend exige un texte de solution pour passer un ticket en RESOLU
  // (TicketService.modifierStatut lève une erreur 400 sinon — "Une solution
  // est requise pour clore le ticket."). On demande donc cette solution
  // avant d'envoyer la requête, au lieu de marquer résolu directement.
  void _demanderSolutionEtResoudre(BuildContext context, String ticketId) {
    final solutionCtrl = TextEditingController();
    final ticketBloc = context.read<TicketBloc>();
    String? erreur;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            title: const Text('Marquer le ticket résolu'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Décrivez brièvement la solution apportée :',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: solutionCtrl,
                  autofocus: true,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'ex: Remplacement du câble réseau défectueux',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    errorText: erreur,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                onPressed: () {
                  if (solutionCtrl.text.trim().isEmpty) {
                    setState(() => erreur = 'La solution est obligatoire.');
                    return;
                  }
                  Navigator.pop(dialogContext);
                  ticketBloc.add(UpdateStatut(
                    ticketId,
                    TicketStatus.resolu,
                    solution: solutionCtrl.text.trim(),
                  ));
                },
                child: const Text('Valider', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _ouvrirDialogueAffectation(BuildContext context, String ticketId) {
    AppUser? agentSelectionne;
    context.read<AdminBloc>().add(LoadUsers());

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Affecter un agent au ticket"),
          content: BlocBuilder<AdminBloc, AdminState>(
            bloc: context.read<AdminBloc>(),
            builder: (context, state) {
              if (state is AdminLoading) {
                return const SizedBox(height: 60, child: Center(child: CircularProgressIndicator()));
              }
              if (state is UsersLoaded) {
                return DropdownButtonFormField<AppUser>(
                  decoration: const InputDecoration(labelText: "Sélectionner un agent", border: OutlineInputBorder()),
                  value: agentSelectionne,
                  items: state.users.map((user) => DropdownMenuItem<AppUser>(
                    value: user, child: Text("${user.nom} ${user.prenom}"))).toList(),
                  onChanged: (val) => agentSelectionne = val,
                );
              }
              return const Text("Erreur lors de la récupération des agents.");
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Annuler")),
            ElevatedButton(
              onPressed: () {
                if (agentSelectionne != null) {
                  context.read<TicketBloc>().add(AffecterAgentTkt(ticketId, agentSelectionne!.id.toString()));
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text("Affecter"),
            ),
          ],
        );
      },
    );
  }

  /// Ouvre WhatsApp via lien direct
  Future<void> _ouvrirWhatsApp(BuildContext context, String numero) async {
    // Nettoie le numéro : enlève +, espaces, tirets
    final clean = numero.replaceAll(RegExp(r'[^\d]'), '');
    final uri = Uri.parse('https://wa.me/$clean');
    try {
      if (await url_launcher.canLaunchUrl(uri)) {
        await url_launcher.launchUrl(uri, mode: url_launcher.LaunchMode.externalApplication);
      } else {
        throw "Impossible d'ouvrir WhatsApp";
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TicketBloc, TicketState>(
      listener: (context, state) {
        if (state is TicketDeletedSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ticket supprimé avec succès')),
          );
          context.read<TicketBloc>().add(LoadTickets());
          Navigator.pop(context);
        }
      },
      child: BlocBuilder<TicketBloc, TicketState>(
        builder: (context, state) {
          Ticket t = widget.ticket;
          if (state is TicketDetailL) t = state.ticket;

          if (state is TicketError && state.msg.isNotEmpty) {
            final pasDeDroits = state.msg.contains('droits nécessaires') || state.msg.contains('session a expiré');
            return Scaffold(
              appBar: AppBar(title: Text('#${widget.ticket.id}')),
              body: Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(state.msg, style: TextStyle(color: pasDeDroits ? Colors.orange[800] : Colors.red), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.read<TicketBloc>().add(LoadTicketDetail(widget.ticket.id)),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer'),
                  ),
                ]),
              ),
            );
          }

          // Récupération du numéro WhatsApp si disponible dans le ticket
          final String? whatsapp = t.whatsapp;

          return Scaffold(
            appBar: AppBar(
              title: Text('#${t.id}', style: const TextStyle(fontSize: 15)),
              actions: [
                // Bouton WhatsApp dans l'AppBar si numéro disponible
                if (whatsapp != null && whatsapp.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.chat, color: Color(0xFF25D366)),
                    tooltip: 'Contacter sur WhatsApp',
                    onPressed: () => _ouvrirWhatsApp(context, whatsapp),
                  ),
                // 🎯 Un USAGER crée un ticket et consulte son état, mais ne gère
                // pas son cycle de vie (affecter/pause/résolu/fermer/supprimer) —
                // c'est l'agent affecté qui le fait. On masque donc ce menu pour lui.
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (_, authState) {
                    final estUsager = authState is AuthOk && authState.role == 'USAGER';
                    if (estUsager) return const SizedBox.shrink();
                    return PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'assign') _ouvrirDialogueAffectation(context, t.id);
                        else if (v == 'pause') context.read<TicketBloc>().add(UpdateStatut(t.id, TicketStatus.enPause));
                        else if (v == 'resolve') _demanderSolutionEtResoudre(context, t.id);
                        else if (v == 'close') context.read<TicketBloc>().add(UpdateStatut(t.id, TicketStatus.ferme));
                        else if (v == 'delete') _showDeleteConfirmationDialog(context, t.id);
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'assign', child: Text('Affecter un agent')),
                        const PopupMenuItem(value: 'pause', child: Text('Mettre en pause')),
                        const PopupMenuItem(value: 'resolve', child: Text('Marquer résolu')),
                        const PopupMenuItem(value: 'close', child: Text('Fermer le ticket')),
                        const PopupMenuDivider(),
                        const PopupMenuItem(value: 'delete', child: Text('Supprimer', style: TextStyle(color: Colors.red))),
                      ],
                    );
                  },
                ),
              ],
            ),
            body: SingleChildScrollView(
              child: Column(children: [
                if (state is TicketLoading) const LinearProgressIndicator(minHeight: 2),

                // ── Infos ticket ───────────────────────────────────────
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(t.description, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Row(children: [
                      StatusBadge.fromTicketStatus(t.status),
                      const SizedBox(width: 8),
                      PriorityBadge(priority: t.priority),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.business_outlined, size: 14, color: AppColors.muted),
                      const SizedBox(width: 4),
                      Text(t.structure, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                      const SizedBox(width: 12),
                      const Icon(Icons.person_outline, size: 14, color: AppColors.muted),
                      const SizedBox(width: 4),
                      Text(t.agentAssigneNom ?? 'Non affecté',
                          style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                    ]),

                    // ── Contact WhatsApp ────────────────────────────────
                    if (whatsapp != null && whatsapp.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: () => _ouvrirWhatsApp(context, whatsapp),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF25D366).withOpacity(0.4)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.chat_bubble_outline, size: 16, color: Color(0xFF25D366)),
                            const SizedBox(width: 8),
                            Text(whatsapp, style: const TextStyle(
                                fontSize: 13, color: Color(0xFF128C7E), fontWeight: FontWeight.w500)),
                            const Spacer(),
                            const Text('Ouvrir WhatsApp',
                                style: TextStyle(fontSize: 11, color: Color(0xFF25D366))),
                            const SizedBox(width: 4),
                            const Icon(Icons.open_in_new, size: 13, color: Color(0xFF25D366)),
                          ]),
                        ),
                      ),
                    ],

                    // ── Pièces jointes (galerie d'aperçu) ──────────────
                    if (t.attachments.isNotEmpty || (t.attachmentUrl != null && t.attachmentUrl!.isNotEmpty)) ...[
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      const Text('Pièces jointes',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted)),
                      const SizedBox(height: 8),
                      _AttachmentGallery(
                        urls: t.attachments.isNotEmpty
                            ? t.attachments
                            : [t.attachmentUrl!], // fallback compat
                      ),
                    ],

                    // ── Solution apportée (si le ticket a été résolu) ────
                    if (t.solution != null && t.solution!.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      const Text('Solution apportée',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted)),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.success.withOpacity(0.3)),
                        ),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Icon(Icons.check_circle_outline, size: 16, color: AppColors.success),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(t.solution!, style: const TextStyle(fontSize: 13, color: AppColors.success)),
                          ),
                        ]),
                      ),
                    ],

                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 12),

                    // ── Boutons d'action (masqués pour un USAGER — il consulte
                    // l'état mais ne gère pas le cycle de vie du ticket) ────
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (_, authState) {
                        final estUsager = authState is AuthOk && authState.role == 'USAGER';
                        if (estUsager) return const SizedBox.shrink();
                        return Column(children: [
                          Row(children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => context.read<TicketBloc>().add(UpdateStatut(t.id, TicketStatus.enPause)),
                                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                                child: const Text('En pause', style: TextStyle(fontSize: 12)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _demanderSolutionEtResoudre(context, t.id),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.success,
                                    padding: const EdgeInsets.symmetric(vertical: 10)),
                                child: const Text('Résolu', style: TextStyle(fontSize: 12, color: Colors.white)),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 8),
                          // ── Bouton supprimer centré ─────────────────────
                          Center(
                            child: OutlinedButton.icon(
                              onPressed: () => _showDeleteConfirmationDialog(context, t.id),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red, width: 1.0),
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.delete_outline, size: 16),
                              label: const Text('Supprimer le ticket',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                            ),
                          ),
                        ]);
                      },
                    ),
                    const SizedBox(height: 8),
                  ]),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// WIDGET : Galerie d'aperçu des pièces jointes
// ═══════════════════════════════════════════════════════════════════
class _AttachmentGallery extends StatelessWidget {
  final List<String> urls;
  const _AttachmentGallery({required this.urls});

  static const String _base = 'http://localhost:8085';

  /// S'assure que l'URL est absolue
  String _abs(String url) =>
      url.startsWith('http') ? url : '$_base$url';

  bool _isImage(String url) {
    final ext = url.split('/').last.split('.').last.toLowerCase().split('?').first;
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext);
  }

  @override
  Widget build(BuildContext context) {
    final absUrls = urls.map(_abs).toList();
    final images = absUrls.where(_isImage).toList();
    final others = absUrls.where((u) => !_isImage(u)).toList();

    if (absUrls.isEmpty) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (images.isNotEmpty)
        SizedBox(
          height: images.length == 1 ? 180 : 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (ctx, i) => GestureDetector(
              onTap: () => _ouvrirApercu(ctx, images, i),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      images[i],
                      width: images.length == 1 ? 280 : 120,
                      height: images.length == 1 ? 180 : 120,
                      fit: BoxFit.cover,
                      headers: const {'Cache-Control': 'no-cache'},
                      loadingBuilder: (ctx, child, progress) => progress == null
                          ? child
                          : Container(
                              width: images.length == 1 ? 280 : 120,
                              height: images.length == 1 ? 180 : 120,
                              color: AppColors.surface,
                              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            ),
                      errorBuilder: (_, error, __) => Container(
                        width: images.length == 1 ? 280 : 120,
                        height: images.length == 1 ? 180 : 120,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.image_not_supported_outlined, color: AppColors.muted, size: 28),
                          const SizedBox(height: 4),
                          Text(images[i].split('/').last,
                              style: const TextStyle(fontSize: 10, color: AppColors.muted),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ]),
                      ),
                    ),
                  ),
                  // Indicateur zoom
                  Positioned(
                    bottom: 4, right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.zoom_in, size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      if (others.isNotEmpty) const SizedBox(height: 8),
      ...others.map((url) => _FileTile(url: url)),
    ]);
  }

  void _ouvrirApercu(BuildContext context, List<String> images, int index) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _ImagePreviewScreen(images: images, initialIndex: index),
    ));
  }
}

class _FileTile extends StatelessWidget {
  final String url;
  const _FileTile({required this.url});

  @override
  Widget build(BuildContext context) {
    final name = url.split('/').last;
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(url.startsWith('http') ? url : 'http://localhost:8085$url');
        if (await url_launcher.canLaunchUrl(uri)) {
          await url_launcher.launchUrl(uri, mode: url_launcher.LaunchMode.externalApplication);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          const Icon(Icons.attach_file, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(name,
              style: const TextStyle(fontSize: 13, color: AppColors.primary,
                  decoration: TextDecoration.underline, fontWeight: FontWeight.w500),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
          const Icon(Icons.open_in_new, size: 14, color: AppColors.primary),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// SCREEN : Aperçu image zoomable
// ═══════════════════════════════════════════════════════════════════
class _ImagePreviewScreen extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  const _ImagePreviewScreen({required this.images, required this.initialIndex});

  @override
  State<_ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<_ImagePreviewScreen> {
  late final PageController _pageCtrl;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _pageCtrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_current + 1} / ${widget.images.length}',
            style: const TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new, color: Colors.white),
            onPressed: () async {
              final uri = Uri.parse(widget.images[_current]);
              if (await url_launcher.canLaunchUrl(uri)) {
                await url_launcher.launchUrl(uri, mode: url_launcher.LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageCtrl,
        itemCount: widget.images.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (ctx, i) => InteractiveViewer(
          minScale: 0.5,
          maxScale: 5.0,
          child: Center(
            child: Image.network(widget.images[i],
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white, size: 64)),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// SHEET : Création d'un ticket
// ═══════════════════════════════════════════════════════════════════
class _CreateTicketSheet extends StatefulWidget {
  const _CreateTicketSheet();

  @override
  State<_CreateTicketSheet> createState() => _CreateTicketSheetState();
}

class _CreateTicketSheetState extends State<_CreateTicketSheet> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  TicketPriority _priority = TicketPriority.normale;
  List<PlatformFile> _selectedFiles = [];

  // Sélections dropdown
  Structure? _structureSelectionnee;
  Service? _serviceSelectionne;
  List<Structure> _structures = [];
  List<Service> _services = [];
  bool _loadingStructures = true;
  bool _loadingServices = false;

  @override
  void initState() {
    super.initState();
    _chargerStructures();
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _whatsappCtrl.dispose();
    super.dispose();
  }

  Future<void> _chargerStructures() async {
    try {
      // On déclenche le chargement via le BLoC ou directement via le service
      // Pour rester simple, on utilise un appel direct à l'ApiService
      final bloc = context.read<TicketBloc>();
      bloc.add(LoadStructures());
    } catch (_) {}
  }

  Future<void> _chargerServices(int structureId) async {
    setState(() { _loadingServices = true; _services = []; _serviceSelectionne = null; });
    try {
      context.read<TicketBloc>().add(LoadServices(structureId));
    } catch (_) {
      setState(() => _loadingServices = false);
    }
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image, // Images uniquement pour les captures
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        // Évite les doublons
        final noms = _selectedFiles.map((f) => f.name).toSet();
        for (final f in result.files) {
          if (!noms.contains(f.name)) _selectedFiles.add(f);
        }
      });
    }
  }

  void _removeFile(int index) => setState(() => _selectedFiles.removeAt(index));

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<TicketBloc>().add(
        CreateTicket(
          description: _descCtrl.text.trim(),
          structure: _structureSelectionnee?.nom ?? '',
          priority: _priority,
          attachments: _selectedFiles,
          whatsapp: _whatsappCtrl.text.trim().isEmpty ? null : _whatsappCtrl.text.trim(),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TicketBloc, TicketState>(
      listener: (ctx, state) {
        if (state is StructuresLoaded) {
          setState(() { _structures = state.structures; _loadingStructures = false; });
        }
        if (state is ServicesLoaded) {
          setState(() { _services = state.services; _loadingServices = false; });
        }
      },
      child: Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre + poignée
                Center(child: Container(width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4)))),
                const SizedBox(height: 12),
                const Text('Nouveau ticket',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                // ── Description ────────────────────────────────────────
                TextFormField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Description / Problème',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Champ requis' : null,
                ),
                const SizedBox(height: 12),

                // ── Structure (dropdown depuis BDD) ────────────────────
                _loadingStructures
                    ? const Center(child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: CircularProgressIndicator(strokeWidth: 2)))
                    : DropdownButtonFormField<Structure>(
                        value: _structureSelectionnee,
                        isExpanded: true,
                        menuMaxHeight: 200,
                        decoration: const InputDecoration(
                          labelText: 'Structure',
                          prefixIcon: Icon(Icons.business_outlined, size: 18),
                        ),
                        items: _structures.map((s) => DropdownMenuItem<Structure>(
                            value: s, child: Text(s.nom, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (val) {
                          setState(() => _structureSelectionnee = val);
                          if (val?.id != null) _chargerServices(val!.id!);
                        },
                        validator: (v) => v == null ? 'Sélectionnez une structure' : null,
                      ),
                const SizedBox(height: 12),

                // ── Service (dropdown selon structure) ─────────────────
                if (_structureSelectionnee != null)
                  _loadingServices
                      ? const Center(child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: CircularProgressIndicator(strokeWidth: 2)))
                      : DropdownButtonFormField<Service>(
                          value: _serviceSelectionne,
                          isExpanded: true,
                          menuMaxHeight: 200,
                          decoration: const InputDecoration(
                            labelText: 'Service concerné',
                            prefixIcon: Icon(Icons.layers_outlined, size: 18),
                          ),
                          items: _services.map((s) => DropdownMenuItem<Service>(
                              value: s, child: Text(s.nom, overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (val) => setState(() => _serviceSelectionne = val),
                          validator: (v) => v == null ? 'Sélectionnez un service' : null,
                        ),
                if (_structureSelectionnee != null) const SizedBox(height: 12),

                // ── Priorité ───────────────────────────────────────────
                DropdownButtonFormField<TicketPriority>(
                  value: _priority,
                  isExpanded: true,
                  menuMaxHeight: 200,
                  decoration: const InputDecoration(
                    labelText: 'Priorité',
                    prefixIcon: Icon(Icons.flag_outlined, size: 18),
                  ),
                  items: TicketPriority.values.map((p) =>
                      DropdownMenuItem(value: p, child: Text(p.name.toUpperCase()))).toList(),
                  onChanged: (val) => setState(() => _priority = val!),
                ),
                const SizedBox(height: 12),

                // ── Contact WhatsApp ───────────────────────────────────
                TextFormField(
                  controller: _whatsappCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Contact WhatsApp (ex: +22670000000)',
                    prefixIcon: Icon(Icons.chat_bubble_outline, size: 18, color: Color(0xFF25D366)),
                    hintText: '+226XXXXXXXX',
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),

                // ── Pièces jointes multiples ────────────────────────────
                Row(children: [
                  const Text('Captures / images', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _pickFiles,
                    icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                    label: const Text('Ajouter', style: TextStyle(fontSize: 12)),
                  ),
                ]),

                if (_selectedFiles.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedFiles.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (ctx, i) {
                        final f = _selectedFiles[i];
                        return Stack(
                          children: [
                            GestureDetector(
                              onTap: () => _ouvrirApercuLocal(ctx, i),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: f.bytes != null
                                    ? Image.memory(f.bytes!, width: 100, height: 100, fit: BoxFit.cover)
                                    : Container(width: 100, height: 100, color: AppColors.surface,
                                        child: const Icon(Icons.image, color: AppColors.muted)),
                              ),
                            ),
                            // Bouton supprimer
                            Positioned(
                              top: 2, right: 2,
                              child: GestureDetector(
                                onTap: () => _removeFile(i),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.all(3),
                                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('${_selectedFiles.length} fichier(s) sélectionné(s)',
                      style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                ],

                const SizedBox(height: 20),

                // ── Bouton soumettre ───────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 7, 68, 35),
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text('Soumettre', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _ouvrirApercuLocal(BuildContext context, int index) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _LocalImagePreviewScreen(
        files: _selectedFiles, initialIndex: index),
    ));
  }
}

// ═══════════════════════════════════════════════════════════════════
// SCREEN : Aperçu local des images sélectionnées (avant envoi)
// ═══════════════════════════════════════════════════════════════════
class _LocalImagePreviewScreen extends StatefulWidget {
  final List<PlatformFile> files;
  final int initialIndex;
  const _LocalImagePreviewScreen({required this.files, required this.initialIndex});

  @override
  State<_LocalImagePreviewScreen> createState() => _LocalImagePreviewScreenState();
}

class _LocalImagePreviewScreenState extends State<_LocalImagePreviewScreen> {
  late int _current;
  late final PageController _ctrl;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _ctrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${widget.files[_current].name}  (${_current + 1}/${widget.files.length})',
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
      ),
      body: PageView.builder(
        controller: _ctrl,
        itemCount: widget.files.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (ctx, i) {
          final bytes = widget.files[i].bytes;
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 5.0,
            child: Center(
              child: bytes != null
                  ? Image.memory(bytes, fit: BoxFit.contain)
                  : const Icon(Icons.broken_image, color: Colors.white, size: 64),
            ),
          );
        },
      ),
    );
  }
}