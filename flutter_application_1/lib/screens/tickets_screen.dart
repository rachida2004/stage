import 'dart:async';
import 'dart:math' as math;
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

enum _Groupement { aucun, annee, mois, jour }

class _TicketsScreenState extends State<TicketsScreen> {
  String _search = '';
  TicketStatus? _filterStatus;
  // 🎯 Pagination côté client, même logique que sur l'écran Invitations.
  int _currentPage = 0;
  static const int _itemsPerPage = 10;
  _Groupement _groupement = _Groupement.aucun;

  static const _moisFr = [
    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
  ];

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

  // 🎯 Regroupe les tickets déjà filtrés en sections (année, mois ou jour),
  // triées de la période la plus récente à la plus ancienne. Utilisé
  // uniquement quand un classement est sélectionné (sinon liste à plat).
  List<MapEntry<String, List<Ticket>>> _grouperTickets(List<Ticket> tickets) {
    final Map<String, List<Ticket>> groupes = {};
    final Map<String, DateTime> cleVersDate = {};

    for (final t in tickets) {
      final d = t.createdAt;
      late final String cle;
      late final DateTime dateRepere;
      switch (_groupement) {
        case _Groupement.annee:
          cle = '${d.year}';
          dateRepere = DateTime(d.year);
          break;
        case _Groupement.mois:
          cle = '${_moisFr[d.month - 1]} ${d.year}';
          dateRepere = DateTime(d.year, d.month);
          break;
        case _Groupement.jour:
          cle = '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
          dateRepere = DateTime(d.year, d.month, d.day);
          break;
        case _Groupement.aucun:
          cle = '';
          dateRepere = d;
          break;
      }
      groupes.putIfAbsent(cle, () => []).add(t);
      cleVersDate[cle] = dateRepere;
    }

    final entrees = groupes.entries.toList()
      ..sort((a, b) => cleVersDate[b.key]!.compareTo(cleVersDate[a.key]!));
    return entrees;
  }

  String _libelleGroupement(_Groupement g) {
    switch (g) {
      case _Groupement.aucun: return 'Aucun classement';
      case _Groupement.annee: return 'Par année';
      case _Groupement.mois: return 'Par mois';
      case _Groupement.jour: return 'Par jour';
    }
  }

  // 🎯 Factorisé : utilisé à la fois par la grille à plat et par les
  // sections groupées, pour ne pas dupliquer la logique de navigation
  // + rechargement au retour.
  Widget _ticketTile(BuildContext ctx, Ticket ticket) {
    return TicketCard(
      ticket: ticket,
      onTap: () => Navigator.push(ctx,
        MaterialPageRoute(builder: (_) => TicketDetailScreen(ticket: ticket)))
          .then((_) {
        if (ctx.mounted) ctx.read<TicketBloc>().add(LoadTickets());
      }),
    );
  }

