import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:url_launcher/url_launcher.dart'; 
import 'package:flutter_application_1/bloc/all_blocs.dart';
import 'package:flutter_application_1/screens/edit_invitation_screen.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widget/shared_widget.dart';
import '../core/api_constants.dart';
import 'package:flutter_application_1/screens/pdf_viewer_page.dart';
import 'package:flutter_application_1/screens/screen/invitation_screen.dart';

// Fonction utilitaire pour gérer l'ouverture des pièces jointes et des exports
Future<void> ouvrirPieceJointe(String urlOrPath) async {
  final Uri url = Uri.parse(urlOrPath.startsWith('http') ? urlOrPath : '${ApiConstants.baseUrl}/$urlOrPath');
  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
    throw Exception('Impossible d\'ouvrir le lien : $url');
  }
}

class InvitationsScreen extends StatefulWidget {
  const InvitationsScreen({super.key});

  @override
  State<InvitationsScreen> createState() => _InvitationsScreenState();
}

enum _InvTab { recues, envoyees }

class _InvitationsScreenState extends State<InvitationsScreen> {
  String _search = '';
  InvitationStatus? _filterStatus;
  _InvTab _currentTab = _InvTab.recues;

  @override
  void initState() {
    super.initState();
    _initialiserOngletSelonRole();
    // 🎯 Vide la pastille "Invitations" (notifications liées non lues) à l'ouverture de l'écran.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<NotifBloc>().add(MarkCategoryRead(NotifCategory.invitation));
    });
  }

  Future<void> _initialiserOngletSelonRole() async {
    final role = await sl<StorageService>().userRole;
    final isAdmin = role == 'ADMIN';
    setState(() => _currentTab = isAdmin ? _InvTab.envoyees : _InvTab.recues);
    _chargerOngletActuel();
  }

  void _chargerOngletActuel() {
    if (_currentTab == _InvTab.envoyees) {
      context.read<InvitationBloc>().add(LoadInvitationsEnvoyees());
    } else {
      context.read<InvitationBloc>().add(LoadInvitationsRecues());
    }
  }

  List<Invitation> _applyFilters(List<Invitation> all) {
    return all.where((inv) {
      final matchSearch = inv.objet.toLowerCase().contains(_search.toLowerCase()) ||
          inv.structureEmettrice.toLowerCase().contains(_search.toLowerCase());
      final matchStatus = _filterStatus == null || inv.status == _filterStatus;
      return matchSearch && matchStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InvitationBloc, InvitationState>(
      listener: (context, state) {
        if (state is InvitationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.msg), backgroundColor: const Color.fromARGB(255, 11, 67, 32)),
          );
          _chargerOngletActuel();
        }
        if (state is InvitationError) {
          showErrorSnack(context, state.msg);
        }
      },
      builder: (context, state) {
        final allInvitations = state is InvitationsLoaded ? state.page.items : <Invitation>[];
        final filtered = _applyFilters(allInvitations);
        final loading = state is InvitationLoading;

        return Scaffold(
          appBar: AppBar(
            title: Text(_currentTab == _InvTab.envoyees ? 'Invitations envoyées' : 'Invitations reçues'),
            actions: [
              if (loading)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.refresh_outlined, size: 20),
                onPressed: _chargerOngletActuel,
              ),
            ],
          ),
          
floatingActionButton: BlocBuilder<AuthBloc, AuthState>(
  builder: (_, authState) {
    // 🎯 Seuls ADMIN, SECRETAIRE, SUPERVISEUR et tout rôle ayant
    // GERER_INVITATIONS peuvent créer ou enregistrer une invitation.
    // AGENT_DSI et USAGER ne voient aucun bouton de création.
    final role = authState is AuthOk ? authState.role : '';
    final peutCreer = authState is AuthOk && (
      role == 'ADMIN' ||
      role == 'SECRETAIRE' ||
      role == 'SUPERVISEUR' ||
      authState.permissions.contains('GERER_INVITATIONS')
    );
    if (!peutCreer) return const SizedBox.shrink();

    return _currentTab == _InvTab.envoyees
      ? FloatingActionButton.extended(
          heroTag: 'fab_enregistrer',
          onPressed: () => _showAddDialog(context),
          backgroundColor: const Color.fromARGB(255, 6, 69, 21),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text("Enregistrer"),
        )
      : FloatingActionButton.extended(
          heroTag: 'fab_creer',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<InvitationBloc>(),
                  child: const InvitationScreen(),
                ),
              ),
            );
          },
          backgroundColor: const Color.fromARGB(255, 2, 50, 20),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.edit),
          label: const Text("Creer"),
        );
  },
),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  children: [
                    AppSearchBar(
                      hint: 'Rechercher par objet, structure...',
                      onChanged: (v) => setState(() => _search = v),
                    ),
                    
                    const SizedBox(height: 10),
                    Row(
  children: [
    // ── BOUTON 1 : ENVOYER (invitations créées par l'administration) ──
    Expanded(
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: _currentTab == _InvTab.envoyees
              ? const Color.fromARGB(255, 10, 78, 25)
              : const Color.fromARGB(255, 170, 190, 175),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () {
          setState(() => _currentTab = _InvTab.envoyees);
          context.read<InvitationBloc>().add(LoadInvitationsEnvoyees());
        },
        icon: const Icon(Icons.send_rounded, size: 18),
        label: const Text('RECU', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      ),
    ),
    
    const SizedBox(width: 12), // Espace d'écartement entre les deux boutons
    
    // ── BOUTON 2 : REÇU (invitations reçues par ma structure) ──────────
    Expanded(
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: _currentTab == _InvTab.recues
              ? const Color.fromARGB(255, 10, 78, 25)
              : const Color.fromARGB(255, 170, 190, 175),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () {
          setState(() => _currentTab = _InvTab.recues);
          context.read<InvitationBloc>().add(LoadInvitationsRecues());
        },
        icon: const Icon(Icons.download_rounded, size: 18),
        label: const Text('ENVOYER', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      ),
    ),
  ],
),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'Toutes',
                            selected: _filterStatus == null,
                            onTap: () => setState(() => _filterStatus = null),
                          ),
                          // 🎯 Les filtres de statut détaillés ne s'affichent que sur l'onglet "Envoyer"
                          if (_currentTab == _InvTab.envoyees)
                            ...InvitationStatus.values.map((s) => Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: _FilterChip(
                                    label: s.label,
                                    selected: _filterStatus == s,
                                    onTap: () => setState(() =>
                                        _filterStatus = _filterStatus == s ? null : s),
                                  ),
                                )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: filtered.isEmpty && !loading
                    ? const Center(
                        child: Text(
                          'Aucune invitation trouvée',
                          style: TextStyle(color: AppColors.muted),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async => _chargerOngletActuel(),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (ctx, i) => _InvitationCard(
                            inv: filtered[i],
                            onTap: () => _openDetail(context, filtered[i]),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openDetail(BuildContext context, Invitation inv) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => InvitationDetailScreen(inv: inv)),
    );
  }

  void _showAddDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<InvitationBloc>(),
        child: const _AddInvitationSheet(),
      ),
      backgroundColor: Colors.white,
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : AppColors.muted,
          ),
        ),
      ),
    );
  }
}

