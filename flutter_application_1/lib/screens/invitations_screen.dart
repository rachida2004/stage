import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
// ✅ Import requis pour faire fonctionner launchUrl directement ici
import 'package:url_launcher/url_launcher.dart'; 

import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widget/shared_widget.dart';
import '../bloc/all_blocs.dart';
import '../core/api_constants.dart'; // Requis pour charger l'URL de base du backend

class InvitationsScreen extends StatefulWidget {
  const InvitationsScreen({super.key});

  @override
  State<InvitationsScreen> createState() => _InvitationsScreenState();
}

class _InvitationsScreenState extends State<InvitationsScreen> {
  String _search = '';
  InvitationStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    context.read<InvitationBloc>().add(LoadInvitations());
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
            SnackBar(content: Text(state.msg), backgroundColor: AppColors.success),
          );
          context.read<InvitationBloc>().add(LoadInvitations());
        }
        if (state is InvitationError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.msg), backgroundColor: AppColors.danger),
          );
        }
      },
      builder: (context, state) {
        final allInvitations = state is InvitationsLoaded
            ? state.page.items
            : <Invitation>[];
        final filtered = _applyFilters(allInvitations);
        final loading = state is InvitationLoading;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Invitations'),
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
                onPressed: () => context.read<InvitationBloc>().add(LoadInvitations()),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            heroTag: 'fab_invitations',
            onPressed: () => _showAddDialog(context),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            child: const Icon(Icons.add),
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
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'Toutes',
                            selected: _filterStatus == null,
                            onTap: () => setState(() => _filterStatus = null),
                          ),
                          const SizedBox(width: 6),
                          ...InvitationStatus.values.map((s) => Padding(
                                padding: const EdgeInsets.only(right: 6),
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
                        onRefresh: () async =>
                            context.read<InvitationBloc>().add(LoadInvitations()),
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
      MaterialPageRoute(builder: (_) => _InvitationDetailScreen(inv: inv)),
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
                    StatusBadge.fromInvStatus(inv.status),
                    const SizedBox(width: 8),
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
  final _objetCtrl  = TextEditingController();
  final _structCtrl = TextEditingController();
  final _lieuCtrl   = TextEditingController();
  final _nbCtrl     = TextEditingController();
  DateTime? _dateDebut;
  DateTime? _dateFin;

  final List<PlatformFile> _selectedFiles = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _objetCtrl.dispose();
    _structCtrl.dispose();
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
        withData: true, // ✨ FIX : true pour TOUTES les plateformes (Web + Mobile)
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
        _structCtrl.text.trim().isEmpty ||
        _dateDebut == null ||
        _dateFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Veuillez remplir les champs obligatoires (*)'),
          backgroundColor: AppColors.danger));
      return;
    }

    // ✨ FIX : Plus besoin de distinction Web/Mobile complexe. 
    // On extrait les octets directement pour tout le monde.
    final List<MapEntry<String, Uint8List>> fileBytes = _selectedFiles
        .where((f) => f.bytes != null)
        .map((f) => MapEntry(f.name, f.bytes!))
        .toList();

    context.read<InvitationBloc>().add(CreateInvitation(
      {
        'objet': _objetCtrl.text.trim(),
        'structureEmettrice': _structCtrl.text.trim(),
        'dateDebut':
            '${_dateDebut!.year}-${_dateDebut!.month.toString().padLeft(2, '0')}-${_dateDebut!.day.toString().padLeft(2, '0')}',
        'dateFin':
            '${_dateFin!.year}-${_dateFin!.month.toString().padLeft(2, '0')}-${_dateFin!.day.toString().padLeft(2, '0')}',
        if (_lieuCtrl.text.trim().isNotEmpty) 'lieu': _lieuCtrl.text.trim(),
        if (_nbCtrl.text.trim().isNotEmpty)
          'nombreParticipants': int.tryParse(_nbCtrl.text.trim()) ?? 0,
      },
      filePaths: const [], // Tu peux laisser vide ou le supprimer selon la signature de ton Event
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
                TextField(
                  controller: _objetCtrl,
                  decoration: const InputDecoration(labelText: "Objet de l'invitation *"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _structCtrl,
                  decoration: const InputDecoration(labelText: 'Structure émettrice *'),
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
                      color: AppColors.surface,
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
                            color: AppColors.muted,
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

// ── Écran de Détail ─────────────────────────────────────────────────

class _InvitationDetailScreen extends StatelessWidget {
  final Invitation inv;
  const _InvitationDetailScreen({required this.inv});

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  void _openFile(BuildContext context, String fileUrlOrName) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tentative d\'ouverture de la pièce jointe...'),
        backgroundColor: AppColors.primary,
        duration: Duration(seconds: 1),
      ),
    );
    await ouvrirPieceJointe(fileUrlOrName);
  }

  // ✅ Appelle directement l'API de génération PDF globale
  void _exportToPDF(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Génération du PDF en cours...'),
        backgroundColor: AppColors.primary,
        duration: Duration(seconds: 1),
      ),
    );
    await ouvrirPieceJointe("api/invitations/${inv.id}/export/pdf");
  }

  // ✅ Appelle directement l'API de génération Word globale
  void _exportToWord(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Génération du document Word en cours...'),
        backgroundColor: AppColors.primary,
        duration: Duration(seconds: 1),
      ),
    );
    await ouvrirPieceJointe("api/invitations/${inv.id}/export/word");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail invitation'),
        actions: [
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.person_add_outlined, size: 18),
            label: const Text('Affecter'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inv.objet,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                StatusBadge.fromInvStatus(inv.status),
                const SizedBox(height: 16),
                const Divider(),
                _DetailRow(
                  icon: Icons.business_outlined,
                  label: 'Structure émettrice',
                  value: inv.structureEmettrice,
                ),
                _DetailRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Date de début',
                  value: _fmt(inv.dateDebut),
                ),
                _DetailRow(
                  icon: Icons.event_outlined,
                  label: 'Date de fin',
                  value: _fmt(inv.dateFin),
                ),
                _DetailRow(
                  icon: Icons.location_on_outlined,
                  label: 'Lieu',
                  value: inv.lieu ?? 'Non précisé',
                ),
                _DetailRow(
                  icon: Icons.group_outlined,
                  label: 'Participants',
                  value: inv.nombreParticipants > 0 ? '${inv.nombreParticipants}' : 'Non défini',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pièces jointes associées',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 10),
                if (inv.files.isEmpty)
                  const Text(
                    'Aucune pièce jointe pour cette invitation',
                    style: TextStyle(fontSize: 13, color: AppColors.muted),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: inv.files.length,
                    itemBuilder: (context, index) {
                      final rawFileString = inv.files[index];
                      
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
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.insert_drive_file_outlined,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  displayName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.primary,
                                    decoration: TextDecoration.underline,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(
                                Icons.visibility_outlined,
                                size: 16,
                                color: AppColors.muted,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Agents affectés',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 10),
                if (inv.agentsAffectes.isEmpty)
                  const Text(
                    'Aucun agent affecté',
                    style: TextStyle(fontSize: 13, color: AppColors.muted),
                  )
                else
                  ...inv.agentsAffectes.map((agent) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            UserAvatar(initials: agent.initiales, size: 30),
                            const SizedBox(width: 8),
                            Text(
                              '${agent.nom}${agent.prenom != null ? ' ${agent.prenom}' : ''}',
                              style: const TextStyle(fontSize: 13),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Agent',
                                style: TextStyle(fontSize: 11, color: AppColors.primaryDark),
                              ),
                            ),
                          ],
                        ),
                      )),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // ✅ Bouton PDF lié à l'API via _exportToPDF
          ElevatedButton.icon(
            onPressed: () => _exportToPDF(context),
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
            label: const Text('Exporter en PDF'),
          ),
          const SizedBox(height: 8),
          // ✅ Bouton Word lié à l'API via _exportToWord
          OutlinedButton.icon(
            onPressed: () => _exportToWord(context),
            icon: const Icon(Icons.download_outlined, size: 18),
            label: const Text('Exporter en Word'),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.muted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ── Fonction Globale Locale pour l'ouverture de fichiers corrigée ───────────────────
Future<void> ouvrirPieceJointe(String urlCompleteOuRelative) async {
  String urlString = urlCompleteOuRelative.trim();
  
  if (urlString.contains('url:')) {
    final match = RegExp(r"url:\s*([^,}]+)").firstMatch(urlString);
    if (match != null) {
      urlString = match.group(1)!.trim();
    }
  }

  if (urlString.endsWith('}')) {
    urlString = urlString.substring(0, urlString.length - 1).trim();
  }

  if (!urlString.startsWith('http://') && !urlString.startsWith('https://')) {
    final cleanPath = urlString.startsWith('/') ? urlString.substring(1) : urlString;
    
    String baseUrl = ApiConstants.baseUrl.endsWith('/') 
        ? ApiConstants.baseUrl 
        : '${ApiConstants.baseUrl}/';
        
    // ⬇️ CORRECTION ICI : Si le chemin relatif commence déjà par 'api/', 
    // on retire temporairement le '/api/' de la baseUrl pour éviter le doublon.
    if (cleanPath.startsWith('api/')) {
      baseUrl = baseUrl.replaceAll('/api/', '/');
    }
    // Gestion existante pour le dossier uploads direct
    else if (cleanPath.startsWith('uploads/') && baseUrl.contains('/api/')) {
      baseUrl = baseUrl.replaceAll('/api/', '/');
    }
        
    urlString = '$baseUrl$cleanPath';
  }

  final Uri url = Uri.parse(Uri.encodeFull(urlString));

  try {
    print('Tentative d\'ouverture de l\'URL finale : $urlString');

    final bool lance = await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );
    if (!lance) {
      throw "Impossible d'ouvrir l'URL : $urlString";
    }
  } catch (e) {
    print('Erreur lors de l\'ouverture du fichier : $e');
  }
}