  // 🎯 Vue groupée : une section par période (année/mois/jour), la plus
  // récente en premier, chacune avec son propre mini-grille de cartes.
  Widget _buildGroupedList(BuildContext context, List<Ticket> tickets) {
    final groupes = _grouperTickets(tickets);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: groupes.length,
      itemBuilder: (context, i) {
        final entree = groupes[i];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 10),
              child: Row(children: [
                Container(
                  width: 4, height: 16,
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 8),
                Text(entree.key, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Colors.black87)),
                const SizedBox(width: 8),
                Text('(${entree.value.length})', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ]),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entree.value.length,
              // 🎯 Cartes compactes, taille fixe (au lieu d'un ratio calculé sur
              // le nombre de colonnes) : le nombre de colonnes s'adapte tout
              // seul à la largeur (2 sur mobile, davantage sur web/tablette).
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 230,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent: 252,
              ),
              itemBuilder: (ctx, j) => _ticketTile(ctx, entree.value[j]),
            ),
          ],
        );
      },
    );
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
                  onChanged: (v) => setState(() { _search = v; _currentPage = 0; }),
                ),
                const SizedBox(height: 10),
                // ── Filtres : statut + classement par période (dropdowns) ──
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<TicketStatus?>(
                          value: _filterStatus,
                          icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: AppColors.muted),
                          style: const TextStyle(fontSize: 13.5, color: Colors.black87, fontWeight: FontWeight.w600),
                          items: [
                            const DropdownMenuItem<TicketStatus?>(
                              value: null,
                              child: Text('Tous les statuts'),
                            ),
                            ...TicketStatus.values.map((s) => DropdownMenuItem<TicketStatus?>(
                                  value: s,
                                  child: Text(s.label),
                                )),
                          ],
                          onChanged: (s) => setState(() { _filterStatus = s; _currentPage = 0; }),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<_Groupement>(
                          value: _groupement,
                          icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: AppColors.muted),
                          style: const TextStyle(fontSize: 13.5, color: Colors.black87, fontWeight: FontWeight.w600),
                          items: [
                            for (final g in _Groupement.values)
                              DropdownMenuItem<_Groupement>(
                                value: g,
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  const Icon(Icons.calendar_today_outlined, size: 15, color: AppColors.muted),
                                  const SizedBox(width: 6),
                                  Text(_libelleGroupement(g)),
                                ]),
                              ),
                          ],
                          onChanged: (g) => setState(() { _groupement = g ?? _Groupement.aucun; _currentPage = 0; }),
                        ),
                      ),
                    ),
                  ],
                ),
              ]),
            ),
            const SizedBox(height: 8),
            // 🎯 Pagination : uniquement sur la vue grille "sans groupement"
            // — avec un groupement par période, les en-têtes de section ne
            // se prêtent pas à un découpage par page fixe.
            Builder(builder: (context) {
              final bool paginable = _groupement == _Groupement.aucun;
              final totalPages = paginable
                  ? (filtered.length / _itemsPerPage).ceil().clamp(1, 1 << 30)
                  : 1;
              if (paginable && _currentPage >= totalPages) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _currentPage = totalPages - 1);
                });
              }
              final pageSure = _currentPage.clamp(0, totalPages - 1);
              final debut = paginable ? pageSure * _itemsPerPage : 0;
              final fin = paginable ? (debut + _itemsPerPage).clamp(0, filtered.length) : filtered.length;
              final pageItems = paginable
                  ? (filtered.isEmpty ? <Ticket>[] : filtered.sublist(debut, fin))
                  : filtered;

              return Expanded(
                child: filtered.isEmpty && !isLoading
                    ? const Center(child: Text('Aucun ticket trouvé', style: TextStyle(color: AppColors.muted)))
                    : Column(
                        children: [
                          Expanded(
                            child: RefreshIndicator(
                              onRefresh: () async => context.read<TicketBloc>().add(LoadTickets()),
                              child: _groupement == _Groupement.aucun
                                  ? GridView.builder(
                                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                                      itemCount: pageItems.length,
                                      // 🎯 Cartes réduites et taille fixe : le nombre de
                                      // colonnes s'adapte automatiquement à la largeur
                                      // réelle (2 sur mobile, 4+ sur web/tablette large),
                                      // sans avoir à recalculer un childAspectRatio.
                                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                        maxCrossAxisExtent: 230,
                                        mainAxisSpacing: 14,
                                        crossAxisSpacing: 14,
                                        mainAxisExtent: 252,
                                      ),
                                      itemBuilder: (ctx, i) => _ticketTile(ctx, pageItems[i]),
                                    )
                                  : _buildGroupedList(context, filtered),
                            ),
                          ),
                          if (paginable)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: ModernPagination(
                                currentPage: pageSure,
                                totalPages: totalPages,
                                onPageChanged: (p) => setState(() => _currentPage = p),
                                resultsLabel: '${debut + 1}–$fin sur ${filtered.length} ticket(s)',
                              ),
                            ),
                        ],
                      ),
              );
            }),
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
// WIDGET : Carte ticket dans la liste
// ═══════════════════════════════════════════════════════════════════
class TicketCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback onTap;
  const TicketCard({required this.ticket, required this.onTap});

  Color get _couleurPriorite {
    switch (ticket.priority) {
      case TicketPriority.haute: return AppColors.danger;
      case TicketPriority.normale: return AppColors.warning;
      case TicketPriority.basse: return const Color.fromARGB(255, 42, 157, 0);
    }
  }

  // 🎯 Couleur du bouton d'action, alignée sur le statut plutôt que la
  // priorité — c'est le statut qui indique "où en est" le ticket, ce que le
  // bouton doit refléter en un coup d'œil (comme "Faire une demande").
  List<Color> get _degradeStatut {
    switch (ticket.status) {
      case TicketStatus.enAttente: return const [Color(0xFFE0642B), Color(0xFFB3401A)];
      case TicketStatus.enCours: return const [Color(0xFF1E88A8), Color(0xFF0C5F78)];
      case TicketStatus.resolu: return const [Color(0xFF3FA85C), Color(0xFF1B7A43)];
      case TicketStatus.ferme: return const [Color(0xFF8A8F98), Color(0xFF5F6169)];
    }
  }

  String get _libelleStatut {
    switch (ticket.status) {
      case TicketStatus.enAttente: return 'En attente';
      case TicketStatus.enCours: return 'En cours';
      case TicketStatus.resolu: return 'Résolu';
      case TicketStatus.ferme: return 'Fermé';
    }
  }

  String get _libellePriorite {
    switch (ticket.priority) {
      case TicketPriority.haute: return 'Haute';
      case TicketPriority.normale: return 'Normale';
      case TicketPriority.basse: return 'Basse';
    }
  }

  // 🎯 Petit formatage de date relative "maison" (pas de dépendance intl
  // supplémentaire, le projet ne l'utilise pas ailleurs).
  String get _dateRelative {
    final diff = DateTime.now().difference(ticket.createdAt);
    if (diff.inMinutes < 1) return "À l'instant";
    if (diff.inHours < 1) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} j';
    return '${ticket.createdAt.day.toString().padLeft(2, '0')}/${ticket.createdAt.month.toString().padLeft(2, '0')}/${ticket.createdAt.year}';
  }

  // 🎯 Carte compacte (réduite par rapport à la version précédente, cf.
  // retour utilisateur) : petit logo aligné à gauche du n°/priorité au lieu
  // d'un gros logo centré, texte resserré, un seul bouton de statut pleine
  // largeur (la flèche est fusionnée dedans — la carte entière reste
  // cliquable via l'InkWell). Pensée pour tenir dans ~190×198, y compris
  // sur mobile (2 colonnes) grâce à SliverGridDelegateWithMaxCrossAxisExtent.
  @override
  Widget build(BuildContext context) {
    final couleur = _couleurPriorite;
    final bool nonAffecte = ticket.agentAssigneNom == null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: couleur.withOpacity(0.35), width: 1),
        boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 6, offset: Offset(0, 3))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── En-tête : petit logo + n°/structure, priorité à droite ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipOval(
                      child: Image.asset('assets/images/logo.jpg', width: 34, height: 34, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('N°${ticket.id}',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: couleur)),
                          Text(
                            ticket.structure.isEmpty ? '—' : ticket.structure,
                            style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.flag, size: 15, color: couleur),
                  ],
                ),
                const SizedBox(height: 8),

                // ── Titre (description) ──────────────────────────────────
                Text(
                  ticket.description,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, height: 1.25),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                ),

                const Spacer(),

                // ── Lignes d'info resserrées (icône + libellé) ───────────
                _ligneInfo(Icons.schedule_outlined, _dateRelative),
                const SizedBox(height: 5),
                _ligneInfo(
                  nonAffecte ? Icons.person_off_outlined : Icons.person_outline,
                  nonAffecte ? 'Non affecté' : ticket.agentAssigneNom!,
                  accent: nonAffecte,
                ),

                const SizedBox(height: 10),

                // ── Bouton de statut (pleine largeur, flèche intégrée) ───
                Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: _degradeStatut),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(_libelleStatut,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _ligneInfo(IconData icone, String texte, {bool accent = false}) {
    final couleurTexte = accent ? AppColors.warning : AppColors.muted;
    return Row(
      children: [
        Icon(icone, size: 13, color: couleurTexte),
        const SizedBox(width: 6),
        Expanded(
          child: Text(texte,
              style: TextStyle(fontSize: 11.5, color: couleurTexte, fontWeight: accent ? FontWeight.w600 : FontWeight.normal),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
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
    // 🎯 Recherche d'agent par nom, au-dessus de la liste (remplace le
    // menu déroulant simple, peu pratique dès qu'il y a beaucoup d'agents).
    final TextEditingController searchCtrl = TextEditingController();
    String query = '';

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

            final agentsFiltres = query.isEmpty
                ? agentsDSI
                : agentsDSI.where((u) => '${u.nom} ${u.prenom ?? ''}'.trim().toLowerCase().contains(query)).toList();

            return AlertDialog(
              title: const Text("Affecter un agent DSI au ticket"),
              // 🎯 CORRECTIF mobile : largeur fixe (360) remplacée par une
              // largeur qui s'adapte à l'écran, pour ne pas déborder sur un
              // téléphone étroit (ex: 320-360px de large).
              content: SizedBox(
                width: math.min(360, MediaQuery.of(context).size.width - 80),
                child: loading
                    ? const SizedBox(height: 60, child: Center(child: CircularProgressIndicator()))
                    : agentsDSI.isEmpty
                        ? const Text("Aucun agent DSI disponible.")
                        // 🎯 CORRECTIF overflow : contenu désormais scrollable
                        // (recherche + liste + priorité ne tenaient plus dans
                        // la hauteur du dialogue → "BOTTOM OVERFLOWED").
                        : SingleChildScrollView(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            // ── Recherche par nom ──────────────────────────
                            TextField(
                              controller: searchCtrl,
                              decoration: InputDecoration(
                                labelText: 'Agent DSI',
                                hintText: 'Rechercher un agent par nom...',
                                prefixIcon: const Icon(Icons.search, size: 20),
                                suffixIcon: query.isEmpty
                                    ? null
                                    : IconButton(
                                        icon: const Icon(Icons.close, size: 18),
                                        onPressed: () => setDialogState(() { searchCtrl.clear(); query = ''; }),
                                      ),
                                border: const OutlineInputBorder(),
                              ),
                              onChanged: (val) => setDialogState(() => query = val.trim().toLowerCase()),
                            ),
                            const SizedBox(height: 8),
                            // ── Liste filtrée, sélection par tap ───────────
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 170),
                              child: agentsFiltres.isEmpty
                                  ? const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                      child: Text("Aucun agent ne correspond à cette recherche."),
                                    )
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: agentsFiltres.length,
                                      itemBuilder: (_, i) {
                                        final u = agentsFiltres[i];
                                        final selectionne = agentSelectionne?.id == u.id;
                                        return ListTile(
                                          dense: true,
                                          selected: selectionne,
                                          selectedTileColor: AppColors.primary.withOpacity(0.08),
                                          leading: Icon(
                                            selectionne ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                            color: selectionne ? AppColors.primary : AppColors.muted,
                                            size: 20,
                                          ),
                                          title: Text(
                                            '${u.nom} ${u.prenom ?? ''}'.trim(),
                                            style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          onTap: () => setDialogState(() => agentSelectionne = u),
                                        );
                                      },
                                    ),
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
                                  .map((p) => DropdownMenuItem(
                                      value: p,
                                      child: Text(p.name.toUpperCase(),
                                          style: const TextStyle(color: Color(0xFF1A1A2E)))))
                                  .toList(),
                              onChanged: (val) => setDialogState(() => prioriteSelectionnee = val!),
                            ),
                          ]),
                        ),
              ),
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
                        icon: const _WhatsAppLogo(size: 24),
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
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _ouvrirWhatsApp(context, whatsapp),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF25D366).withOpacity(0.35)),
                            ),
                            child: Row(children: [
                              // ── Logo WhatsApp (bulle + combiné, dessiné maison) ──
                              const _WhatsAppLogo(size: 36),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(whatsapp, style: const TextStyle(
                                        fontSize: 13.5, color: Color(0xFF128C7E), fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 1),
                                    const Text('Contacter sur WhatsApp',
                                        style: TextStyle(fontSize: 11, color: Color(0xFF25D366))),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, size: 20, color: Color(0xFF25D366)),
                            ]),
                          ),
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
                          // Même forme que "Supprimer" ci-dessous (pleine
                          // largeur, coins arrondis 10px, icône) pour un
                          // rendu cohérent entre les deux actions.
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _demanderSolutionEtResoudre(context, t.id),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.check_circle_outline, size: 17),
                              label: const Text('Marquer résolu',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            ),
                          ),
                          if (peutSupprimer) ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _showDeleteConfirmationDialog(context, t.id),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red, width: 1.2),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.delete_outline, size: 17),
                                label: const Text('Supprimer le ticket',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
      // 🎯 Carrousel auto-défilant seulement à partir de 2 images — pour une
      // seule image, pas besoin de défilement, l'aperçu statique suffit.
      if (images.length > 1)
        _ImageCarousel(images: images, onTapImage: (i) => _ouvrirApercu(context, images, i))
      else if (images.length == 1)
        GestureDetector(
          onTap: () => _ouvrirApercu(context, images, 0),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  images[0],
                  width: 280, height: 180,
                  fit: BoxFit.cover,
                  headers: const {'Cache-Control': 'no-cache'},
                  loadingBuilder: (ctx, child, progress) => progress == null
                      ? child
                      : Container(
                          width: 280, height: 180,
                          color: AppColors.surface,
                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                  errorBuilder: (_, error, __) => Container(
                    width: 280, height: 180,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.image_not_supported_outlined, color: AppColors.muted, size: 28),
                      const SizedBox(height: 4),
                      Text(images[0].split('/').last,
                          style: const TextStyle(fontSize: 10, color: AppColors.muted),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ]),
                  ),
                ),
              ),
              Positioned(
                bottom: 4, right: 4,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(4)),
                  child: const Icon(Icons.zoom_in, size: 14, color: Colors.white),
                ),
              ),
            ],
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

