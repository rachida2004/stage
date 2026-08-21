import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widget/shared_widget.dart';
import '../bloc/all_blocs.dart';
import '../services/services.dart';
import '../services/storage_service.dart';
import '../core/api_constants.dart';

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

  // 🎯 Le TicketBloc est PARTAGÉ avec l'écran de détail (changement de
  // statut, affectation, messages...). Ouvrir un ticket émet des états
  // (TicketDetailL, TicketLoading, TicketError...) sur ce même bloc, et
  // cet écran liste — gardé vivant en mémoire par l'IndexedStack — se
  // reconstruit à CHAQUE fois, même s'il n'est pas affiché. Sans ce cache,
  // on perdait la liste ("Aucun ticket trouvé") dès qu'on ouvrait un
  // ticket, pas seulement en y revenant. Même correctif que celui déjà
  // appliqué à AdminBloc via _lastKnownUsers.
  List<Ticket> _lastKnownTickets = [];

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
    return BlocConsumer<TicketBloc, TicketState>(
      // 🎯 Une erreur venant d'une action sur l'écran détail (ex. affectation
      // refusée) ne doit pas casser l'écran liste en plein écran d'erreur
      // s'il affiche déjà des tickets — juste un avertissement discret.
      listener: (context, state) {
        if (state is TicketError && _lastKnownTickets.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.msg), backgroundColor: AppColors.danger),
          );
        }
      },
      builder: (context, state) {
        bool isLoading = state is TicketLoading;

        if (state is TicketsLoaded) {
          _lastKnownTickets = state.page.items;
        } else if (state is TicketError && _lastKnownTickets.isEmpty) {
          // 🎯 Écran d'erreur plein écran uniquement si on n'a encore AUCUNE
          // donnée à afficher (échec du tout premier chargement) — sinon la
          // liste déjà connue reste visible (cf. listener ci-dessus).
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
        // 🎯 Pour tout autre état (TicketDetailL, TicketSuccess,
        // TicketDeletedSuccess, TicketInitial...) émis pendant que cet écran
        // liste est en arrière-plan, on continue d'afficher la dernière
        // liste connue au lieu de la vider.
        final allTickets = _lastKnownTickets;

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
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // 🎯 Grille de cartes carrées : 2 colonnes en mobile,
                          // davantage sur les écrans larges (web/tablette).
                          final int colonnes = (constraints.maxWidth / 220).floor().clamp(2, 4);
                          return GridView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                            itemCount: filtered.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: colonnes,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.92, // légèrement plus haute que large : reste "carrée"
                            ),
                            itemBuilder: (ctx, i) => _TicketCard(
                              ticket: filtered[i],
                              // 🎯 On recharge systématiquement la liste au retour de
                              // l'écran détail (Navigator.pop), qu'un changement ait
                              // eu lieu ou non — changement de statut, affectation,
                              // modification, message, tout ça se passe dans le
                              // détail sans jamais mettre à jour la liste sous-jacente
                              // tant qu'on ne revient pas dessus.
                              onTap: () => Navigator.push(ctx,
                                MaterialPageRoute(builder: (_) => TicketDetailScreen(ticket: filtered[i])))
                                  .then((_) {
                                if (ctx.mounted) ctx.read<TicketBloc>().add(LoadTickets());
                              }),
                            ),
                          );
                        },
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

  Color get _couleurPriorite {
    switch (ticket.priority) {
      case TicketPriority.haute: return AppColors.danger;
      case TicketPriority.normale: return AppColors.warning;
      case TicketPriority.basse: return const Color.fromARGB(255, 42, 157, 0);
    }
  }

  // 🎯 Petit formatage de date relative "maison" (pas de dépendance intl
  // supplémentaire, le projet ne l'utilise pas ailleurs).
  String get _dateRelative {
    final diff = DateTime.now().difference(ticket.createdAt);
    if (diff.inMinutes < 1) return "À l'instant";
    if (diff.inHours < 1) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours} h';
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return '${diff.inDays} j';
    return '${ticket.createdAt.day.toString().padLeft(2, '0')}/${ticket.createdAt.month.toString().padLeft(2, '0')}';
  }

  // 🎯 Au niveau de la structure "DSI", on affiche le vrai logo (asset déjà
  // utilisé pour l'en-tête des lettres officielles) plutôt qu'une icône
  // générique de bâtiment, pour un rendu plus institutionnel.
  bool get _estDsi => ticket.structure.toLowerCase().contains('dsi');

  @override
  Widget build(BuildContext context) {
    final couleur = _couleurPriorite;
    final bool nonAffecte = ticket.agentAssigneNom == null;
    final int nbMessages = ticket.messages.length;
    final int nbPieces = ticket.attachments.length;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7EBF0)),
        boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 3))],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Bandeau coloré selon la priorité (en tête, format carré) ──
            Container(height: 4, color: couleur),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── En-tête : logo/structure + statut ─────────────────
                    Row(
                      children: [
                        _estDsi
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset('assets/images/logo.jpg',
                                    width: 28, height: 28, fit: BoxFit.cover),
                              )
                            : Container(
                                width: 28, height: 28,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: couleur.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.apartment_outlined, size: 15, color: couleur),
                              ),
                        const Spacer(),
                        StatusBadge.fromTicketStatus(ticket.status),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // ── N° + description (occupe l'espace disponible) ────
                    Text('N°${ticket.id}',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: couleur)),
                    const SizedBox(height: 2),
                    Expanded(
                      child: Text(
                        ticket.description,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.25),
                        maxLines: 3, overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // ── Priorité ────────────────────────────────────────
                    PriorityBadge(priority: ticket.priority),
                    const SizedBox(height: 6),

                    // ── Agent affecté ─────────────────────────────────────
                    Row(
                      children: [
                        Icon(nonAffecte ? Icons.person_off_outlined : Icons.person_outline,
                            size: 12, color: nonAffecte ? AppColors.warning : AppColors.muted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            nonAffecte ? 'Non affecté' : ticket.agentAssigneNom!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: nonAffecte ? FontWeight.w600 : FontWeight.normal,
                              color: nonAffecte ? AppColors.warning : AppColors.muted,
                            ),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(height: 1, color: const Color(0xFFF0F2F5)),
                    const SizedBox(height: 4),

                    // ── Pied : date + compteurs ────────────────────────
                    Row(
                      children: [
                        const Icon(Icons.schedule_outlined, size: 11, color: AppColors.muted),
                        const SizedBox(width: 3),
                        Text(_dateRelative, style: const TextStyle(fontSize: 10.5, color: AppColors.muted)),
                        const Spacer(),
                        if (nbMessages > 0) ...[
                          const Icon(Icons.chat_bubble_outline, size: 12, color: AppColors.muted),
                          const SizedBox(width: 2),
                          Text('$nbMessages', style: const TextStyle(fontSize: 10.5, color: AppColors.muted)),
                          const SizedBox(width: 8),
                        ],
                        if (nbPieces > 0) ...[
                          const Icon(Icons.attach_file, size: 12, color: AppColors.muted),
                          const SizedBox(width: 2),
                          Text('$nbPieces', style: const TextStyle(fontSize: 10.5, color: AppColors.muted)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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

  // 🎯 Modification d'un ticket par son créateur (typiquement un USAGER qui
  // corrige une erreur : texte ou image envoyée par erreur). Permet de
  // retirer d'anciennes pièces jointes et d'en ajouter de nouvelles.
  void _ouvrirEditionTicket(BuildContext context, Ticket t) {
    final descCtrl = TextEditingController(text: t.description);
    final removedIds = <int>{};
    final nouveauxFichiers = <PlatformFile>[];
    final ticketBloc = context.read<TicketBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Modifier le ticket'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                  controller: descCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                // Pièces jointes existantes — chacune peut être retirée
                // (ex: mauvaise image envoyée par erreur).
                if (t.attachmentsDetail.isNotEmpty) ...[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Pièces jointes actuelles', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: t.attachmentsDetail.where((a) => !removedIds.contains(a.id)).map((a) {
                      return Chip(
                        label: Text('PJ #${a.id}', style: const TextStyle(fontSize: 11)),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => setDialogState(() => removedIds.add(a.id)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                // Nouvelles pièces jointes à ajouter
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(
                        allowMultiple: true,
                        type: FileType.image,
                        withData: true,
                      );
                      if (result != null) {
                        setDialogState(() => nouveauxFichiers.addAll(result.files));
                      }
                    },
                    icon: const Icon(Icons.attach_file, size: 16),
                    label: const Text('Ajouter une image', style: TextStyle(fontSize: 12)),
                  ),
                ),
                if (nouveauxFichiers.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: nouveauxFichiers.map((f) => Chip(
                        label: Text(f.name, style: const TextStyle(fontSize: 11)),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => setDialogState(() => nouveauxFichiers.remove(f)),
                      )).toList(),
                    ),
                  ),
              ]),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                ticketBloc.add(UpdateTicket(
                  t.id,
                  description: descCtrl.text.trim(),
                  newFiles: nouveauxFichiers,
                  removeAttachmentIds: removedIds.toList(),
                ));
                Navigator.pop(dialogContext);
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }


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
                style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 8, 65, 29)),
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
    // 🎯 La priorité du ticket est désormais précisée ici, par le
    // secrétaire ou l'admin, au moment de l'affectation — plus par l'usager
    // à la création.
    TicketPriority prioriteSelectionnee = TicketPriority.normale;
    List<AppUser> agentsDSI = [];
    bool loading = true;

    // 🎯 On charge directement les AGENT_DSI via getAgentsDSI() au lieu
    // de passer par AdminBloc (qui renverrait tous les utilisateurs).
    sl<AdminService>().getAgentsDSI().then((liste) {
      agentsDSI = liste;
      loading = false;
    }).catchError((_) => loading = false);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            // Déclenche le rechargement de l'UI quand les agents arrivent
            if (loading) {
              sl<AdminService>().getAgentsDSI().then((liste) {
                if (dialogContext.mounted) {
                  setDialogState(() { agentsDSI = liste; loading = false; });
                }
              }).catchError((_) {
                if (dialogContext.mounted) setDialogState(() => loading = false);
              });
            }

            return AlertDialog(
              title: const Text("Affecter un agent DSI au ticket"),
              content: loading
                  ? const SizedBox(height: 60, child: Center(child: CircularProgressIndicator()))
                  : agentsDSI.isEmpty
                      ? const Text("Aucun agent DSI disponible.")
                      : Column(mainAxisSize: MainAxisSize.min, children: [
                          DropdownButtonFormField<AppUser>(
                            decoration: const InputDecoration(
                              labelText: "Agent DSI",
                              border: OutlineInputBorder(),
                            ),
                            isExpanded: true,
                            menuMaxHeight: 250,
                            value: agentSelectionne,
                            items: agentsDSI
                                .map((u) => DropdownMenuItem<AppUser>(
                                      value: u,
                                      child: Text(
                                        '${u.nom} ${u.prenom ?? ''}'.trim(),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ))
                                .toList(),
                            onChanged: (val) => setDialogState(() => agentSelectionne = val),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<TicketPriority>(
                            decoration: const InputDecoration(
                              labelText: "Priorité",
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.flag_outlined, size: 18),
                            ),
                            isExpanded: true,
                            value: prioriteSelectionnee,
                            items: TicketPriority.values
                                .map((p) => DropdownMenuItem(value: p, child: Text(p.name.toUpperCase())))
                                .toList(),
                            onChanged: (val) => setDialogState(() => prioriteSelectionnee = val!),
                          ),
                        ]),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Annuler")),
                ElevatedButton(
                  onPressed: agentSelectionne == null ? null : () {
                    context.read<TicketBloc>().add(
                        AffecterAgentTkt(ticketId, agentSelectionne!.id.toString(),
                            priorite: prioriteSelectionnee));
                    Navigator.pop(dialogContext);
                  },
                  child: const Text("Affecter"),
                ),
              ],
            );
          },
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
            const SnackBar(content: Text('Ticket supprimé avec succès', style: TextStyle(color: Color.fromARGB(255, 164, 189, 179), fontWeight: FontWeight.w500)), backgroundColor: Color.fromARGB(255, 1, 61, 23), duration: Duration(seconds: 2))
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
              appBar: AppBar(title: Text('N°${widget.ticket.id}')),
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
              title: Text('N°${t.id}', style: const TextStyle(fontSize: 15)),
              actions: [
                // Bouton WhatsApp dans l'AppBar si numéro disponible
                // 🎯 L'usager ne doit pas voir le lien WhatsApp (réservé au
                // personnel DSI qui a besoin de contacter l'usager, pas
                // l'inverse).
                if (whatsapp != null && whatsapp.isNotEmpty)
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (_, authState) {
                      final role = authState is AuthOk ? authState.role : '';
                      if (role == 'USAGER') return const SizedBox.shrink();
                      return IconButton(
                        icon: const Icon(Icons.chat, color: Color.fromARGB(255, 3, 50, 20)),
                        tooltip: 'Contacter sur WhatsApp',
                        onPressed: () => _ouvrirWhatsApp(context, whatsapp),
                      );
                    },
                  ),
                // 🎯 Actions selon le rôle :
                // USAGER      → peut modifier/supprimer SON PROPRE ticket
                //               tant qu'il n'est pas résolu/fermé (icône
                //               crayon ici ; bouton Modifier/Supprimer
                //               dupliqués en bas de page pour visibilité)
                // SECRETAIRE  → peut affecter un agent uniquement
                // Autres      → menu complet (résolu, fermer, supprimer) —
                //               PLUS D'OPTION "Mettre en pause" : un ticket
                //               affecté reste "En cours" jusqu'à résolution.
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (_, authState) {
                    final role = authState is AuthOk ? authState.role : '';
                    if (role == 'USAGER') {
                      final estProprietaire = t.createur != null &&
                          t.createur!.id == sl<StorageService>().cachedUserId;
                      final modifiable = t.status != TicketStatus.resolu && t.status != TicketStatus.ferme;
                      if (!estProprietaire || !modifiable) return const SizedBox.shrink();
                      return IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Modifier mon ticket',
                        onPressed: () => _ouvrirEditionTicket(context, t),
                      );
                    }

                    if (role == 'SECRETAIRE') {
                      return IconButton(
                        icon: const Icon(Icons.person_add_outlined),
                        tooltip: 'Affecter un agent',
                        onPressed: () => _ouvrirDialogueAffectation(context, t.id),
                      );
                    }

                    // 🎯 "Affecter un agent" réservé à ADMIN et SECRETAIRE.
                    // SECRETAIRE l'a déjà via son propre bouton ci-dessus ;
                    // ici on l'ajoute uniquement pour ADMIN (les autres rôles,
                    // ex. AGENT_DSI/SUPERVISEUR, gardent le reste du menu
                    // mais pas l'affectation).
                    return PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'assign') _ouvrirDialogueAffectation(context, t.id);
                        else if (v == 'resolve') _demanderSolutionEtResoudre(context, t.id);
                        else if (v == 'close') context.read<TicketBloc>().add(UpdateStatut(t.id, TicketStatus.ferme));
                        else if (v == 'delete') _showDeleteConfirmationDialog(context, t.id);
                      },
                      itemBuilder: (_) {
                        // 🎯 Suppression réservée à ADMIN ou à l'agent affecté
                        // à CE ticket précis (pas n'importe quel agent).
                        final peutSupprimer = role == 'ADMIN' ||
                            (t.agentAssigne != null && t.agentAssigne!.id == sl<StorageService>().cachedUserId);
                        return [
                          if (role == 'ADMIN')
                            const PopupMenuItem(value: 'assign', child: Text('Affecter un agent')),
                          const PopupMenuItem(value: 'resolve', child: Text('Marquer résolu')),
                          const PopupMenuItem(value: 'close', child: Text('Fermer le ticket')),
                          if (peutSupprimer) ...[
                            const PopupMenuDivider(),
                            const PopupMenuItem(value: 'delete', child: Text('Supprimer', style: TextStyle(color: Colors.red))),
                          ],
                        ];
                      },
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
                      // 🎯 Même logique que sur les cartes de la liste : le
                      // logo institutionnel remplace l'icône générique quand
                      // la structure concernée est la DSI.
                      t.structure.toLowerCase().contains('dsi')
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.asset('assets/images/logo.jpg', width: 16, height: 16, fit: BoxFit.cover),
                            )
                          : const Icon(Icons.business_outlined, size: 14, color: AppColors.muted),
                      const SizedBox(width: 4),
                      Flexible(child: Text(t.structure, style: const TextStyle(fontSize: 12, color: AppColors.muted), overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 12),
                      const Icon(Icons.person_outline, size: 14, color: AppColors.muted),
                      const SizedBox(width: 4),
                      Flexible(child: Text(t.agentAssigneNom ?? 'Non affecté',
                          style: const TextStyle(fontSize: 12, color: AppColors.muted), overflow: TextOverflow.ellipsis)),
                    ]),

                    // ── Contact WhatsApp ────────────────────────────────
                    // 🎯 L'usager ne doit pas voir le lien WhatsApp.
                    if (whatsapp != null && whatsapp.isNotEmpty)
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (_, authState) {
                          final role = authState is AuthOk ? authState.role : '';
                          if (role == 'USAGER') return const SizedBox.shrink();
                          return Column(children: [
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
                          ]);
                        },
                      ),

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
                          color: const Color.fromARGB(255, 2, 58, 22),
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

                    // ── Boutons d'action bas de page ────────────────────
                    // USAGER : pas de gestion du cycle de vie (résolu/fermé),
                    // mais peut modifier/supprimer SON PROPRE ticket tant
                    // qu'il n'est pas résolu/fermé.
                    // SECRETAIRE : ne gère pas non plus le cycle de vie.
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (_, authState) {
                        final role = authState is AuthOk ? authState.role : '';

                        if (role == 'USAGER') {
                          final estProprietaire = t.createur != null &&
                              t.createur!.id == sl<StorageService>().cachedUserId;
                          final modifiable = t.status != TicketStatus.resolu && t.status != TicketStatus.ferme;
                          if (!estProprietaire || !modifiable) return const SizedBox.shrink();
                          return Row(children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _ouvrirEditionTicket(context, t),
                                icon: const Icon(Icons.edit_outlined, size: 16),
                                label: const Text('Modifier', style: TextStyle(fontSize: 12)),
                                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _showDeleteConfirmationDialog(context, t.id),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red, width: 1.0),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                                icon: const Icon(Icons.delete_outline, size: 16),
                                label: const Text('Supprimer', style: TextStyle(fontSize: 12)),
                              ),
                            ),
                          ]);
                        }

                        if (role == 'SECRETAIRE') return const SizedBox.shrink();

                        // 🎯 Suppression réservée à ADMIN ou à l'agent affecté
                        // à CE ticket précis (pas n'importe quel agent).
                        final peutSupprimer = role == 'ADMIN' ||
                            (t.agentAssigne != null && t.agentAssigne!.id == sl<StorageService>().cachedUserId);

                        return Column(children: [
                          // 🎯 Plus d'état "En pause" : un ticket affecté reste
                          // "En cours" jusqu'à sa résolution.
                          ElevatedButton(
                            onPressed: () => _demanderSolutionEtResoudre(context, t.id),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                padding: const EdgeInsets.symmetric(vertical: 10)),
                            child: const Text('Marquer résolu', style: TextStyle(fontSize: 12, color: Colors.white)),
                          ),
                          if (peutSupprimer) ...[
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
                          ],
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

  static String get _base => ApiConstants.baseUrl;

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
        final uri = Uri.parse(url.startsWith('http') ? url : '${ApiConstants.baseUrl}$url');
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

  // 🎯 Structure/service de l'utilisateur connecté, pour préremplissage
  // automatique dès que les listes correspondantes sont chargées.
  String? _structureNomUtilisateur;
  String? _serviceNomUtilisateur;

  @override
  void initState() {
    super.initState();
    _chargerStructures();
    _chargerProfilUtilisateur();
  }

  Future<void> _chargerProfilUtilisateur() async {
    try {
      final profil = await sl<AuthService>().monProfil();
      _structureNomUtilisateur = profil['structure']?.toString();
      _serviceNomUtilisateur = profil['service']?.toString();
      final telephone = profil['telephone']?.toString();
      if (telephone != null && telephone.isNotEmpty && _whatsappCtrl.text.isEmpty) {
        _whatsappCtrl.text = telephone;
      }
      _tenterPreremplissageStructure();
    } catch (_) {
      // Si la récupération du profil échoue, l'usager choisit simplement
      // manuellement — ce n'est pas bloquant pour créer un ticket.
    }
  }

  void _tenterPreremplissageStructure() {
    if (_structureSelectionnee != null || _structureNomUtilisateur == null || _structures.isEmpty) return;
    Structure? match;
    for (final s in _structures) {
      if (s.nom == _structureNomUtilisateur) { match = s; break; }
    }
    if (match != null && match.id != null) {
      setState(() => _structureSelectionnee = match);
      _chargerServices(match.id!);
    }
  }

  void _tenterPreremplissageService() {
    if (_serviceSelectionne != null || _serviceNomUtilisateur == null || _services.isEmpty) return;
    Service? match;
    for (final s in _services) {
      if (s.nom == _serviceNomUtilisateur) { match = s; break; }
    }
    if (match != null) setState(() => _serviceSelectionne = match);
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _whatsappCtrl.dispose();
    super.dispose();
  }

  Future<void> _chargerStructures() async {
    // 🎯 Appel direct à l'API plutôt que de passer par le TicketBloc partagé :
    // ce Bloc peut déjà contenir un état StructuresLoaded d'un chargement
    // précédent (ex: visite de l'onglet Tickets), auquel cas redéclencher
    // LoadStructures() ne réémet PAS d'état "nouveau" (Equatable considère
    // la même liste comme un état égal) — le BlocListener ne se redéclenche
    // alors jamais, et ce formulaire reste bloqué avec une liste vide.
    try {
      final structures = await sl<TicketService>().getStructures();
      if (!mounted) return;
      setState(() { _structures = structures; _loadingStructures = false; });
      _tenterPreremplissageStructure();
    } catch (_) {
      if (mounted) setState(() => _loadingStructures = false);
    }
  }

  Future<void> _chargerServices(int structureId) async {
    setState(() { _loadingServices = true; _services = []; _serviceSelectionne = null; });
    try {
      final services = await sl<TicketService>().getServices(structureId: structureId);
      if (!mounted) return;
      setState(() { _services = services; _loadingServices = false; });
      _tenterPreremplissageService();
    } catch (_) {
      if (mounted) setState(() => _loadingServices = false);
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

  // ── Champ "Structure" avec recherche par saisie ──────────────────
  //
  // 🎯 La `key` inclut l'id de la structure sélectionnée : quand elle
  // change (sélection manuelle OU préremplissage automatique depuis le
  // profil utilisateur), Flutter recrée le widget Autocomplete avec le
  // bon `initialValue` au lieu de garder l'ancien texte affiché.
  Widget _buildStructureAutocomplete() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Autocomplete<Structure>(
          key: ValueKey('structure-${_structureSelectionnee?.id}'),
          initialValue: TextEditingValue(text: _structureSelectionnee?.nom ?? ''),
          displayStringForOption: (s) => s.nom,
          optionsBuilder: (TextEditingValue value) {
            final query = value.text.trim().toLowerCase();
            if (query.isEmpty) return _structures;
            return _structures.where((s) => s.nom.toLowerCase().contains(query));
          },
          onSelected: (s) {
            setState(() => _structureSelectionnee = s);
            if (s.id != null) _chargerServices(s.id!);
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              decoration: const InputDecoration(
                labelText: 'Structure',
                hintText: 'Tapez pour rechercher...',
                prefixIcon: Icon(Icons.business_outlined, size: 18),
              ),
              validator: (_) => _structureSelectionnee == null ? 'Sélectionnez une structure' : null,
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                color: Colors.white,
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 220, maxWidth: constraints.maxWidth),
                  child: options.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text('Aucune structure trouvée', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (context, index) {
                            final s = options.elementAt(index);
                            return ListTile(
                              dense: true,
                              title: Text(
                                s.nom,
                                style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500),
                              ),
                              onTap: () => onSelected(s),
                            );
                          },
                        ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Champ "Service" avec recherche par saisie ────────────────────
  //
  // Filtré par _services (déjà limité à la structure choisie via
  // _chargerServices). La key inclut structure + service pour forcer
  // la recréation du champ quand la structure change (reset du texte).
  Widget _buildServiceAutocomplete() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Autocomplete<Service>(
          key: ValueKey('service-${_structureSelectionnee?.id}-${_serviceSelectionne?.id}'),
          initialValue: TextEditingValue(text: _serviceSelectionne?.nom ?? ''),
          displayStringForOption: (s) => s.nom,
          optionsBuilder: (TextEditingValue value) {
            final query = value.text.trim().toLowerCase();
            if (query.isEmpty) return _services;
            return _services.where((s) => s.nom.toLowerCase().contains(query));
          },
          onSelected: (s) => setState(() => _serviceSelectionne = s),
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              decoration: const InputDecoration(
                labelText: 'Service concerné',
                hintText: 'Tapez pour rechercher...',
                prefixIcon: Icon(Icons.layers_outlined, size: 18),
              ),
              validator: (_) => _serviceSelectionne == null ? 'Sélectionnez un service' : null,
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                color: Colors.white,
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 220, maxWidth: constraints.maxWidth),
                  child: options.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text('Aucun service trouvé', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (context, index) {
                            final s = options.elementAt(index);
                            return ListTile(
                              dense: true,
                              title: Text(
                                s.nom,
                                style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500),
                              ),
                              onTap: () => onSelected(s),
                            );
                          },
                        ),
                ),
              ),
            );
          },
        );
      },
    );
  }

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
          _tenterPreremplissageStructure();
        }
        if (state is ServicesLoaded) {
          setState(() { _services = state.services; _loadingServices = false; });
          _tenterPreremplissageService();
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

                // ── Structure (recherche par saisie) ───────────────────
                _loadingStructures
                    ? const Center(child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: CircularProgressIndicator(strokeWidth: 2)))
                    : _buildStructureAutocomplete(),
                const SizedBox(height: 12),

                // ── Service (recherche par saisie, filtré par structure) ─
                if (_structureSelectionnee != null)
                  _loadingServices
                      ? const Center(child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: CircularProgressIndicator(strokeWidth: 2)))
                      : _buildServiceAutocomplete(),
                if (_structureSelectionnee != null) const SizedBox(height: 12),

                // 🎯 La priorité n'est plus fixée à la création par l'usager :
                // elle est désormais précisée par le secrétaire ou l'admin
                // au moment de l'affectation d'un agent (voir
                // _ouvrirDialogueAffectation ci-dessous). Le ticket est créé
                // avec la priorité par défaut (_priority = normale).

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