class _InvitationCard extends StatelessWidget {
  final Invitation inv;
  final VoidCallback onTap;

  const _InvitationCard({required this.inv, required this.onTap});

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.mail_outline, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inv.objet,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${inv.structureEmettrice} · ${_fmt(inv.dateDebut)}'
                  '${inv.dateFin != inv.dateDebut ? ' – ${_fmt(inv.dateFin)}' : ''}',
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    // 🎯 Le statut (En attente/Planifiée/En cours/...) ne s'applique
                    // pas aux lettres officielles créées via "Créer".
                    if (inv.modeCreation != 'CREER') ...[
                      StatusBadge.fromInvStatus(inv.status),
                      const SizedBox(width: 8),
                    ],
                    if (inv.nombreParticipants > 0)
                      Text(
                        '${inv.nombreParticipants} participant(s)',
                        style: const TextStyle(fontSize: 11, color: AppColors.muted),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 18, color: AppColors.muted),
        ],
      ),
    );
  }
}

// ── Formulaire de création ──────────────────────────────────────────

class _AddInvitationSheet extends StatefulWidget {
  const _AddInvitationSheet();

  @override
  State<_AddInvitationSheet> createState() => _AddInvitationSheetState();
}

class _AddInvitationSheetState extends State<_AddInvitationSheet> {
  // 🎯 Remplace le champ texte libre par une liste déroulante des structures
  // en base, avec recherche par nom.
  final _structureEmettriceCtrl = TextEditingController();
  Structure? _structureSelectionnee;
  List<Structure> _structuresList = [];
  bool _loadingStructures = true;

  final _objetCtrl  = TextEditingController();
  final _lieuCtrl   = TextEditingController();
  final _nbCtrl     = TextEditingController();
  DateTime? _dateDebut;
  DateTime? _dateFin;

  final List<PlatformFile> _selectedFiles = [];

  @override
  void initState() {
    super.initState();
    _chargerStructures();
  }