// ─────────────────────────────────────────────────────────────────────────────
// Carrousel horizontal des images jointes, avec défilement automatique et un
// bouton pause/lecture pour l'arrêter et prendre le temps de regarder — le tap
// sur une image l'arrête aussi automatiquement et ouvre l'aperçu plein écran.
// ─────────────────────────────────────────────────────────────────────────────
class _ImageCarousel extends StatefulWidget {
  final List<String> images;
  final void Function(int index) onTapImage;
  const _ImageCarousel({required this.images, required this.onTapImage});

  @override
  State<_ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<_ImageCarousel> {
  static const double _hauteur = 170;
  late final PageController _pageCtrl;
  Timer? _timer;
  bool _enLecture = true;
  int _pageActuelle = 0;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    _demarrerDefilement();
  }

  // 🎯 PageView.animateToPage() bascule TOUJOURS d'une image à l'autre,
  // contrairement à un ScrollController horizontal dont le déplacement
  // dépendait de la largeur totale à faire défiler — avec seulement 2 ou 3
  // images tenant déjà dans la largeur visible, il n'y avait "rien à faire
  // défiler" et le minuteur tournait dans le vide (bug précédent).
  void _demarrerDefilement() {
    _timer?.cancel();
    if (widget.images.length < 2) return; // rien à faire défiler avec une seule image
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !_pageCtrl.hasClients) return;
      final suivante = (_pageActuelle + 1) % widget.images.length;
      _pageCtrl.animateToPage(suivante,
          duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    });
  }

  // 🎯 Arrêt explicite (bouton) — celui demandé pour "stopper et voir".
  void _basculerLecture() {
    setState(() => _enLecture = !_enLecture);
    if (_enLecture) {
      _demarrerDefilement();
    } else {
      _timer?.cancel();
    }
  }

  void _onTapImage(int i) {
    // 🎯 Ouvrir une image met aussi le carrousel en pause : à son retour de
    // l'aperçu plein écran, l'utilisateur le retrouve arrêté sur place,
    // plutôt que de le voir repartir tout seul pendant qu'il regardait.
    _timer?.cancel();
    if (_enLecture) setState(() => _enLecture = false);
    widget.onTapImage(i);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    return SizedBox(
      // 🎯 Largeur fixe (comme l'affichage à une seule image) : sans ça, le
      // PageView s'étirait sur toute la largeur de l'écran, ce qui forçait
      // un zoom énorme sur des images à la hauteur fixe de 170px.
      width: 280,
      child: Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: _hauteur,
            child: PageView.builder(
              controller: _pageCtrl,
              itemCount: images.length,
              onPageChanged: (i) => setState(() => _pageActuelle = i),
              itemBuilder: (ctx, i) => GestureDetector(
                onTap: () => _onTapImage(i),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      images[i],
                      fit: BoxFit.cover,
                      headers: const {'Cache-Control': 'no-cache'},
                      loadingBuilder: (ctx, child, progress) => progress == null
                          ? child
                          : Container(
                              color: AppColors.surface,
                              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            ),
                      errorBuilder: (_, error, __) => Container(
                        color: AppColors.surface,
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.image_not_supported_outlined, color: AppColors.muted, size: 28),
                          const SizedBox(height: 4),
                          Text(images[i].split('/').last,
                              style: const TextStyle(fontSize: 10, color: AppColors.muted),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ]),
                      ),
                    ),
                    Positioned(
                      bottom: 6, right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(4)),
                        child: const Icon(Icons.zoom_in, size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // ── Bouton pause / lecture ──────────────────────────────────────
        if (images.length > 1)
          Positioned(
            top: 8, right: 8,
            child: GestureDetector(
              onTap: _basculerLecture,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: Icon(_enLecture ? Icons.pause : Icons.play_arrow, size: 16, color: Colors.white),
              ),
            ),
          ),

        // ── Indicateurs (points) ──────────────────────────────────────────
        if (images.length > 1)
          Positioned(
            bottom: 8, left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(images.length, (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: i == _pageActuelle ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _pageActuelle ? Colors.white : Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(3),
                ),
              )),
            ),
          ),
      ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Logo WhatsApp "maison" — bulle verte + tail + combiné téléphonique blanc,
