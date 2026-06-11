import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:url_launcher/url_launcher.dart'; 
import 'package:flutter_application_1/bloc/all_blocs.dart';

import '../models/models.dart';
import '../services/services.dart';
import '../theme/app_theme.dart';
import '../widget/shared_widget.dart';
import '../core/api_constants.dart';

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
        final allInvitations = state is InvitationsLoaded ? state.page.items : <Invitation>[];
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
        _structCtrl.text.trim().isEmpty ||
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



class InvitationDetailScreen extends StatefulWidget {
  final Invitation inv;
  const InvitationDetailScreen({super.key, required this.inv});

  @override
  State<InvitationDetailScreen> createState() => _InvitationDetailScreenState();
}

class _InvitationDetailScreenState extends State<InvitationDetailScreen> {
  final List<String> _selectedAgentIds = []; 
  String? _responsableId;

  // Configuration de l'URL de ton serveur de gestion DSI (Ajuste l'adresse en prod ou préprod)
  // Utilise "http://10.0.2.2:8080" pour tester depuis un émulateur Android vers ton localhost
  static final String _baseUrl = kIsWeb ? "http://localhost:8085" : "http://10.0.2.2:8085";

  @override
  void initState() {
    super.initState();
    _selectedAgentIds.addAll(widget.inv.agentsAffectes.map((a) => a.id.toString()));
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

 // ─── 1. OUVERTURE ET TÉLÉCHARGEMENT DE LA PIÈCE JOINTE ──────────────────────
  void _openFile(BuildContext context, String fileUrlOrName) async {
    String targetUrl = fileUrlOrName;

    // Décodage si la chaîne reçue ressemble à "nom: doc.pdf, chemin: 45_doc.pdf"
    if (fileUrlOrName.contains('chemin:')) {
      final cheminMatch = RegExp(r"chemin:\s*([^,}]+)").firstMatch(fileUrlOrName);
      if (cheminMatch != null) targetUrl = cheminMatch.group(1)!.trim();
    }

    // Si c'est un nom de fichier ou un chemin relatif, on ajoute le préfixe Spring Boot
    if (!targetUrl.startsWith('http')) {
      // 🎯 Sécurité : On retire le premier caractère si c'est un slash '/'
      if (targetUrl.startsWith('/')) {
        targetUrl = targetUrl.substring(1);
      }
      
      // On s'assure d'avoir une URL propre avec un seul slash après download
      targetUrl = "$_baseUrl/api/files/download/$targetUrl";
    }

    // Petit log de contrôle bien pratique en console de debug 
    print("🎯 URL finale appelée : $targetUrl");

    final Uri url = Uri.parse(targetUrl);

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Impossible d\'ouvrir le lien système';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'ouverture : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ─── 2. EXPORT ET TÉLÉCHARGEMENT DU DOCUMENT PDF ────────────────────────────
  Future<void> _exportPdf(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export PDF en cours…'),
        backgroundColor: Color(0xFF2ECC71),
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
        backgroundColor: Colors.blue,
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2ECC71),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Détail invitation',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _showAffectationModal(context),
            icon: const Icon(Icons.person_add_outlined, size: 20, color: Colors.white),
            label: const Text(
              'Affecter',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      backgroundColor: const Color(0xFFF1F5F9),
      body: BlocBuilder<InvitationBloc, InvitationState>(
        builder: (context, state) {
          Invitation invitationAffichee = widget.inv;
          if (state is InvDetailLoaded) {
            invitationAffichee = state.inv;
          }

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
                    StatusBadge.fromInvStatus(invitationAffichee.status),
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
                                  const Icon(Icons.insert_drive_file_outlined, color: Color(0xFF2ECC71), size: 22),
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

              // ── Agents affectés ───────────────────────────────────────────
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

              // ── Bouton Exporter en PDF ────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => _exportPdf(context),
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
                  label: const Text('Exporter en PDF', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2ECC71),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ── Bouton Exporter en Word ───────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => _exportWord(context),
                  icon: const Icon(Icons.download_outlined, size: 20),
                  label: const Text('Exporter en Word', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          );
        },
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
              backgroundColor: const Color(0xFF2ECC71),
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
                activeColor: const Color(0xFF2ECC71),
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF64748B)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, color: Color.fromARGB(255, 9, 9, 10)),
          ),
        ],
      ),
    );
  }
}