  Future<void> _chargerStructures() async {
    try {
      final liste = await sl<AdminService>().getStructures();
      if (mounted) setState(() { _structuresList = liste; _loadingStructures = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingStructures = false);
    }
  }

  @override
  void dispose() {
    _structureEmettriceCtrl.dispose();
    _objetCtrl.dispose();
    _lieuCtrl.dispose();
    _nbCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isDebut) async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (d != null) {
      setState(() {
        if (isDebut) {
          _dateDebut = d;
        } else {
          _dateFin = d;
        }
      });
    }
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
        withData: true,
      );

      if (result != null) {
        setState(() {
          _selectedFiles.addAll(result.files);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection des fichiers: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  void _submit() {
    if (_objetCtrl.text.trim().isEmpty ||
        _dateDebut == null ||
        _dateFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Veuillez remplir les champs obligatoires (*)'),
          backgroundColor: AppColors.danger));
      return;
    }

    final List<MapEntry<String, Uint8List>> fileBytes = _selectedFiles
        .where((f) => f.bytes != null)
        .map((f) => MapEntry(f.name, f.bytes!))
        .toList();

    context.read<InvitationBloc>().add(CreateInvitation(
      {
        'structureEmettrice': _structureEmettriceCtrl.text.trim(),
        'objet': _objetCtrl.text.trim(),
        'lieu': _lieuCtrl.text.trim(),           // 👈 MODIFIÉ : Envoi explicite du lieu
        'dateDebut':
            '${_dateDebut!.year}-${_dateDebut!.month.toString().padLeft(2, '0')}-${_dateDebut!.day.toString().padLeft(2, '0')}',
        'dateFin':
            '${_dateFin!.year}-${_dateFin!.month.toString().padLeft(2, '0')}-${_dateFin!.day.toString().padLeft(2, '0')}',
        'nombreParticipants': int.tryParse(_nbCtrl.text.trim()) ?? 0, // 👈 MODIFIÉ : Suppression du 'if', envoi systématique
        'modeCreation': 'ENREGISTRER',
      },
      filePaths: const [],
      fileBytes: fileBytes,
    ));

    Navigator.pop(context);
  }
  @override
  Widget build(BuildContext context) {
    return BlocListener<InvitationBloc, InvitationState>(
      listener: (context, state) {
        if (state is InvitationSuccess && mounted) {
          Navigator.of(context).maybePop();
        }
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Text(
                      'Nouvelle invitation',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Text(
                  '* Champs obligatoires',
                  style: TextStyle(fontSize: 11, color: AppColors.muted),
                ),
                const SizedBox(height: 12),

                // 🎯 Liste déroulante des structures en base avec recherche par nom
                _loadingStructures
                  ? const SizedBox(height: 48, child: Center(child: LinearProgressIndicator()))
                  : Autocomplete<Structure>(
                      displayStringForOption: (s) => s.nom,
                      optionsBuilder: (TextEditingValue tv) {
                        if (tv.text.isEmpty) return _structuresList;
                        return _structuresList.where((s) =>
                            s.nom.toLowerCase().contains(tv.text.toLowerCase()));
                      },
                      onSelected: (Structure s) {
                        setState(() => _structureSelectionnee = s);
                        _structureEmettriceCtrl.text = s.nom;
                      },
                      fieldViewBuilder: (ctx, ctrl, focusNode, onSubmitted) =>
                        TextField(
                          controller: ctrl,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            labelText: "Structure émettrice *",
                            hintText: "Tapez pour rechercher…",
                            prefixIcon: const Icon(Icons.account_balance_outlined, size: 18),
                            suffixIcon: _structureSelectionnee != null
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      setState(() => _structureSelectionnee = null);
                                      ctrl.clear();
                                      _structureEmettriceCtrl.clear();
                                    },
                                  )
                                : const Icon(Icons.arrow_drop_down),
                          ),
                        ),
                     optionsViewBuilder: (ctx, onSel, opts) => Align(
  alignment: Alignment.topLeft,
  child: Material(
    elevation: 4,
    borderRadius: BorderRadius.circular(8),
    color: Colors.white, // 👈 Force le fond du menu en blanc opaque
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 200),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: opts.length,
        itemBuilder: (_, i) {
          final s = opts.elementAt(i);
          return ListTile(
            dense: true,
            // 👈 On force la couleur du texte en noir pour qu'il soit bien visible
            title: Text(
              s.nom, 
              style: const TextStyle(
                color: Colors.black87, 
                fontSize: 13,
                fontWeight: FontWeight.w500
              ),
            ),
            onTap: () => onSel(s),
          );
        },
      ),
    ),
  ),
),
                    ),

                const SizedBox(height: 10),
                TextField(
                  controller: _objetCtrl,
                  decoration: const InputDecoration(labelText: "Objet de l'invitation *"),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _pickDate(true),
                        child: AbsorbPointer(
                          child: TextField(
                            controller: TextEditingController(
                              text: _dateDebut != null ? _fmt(_dateDebut!) : '',
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Date début *',
                              prefixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _pickDate(false),
                        child: AbsorbPointer(
                          child: TextField(
                            controller: TextEditingController(
                              text: _dateFin != null ? _fmt(_dateFin!) : '',
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Date fin *',
                              prefixIcon: Icon(Icons.event_outlined, size: 18),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _lieuCtrl,
                  decoration: const InputDecoration(labelText: 'Lieu'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _nbCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Nombre de participants'),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Pièces jointes',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                OutlinedButton.icon(
                  onPressed: _pickFiles,
                  icon: const Icon(Icons.attach_file, size: 18),
                  label: const Text('Joindre un fichier'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 0.8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                if (_selectedFiles.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 20, 9, 9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border, width: 0.5),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      itemCount: _selectedFiles.length,
                      itemBuilder: (context, index) {
                        final file = _selectedFiles[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(
                            Icons.insert_drive_file,
                            color: Color.fromARGB(222, 13, 2, 2),
                            size: 18,
                          ),
                          title: Text(
                            file.name,
                            style: const TextStyle(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: AppColors.danger,
                              size: 18,
                            ),
                            onPressed: () => _removeFile(index),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Enregistrer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



class InvitationDetailScreen extends StatefulWidget {
  final Invitation inv;
  const InvitationDetailScreen({super.key, required this.inv});

  @override
  State<InvitationDetailScreen> createState() => _InvitationDetailScreenState();
}

class _InvitationDetailScreenState extends State<InvitationDetailScreen> {
  final List<String> _selectedAgentIds = []; 
  String? _responsableId;

  // 🎯 IMPORTANT — Le InvitationBloc est PARTAGÉ globalement (liste, création,
  // détail...). Si un autre écran déclenche LoadInvitationsEnvoyees/Recues
  // pendant qu'on est sur cette page de détail, le state du Bloc n'est plus
  // InvDetailLoaded et l'écran retombait sur `widget.inv` (la version
  // d'AVANT le clic sur "Retirer") — donc le retrait semblait ne rien faire,
  // même si la suppression avait bien réussi côté serveur.
  // On garde donc la dernière invitation connue (_invAffichee) et on ne la
  // remplace QUE quand le state reçu est effectivement InvDetailLoaded.
  late Invitation _invAffichee;

  // Configuration de l'URL de ton serveur de gestion DSI.
  // ApiConstants.baseUrl gère automatiquement web / émulateur / téléphone
  // physique (via --dart-define=API_HOST).
  static String get _baseUrl => ApiConstants.baseUrl;

  @override
  void initState() {
    super.initState();
    _invAffichee = widget.inv;
    _selectedAgentIds.addAll(widget.inv.agentsAffectes.map((a) => a.id.toString()));
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Widget _badgeStatutReponse(String statut) {
    Color couleur;
    String libelle;
    switch (statut) {
      case 'ACCEPTEE':
        couleur = const Color(0xFF16A34A);
        libelle = 'Acceptée';
        break;
      case 'REFUSEE':
        couleur = const Color(0xFFDC2626);
        libelle = 'Refusée';
        break;
      case 'EXCUSEE':
        couleur = const Color(0xFFD97706);
        libelle = 'Excusée';
        break;
      default:
        couleur = const Color(0xFF64748B);
        libelle = 'En attente';
    }
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: couleur.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(libelle, style: TextStyle(fontSize: 11, color: couleur, fontWeight: FontWeight.w600)),
    );
  }

  void _showAjouterStructureDialog(BuildContext context, Invitation inv) {
    final InvitationBloc invBloc = BlocProvider.of<InvitationBloc>(context);
    final invId = inv.id;
    final dejaLiees = inv.structuresInvitees.map((s) => s.id).toSet();
    showDialog(
      context: context,
      builder: (dialogContext) => _AjouterStructureDialog(
        invId: invId,
        dejaLiees: dejaLiees,
        onAjouter: (structureId) =>
            invBloc.add(AjouterStructureInvitee(invId: invId, structureId: structureId)),
      ),
    );
  }

 void _openFile(BuildContext context, String fileUrlOrName) async {
  String targetUrl = fileUrlOrName;

  if (fileUrlOrName.contains('chemin:')) {
    final cheminMatch = RegExp(r"chemin:\s*([^,}]+)").firstMatch(fileUrlOrName);
    if (cheminMatch != null) targetUrl = cheminMatch.group(1)!.trim();
  }

  if (!targetUrl.startsWith('http')) {
    if (targetUrl.startsWith('/')) {
      targetUrl = targetUrl.substring(1);
    }
    targetUrl = "$_baseUrl/api/files/download/$targetUrl";
  }

  // 🎯 Un navigateur sait afficher un PDF ou une image dans une iframe,
  // mais PAS un .docx/.doc/.xlsx (aucun navigateur ne le rend nativement).
  // Pour ces formats, on ouvre/télécharge directement au lieu d'afficher
  // un aperçu cassé/vide dans l'iframe.
  final ext = targetUrl.split('.').last.toLowerCase().split('?').first;
  const previsualisable = ['pdf', 'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'];

  if (!previsualisable.contains(ext)) {
    await ouvrirPieceJointe(targetUrl);
    return;
  }

  print("🎯 URL finale appelée pour l'IFrame : $targetUrl");

  // Redirection vers notre composant IFrame au lieu d'ouvrir une application externe !
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => PdfViewerPage(
        pdfUrl: targetUrl,
        title: targetUrl.split('/').last,
      ),
    ),
  );
}
  // ─── 2. EXPORT ET TÉLÉCHARGEMENT DU DOCUMENT PDF ────────────────────────────
  Future<void> _exportPdf(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export PDF en cours…'),
        backgroundColor: Color.fromARGB(255, 5, 65, 30),
        duration: Duration(seconds: 2),
      ),
    );

    final String exportUrl = '$_baseUrl/api/invitations/${widget.inv.id}/export/pdf';
    final Uri url = Uri.parse(exportUrl);

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Lien d\'export introuvable ou inaccessible';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec de l\'export PDF : $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ─── 3. EXPORT ET TÉLÉCHARGEMENT DU DOCUMENT WORD ───────────────────────────
  Future<void> _exportWord(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export Word en cours…'),
        backgroundColor: Color.fromARGB(255, 3, 66, 35),
        duration: Duration(seconds: 2),
      ),
    );

    final String exportUrl = '$_baseUrl/api/invitations/${widget.inv.id}/export/word';
    final Uri url = Uri.parse(exportUrl);

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Lien d\'export introuvable ou inaccessible';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec de l\'export Word : $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showAffectationModal(BuildContext context) async {
    setState(() {
      _selectedAgentIds.clear();
      _selectedAgentIds.addAll(widget.inv.agentsAffectes.map((a) => a.id.toString()));
    });

    final InvitationBloc invBloc = BlocProvider.of<InvitationBloc>(context);

    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return BlocProvider.value(
          value: invBloc,
          child: _AffectationModal(
            inv: widget.inv,
            initialSelectedIds: List.from(_selectedAgentIds),
            initialResponsableId: _responsableId,
            onConfirmed: (selectedIds, responsableId) {
              setState(() {
                _selectedAgentIds
                  ..clear()
                  ..addAll(selectedIds);
                _responsableId = responsableId;
              });
              
              invBloc.add(AssignerAgentsInvitation(
                invId: widget.inv.id.toString(),
                agentIds: selectedIds,
                responsableId: responsableId,
              ));
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🎯 Une invitation créée via "Créer" (lettre officielle) n'a pas besoin
    // d'affectation d'agents ; seules celles créées via "Enregistrer" en ont besoin.
    final bool estUneLettreCreee = widget.inv.modeCreation == 'CREER';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 3, 75, 33),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Détail invitation',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        ),
        actions: [
          // 🎯 Affectation gérée par ADMIN et SECRETAIRE uniquement
          // (le nom de permission 'AFFECTER_AGENT' n'existe pas côté backend
          // — l'enum Permission a AFFECTER_INVITATION/AFFECTER_TICKET —
          // donc on se base directement sur le rôle, comme pour les tickets).
          BlocBuilder<AuthBloc, AuthState>(
            builder: (_, authState) {
              final role = authState is AuthOk ? authState.role : '';
              final peutAffecter = role == 'ADMIN' || role == 'SECRETAIRE';
              if (estUneLettreCreee || !peutAffecter) return const SizedBox.shrink();
              return TextButton.icon(
                onPressed: () => _showAffectationModal(context),
                icon: const Icon(Icons.person_add_outlined, size: 20, color: Colors.white),
                label: const Text(
                  'Affecter',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      backgroundColor: const Color(0xFFF1F5F9),
      body: BlocConsumer<InvitationBloc, InvitationState>(
        // 🎯 Jusqu'ici, aucune erreur n'était jamais affichée sur cet écran —
        // si "Retirer" échouait côté serveur, rien ne le signalait, on
        // retombait juste sur l'ancienne liste sans explication.
        listener: (context, state) {
          if (state is InvitationError) {
            showErrorSnack(context, state.msg);
          }
        },
        builder: (context, state) {
          // On ne met à jour le cache QUE lorsque l'état concerne bien le détail
          // de CETTE invitation (et pas un rechargement de liste déclenché ailleurs).
          if (state is InvDetailLoaded && state.inv.id == widget.inv.id) {
            _invAffichee = state.inv;
          }
          final Invitation invitationAffichee = _invAffichee;
          final bool loading = state is InvitationLoading;

          final bool afficherExport = invitationAffichee.modeCreation == 'CREER';
          final bool afficherAffectation = !afficherExport;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            children: [
              // ── Carte principale ──────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                ),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invitationAffichee.objet,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    // 🎯 Le statut ne s'applique pas aux lettres officielles créées via "Créer".
                    if (!afficherExport) StatusBadge.fromInvStatus(invitationAffichee.status),
                    // 🎯 Export PDF/Word réservé aux invitations créées via "Créer"
                    if (afficherExport) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _exportPdf(context),
                              icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                              label: const Text('Exporter PDF'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color.fromARGB(255, 5, 65, 30),
                                side: const BorderSide(color: Color.fromARGB(255, 5, 65, 30), width: 0.8),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _exportWord(context),
                              icon: const Icon(Icons.description_outlined, size: 18),
                              label: const Text('Exporter Word'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color.fromARGB(255, 3, 66, 35),
                                side: const BorderSide(color: Color.fromARGB(255, 3, 66, 35), width: 0.8),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
                    const Divider(color: Color(0xFFE2E8F0), height: 1),
                    _DetailRow(
                      icon: Icons.grid_view_outlined,
                      label: 'Structure émettrice',
                      value: invitationAffichee.structureEmettrice.isNotEmpty ? invitationAffichee.structureEmettrice : '—',
                    ),
                    const Divider(color: Color(0xFFE2E8F0), height: 1),
                    _DetailRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Date de début',
                      value: _fmt(invitationAffichee.dateDebut),
                    ),
                    const Divider(color: Color(0xFFE2E8F0), height: 1),
                    _DetailRow(
                      icon: Icons.event_outlined,
                      label: 'Date de fin',
                      value: _fmt(invitationAffichee.dateFin),
                    ),
                    const Divider(color: Color(0xFFE2E8F0), height: 1),
                    _DetailRow(
                      icon: Icons.location_on_outlined,
                      label: 'Lieu',
                      value: invitationAffichee.lieu?.isNotEmpty == true ? invitationAffichee.lieu! : 'Non précisé',
                    ),
                    const Divider(color: Color(0xFFE2E8F0), height: 1),
                    _DetailRow(
                      icon: Icons.group_outlined,
                      label: 'Participants',
                      value: invitationAffichee.nombreParticipants > 0 ? '${invitationAffichee.nombreParticipants}' : 'Non défini',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── Structures destinataires (CRUD structure_invitee) ───────────
              // 🎯 Réservé aux invitations créées via "Créer" (lettre officielle) ;
              // pas pertinent pour les invitations "Enregistrer" (page Envoyer).
              if (afficherExport) ...[
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Structures destinataires',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                            ),
                          ),
                          if (loading)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                            ),
                          TextButton.icon(
                            onPressed: loading ? null : () => _showAjouterStructureDialog(context, invitationAffichee),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Ajouter'),
                            style: TextButton.styleFrom(foregroundColor: const Color.fromARGB(255, 5, 77, 35)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (invitationAffichee.structuresInvitees.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Aucune structure destinataire pour cette invitation',
                            style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: invitationAffichee.structuresInvitees.length,
                          itemBuilder: (context, index) {
                            final si = invitationAffichee.structuresInvitees[index];
                            return Container(
                              margin: const EdgeInsets.only(top: 6),
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.account_balance_outlined, size: 18, color: Color.fromARGB(255, 5, 77, 35)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(si.nom, style: const TextStyle(fontSize: 13)),
                                  ),
                                  _badgeStatutReponse(si.statutReponse),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, size: 18),
                                    onSelected: (action) {
                                      if (si.structureInviteeId == null) {
                                        // 🎯 Ne devrait jamais arriver si le backend renvoie bien
                                        // "structureInviteeId" — message explicite plutôt qu'un no-op silencieux.
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                          content: Text("Impossible d'identifier cette structure destinataire (id manquant)."),
                                          backgroundColor: Colors.red,
                                        ));
                                        return;
                                      }
                                      if (action == 'RETIRER') {
                                        context.read<InvitationBloc>().add(
                                            SupprimerStructureInvitee(structureInviteeId: si.structureInviteeId!));
                                      } else {
                                        context.read<InvitationBloc>().add(ModifierStatutStructureInvitee(
                                            structureInviteeId: si.structureInviteeId!, statutReponse: action));
                                      }
                                    },
                                    itemBuilder: (context) => const [
                                      PopupMenuItem(value: 'EN_ATTENTE', child: Text('Marquer en attente')),
                                      PopupMenuItem(value: 'ACCEPTEE', child: Text('Marquer acceptée')),
                                      PopupMenuItem(value: 'REFUSEE', child: Text('Marquer refusée')),
                                      PopupMenuItem(value: 'EXCUSEE', child: Text('Marquer excusée')),
                                      PopupMenuDivider(),
                                      PopupMenuItem(value: 'RETIRER', child: Text('Retirer', style: TextStyle(color: Colors.red))),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ── Pièces jointes ────────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pièces jointes associées',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                    const SizedBox(height: 10),
                    if (invitationAffichee.files.isEmpty)
                      const Text(
                        'Aucune pièce jointe pour cette invitation',
                        style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: invitationAffichee.files.length,
                        itemBuilder: (context, index) {
                          final rawFileString = invitationAffichee.files[index];
                          String displayName = "Pièce jointe";
                          if (rawFileString.contains('nom:')) {
                            final nomMatch = RegExp(r"nom:\s*([^,]+)").firstMatch(rawFileString);
                            if (nomMatch != null) displayName = nomMatch.group(1)!.trim();
                          } else {
                            displayName = rawFileString.contains('/') ? rawFileString.split('/').last : rawFileString;
                          }
                          return InkWell(
                            onTap: () => _openFile(context, rawFileString),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.insert_drive_file_outlined, color: Color.fromARGB(255, 5, 77, 35), size: 22),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      displayName,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF2ECC71),
                                        decoration: TextDecoration.underline,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Icon(Icons.visibility_outlined, size: 18, color: Color(0xFF94A3B8)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── Agents affectés (uniquement pour les invitations "Enregistrer") ──
              if (afficherAffectation)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Agents affectés',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                      const SizedBox(height: 10),
                      if (invitationAffichee.agentsAffectes.isEmpty)
                        const Text(
                          'Aucun agent affecté',
                          style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: invitationAffichee.agentsAffectes.length,
                          itemBuilder: (context, index) {
                            final agent = invitationAffichee.agentsAffectes[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: const Color(0xFFE6F1FB),
                                    radius: 16,
                                    child: Text(
                                      agent.nom.substring(0, 1).toUpperCase(),
                                      style: const TextStyle(color: Color(0xFF2ECC71), fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    '${agent.nom} ${agent.prenom ?? ''}'.trim(),
                                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),
// ─── ACTIONS : MODIFIER ET SUPPRIMER ─────────────────────────────────────────
// 🎯 Un AGENT_DSI ne fait que consulter les invitations : il ne doit
// jamais voir les boutons Modifier / Supprimer, quel que soit le
// mode de création (CREER ou ENREGISTRER) ni le statut.
BlocBuilder<AuthBloc, AuthState>(
  builder: (_, authState) {
    final role = authState is AuthOk ? authState.role : '';
    if (role == 'AGENT_DSI') return const SizedBox.shrink();
    return Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
  child: Row(
    children: [
      // Bouton Modifier
      Expanded(
        child: ElevatedButton.icon(
          onPressed: () {
              if (invitationAffichee.status == 'TERMINEE') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Impossible de modifier une invitation terminée.'),
                    backgroundColor: Colors.red,
                  ),
                );
              } else {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => EditInvitationPage(inv: invitationAffichee)),
  );
            };
            // Navigator.push(context, MaterialPageRoute(builder: (context) => EditInvitationPage(inv: invitationAffichee)));
          },
          icon: const Icon(Icons.edit, size: 18),
          label: const Text('Modifier'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 4, 67, 30),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
      const SizedBox(width: 12),
      // Bouton Supprimer
      Expanded(
        child: OutlinedButton.icon(
          onPressed: () => _confirmerSuppression(context),
          icon: const Icon(Icons.delete_outline, size: 18),
          label: const Text('Supprimer'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red, width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
    ],
  ),
);
  },
),
            ],
          );
        },
      ),
    );
  }

  void _confirmerSuppression(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette invitation ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<InvitationBloc>().add(DeleteInvitation(widget.inv.id.toString()));
              Navigator.pop(ctx);
              Navigator.pop(context); // Ferme aussi la page de détail après suppression
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// Modal d'affectation d'agents
// ─────────────────────────────────────────────────────────────────────────────
class _AffectationModal extends StatefulWidget {
  final Invitation inv;
  final List<String> initialSelectedIds;
  final String? initialResponsableId;
  final void Function(List<String> selectedIds, String? responsableId) onConfirmed;

  const _AffectationModal({
    required this.inv,
    required this.initialSelectedIds,
    required this.initialResponsableId,
    required this.onConfirmed,
  });

  @override
  State<_AffectationModal> createState() => _AffectationModalState();
}

class _AffectationModalState extends State<_AffectationModal> {
  late List<String> _selectedIds;
  String? _responsableId;
  List<AppUser> _agents = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.initialSelectedIds);
    _responsableId = widget.initialResponsableId;
    _loadAgents();
  }

  Future<void> _loadAgents() async {
    try {
      if (!mounted) return;
      setState(() {
        _loading = true;
        _error = null;
      });

      final agents = await sl<AdminService>().getAgents();

      if (mounted) {
        setState(() {
          _agents = agents;
          _loading = false;
        });
      }
    } catch (e, stack) {
      debugPrint("❌ ERREUR CHARGEMENT MODAL AGENTS : $e");
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 20, left: 20, right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Affecter des agents',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Erreur de communication : $_error',
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else if (_agents.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: Text('Aucun agent disponible')),
            )
          else
            WidgetAgentsList(
              agents: _agents,
              selectedIds: _selectedIds,
              responsableId: _responsableId,
              onChanged: (selected, resp) {
                setState(() {
                  _selectedIds = selected;
                  _responsableId = resp;
                });
              },
            ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 6, 69, 32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: Text(_selectedIds.isEmpty
                ? 'Confirmer (aucun sélectionné)'
                : 'Confirmer — ${_selectedIds.length} agent(s)'),
            onPressed: () {
              widget.onConfirmed(_selectedIds, _responsableId);
              Navigator.pop(context, true);
            },
          ),
        ],
      ),
    );
  }
}

// Composant interne pour encapsuler la liste dynamique des agents
class WidgetAgentsList extends StatelessWidget {
  final List<AppUser> agents;
  final List<String> selectedIds;
  final String? responsableId;
  final Function(List<String> selected, String? resp) onChanged;

  const WidgetAgentsList({
    super.key,
    required this.agents,
    required this.selectedIds,
    required this.responsableId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 320),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: agents.length,
        itemBuilder: (_, i) {
          final agent = agents[i];
          final agentId = agent.id;
          final isSelected = selectedIds.contains(agentId);
          final isResponsable = responsableId == agentId;
          return Column(
            children: [
              CheckboxListTile(
                dense: true,
                activeColor: const Color.fromARGB(255, 3, 58, 26),
                title: Text(
                  '${agent.nom} ${agent.prenom ?? ''}'.trim(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1E293B),
                  ),
                ),
                subtitle: isSelected
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Responsable', 
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: isResponsable,
                            activeColor: const Color(0xFF2ECC71),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            onChanged: (val) {
                              onChanged(selectedIds, val ? agentId : null);
                            },
                          ),
                        ],
                      )
                    : null,
                value: isSelected,
                onChanged: (checked) {
                  final updatedIds = List<String>.from(selectedIds);
                  String? updatedResp = responsableId;
                  if (checked == true) {
                    updatedIds.add(agentId);
                  } else {
                    updatedIds.remove(agentId);
                    if (updatedResp == agentId) updatedResp = null;
                  }
                  onChanged(updatedIds, updatedResp);
                },
              ),
              const Divider(height: 1, indent: 16),
            ],
          );
        },
      ),
    );
  }
}

class _AjouterStructureDialog extends StatefulWidget {
  final String invId;
  final Set<int?> dejaLiees;
  final void Function(int structureId) onAjouter;

  const _AjouterStructureDialog({
    required this.invId,
    required this.dejaLiees,
    required this.onAjouter,
  });

  @override
  State<_AjouterStructureDialog> createState() => _AjouterStructureDialogState();
}

class _AjouterStructureDialogState extends State<_AjouterStructureDialog> {
  List<Structure> _structures = [];
  bool _loading = true;
  Structure? _selectionnee;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    try {
      final liste = await sl<AdminService>().getStructures();
      if (!mounted) return;
      setState(() {
        _structures = liste.where((s) => s.id != null && !widget.dejaLiees.contains(s.id)).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter une structure destinataire'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: _loading
            ? const SizedBox(height: 80, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
            : _structures.isEmpty
                ? const Text('Toutes les structures disponibles sont déjà destinataires de cette invitation.')
                : DropdownButtonFormField<Structure>(
                    value: _selectionnee,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Structure'),
                    items: _structures
                        .map((s) => DropdownMenuItem(value: s, child: Text(s.nom, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (s) => setState(() => _selectionnee = s),
                  ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: _selectionnee == null
              ? null
              : () {
                  widget.onAjouter(_selectionnee!.id!);
                  Navigator.pop(context);
                },
          style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 4, 61, 18), foregroundColor: Colors.white),
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF64748B)),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 14, color: Color.fromARGB(255, 9, 9, 10)),
            ),
          ),
        ],
      ),
    );
  }
}