// dessiné au Canvas plutôt que via un package tiers (font_awesome_flutter a
// cassé la compilation avec certaines versions du SDK Flutter : IconData est
// désormais une classe "final" que ce package tentait d'étendre). Zéro
// dépendance = zéro risque de ce genre de casse.
// ─────────────────────────────────────────────────────────────────────────────
class _WhatsAppLogo extends StatelessWidget {
  final double size;
  const _WhatsAppLogo({this.size = 20});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size, size), painter: _WhatsAppPainter());
  }
}

class _WhatsAppPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintBulle = Paint()..color = const Color(0xFF25D366);
    final r = size.width / 2;

    // Bulle principale
    canvas.drawCircle(Offset(r, r), r, paintBulle);

    // Petite pointe de bulle de discussion (bas-gauche)
    final tail = Path()
      ..moveTo(size.width * 0.20, size.height * 0.80)
      ..lineTo(size.width * 0.03, size.height * 0.98)
      ..lineTo(size.width * 0.32, size.height * 0.86)
      ..close();
    canvas.drawPath(tail, paintBulle);

    // Combiné téléphonique blanc, centré (réutilise la glyphe Icons.phone
    // du thème Material, toujours disponible — pas un package tiers).
    final textPainter = TextPainter(textDirection: TextDirection.ltr)
      ..text = TextSpan(
        text: String.fromCharCode(Icons.phone.codePoint),
        style: TextStyle(
          fontSize: size.width * 0.52,
          fontFamily: Icons.phone.fontFamily,
          package: Icons.phone.fontPackage,
          color: Colors.white,
        ),
      )
      ..layout();
    textPainter.paint(
      canvas,
      Offset(r - textPainter.width / 2, r - textPainter.height / 2 - size.height * 0.03),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
      // 🎯 Si la structure/service n'étaient pas déjà sur le profil (compte
      // créé avant le correctif de l'inscription, par ex.) et que
      // l'utilisateur vient de les choisir ici lui-même, on les enregistre
      // sur son profil — comme ça, la prochaine fois, tout se préremplit
      // automatiquement (même logique que le numéro de téléphone).
      if (_structureNomUtilisateur == null && _structureSelectionnee?.id != null) {
        sl<AuthService>().mettreAJourMonProfil(
          structureId: _structureSelectionnee!.id,
          serviceId: _serviceSelectionne?.id,
        ).catchError((_) {
          // Non bloquant : si ça échoue, le ticket est quand même créé,
          // l'utilisateur choisira simplement de nouveau la prochaine fois.
        });
      }
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