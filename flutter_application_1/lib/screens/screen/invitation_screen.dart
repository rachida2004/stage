import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:flutter_application_1/bloc/all_blocs.dart';

import '../../models/models.dart';
import '../../services/services.dart';
import '../../theme/app_theme.dart';

/// ════════════════════════════════════════════════════════════════════
/// FORMULAIRE DE CRÉATION D'UNE LETTRE D'INVITATION OFFICIELLE
/// ════════════════════════════════════════════════════════════════════
/// Reprend la structure de la lettre du Secrétariat général :
/// en-tête (structure émettrice / Burkina Faso), référence, qualité du
/// signataire, destinataire(s), objet, corps, pièce jointe, ampliation
/// et signature.
///
/// Les structures destinataires sont sélectionnées depuis la base de
/// données (table `structure_invitee`, via GET /api/structures) — il ne
/// s'agit plus d'une saisie en texte libre.
class InvitationScreen extends StatefulWidget {
  const InvitationScreen({super.key});

  @override
  State<InvitationScreen> createState() => _InvitationScreenState();
}

class _InvitationScreenState extends State<InvitationScreen> {
  final _objetCtrl              = TextEditingController();
  final _numeroRefCtrl          = TextEditingController();
  final _villeCtrl              = TextEditingController(text: 'Ouagadougou');
  final _lieuCtrl                = TextEditingController();
  final _nbCtrl                  = TextEditingController();
  final _contenuCtrl             = TextEditingController();
  final _ampliationCtrl          = TextEditingController();
  final _signataireNomCtrl       = TextEditingController();
  final _signataireQualiteCtrl   = TextEditingController(text: 'Le Secrétaire général');

  DateTime? _dateDebut;
  DateTime? _dateFin;

  List<Structure> _structures = [];
  bool _loadingStructures = true;
  Structure? _structureEmettrice;
  final Set<int> _structuresDestinatairesIds = {};

  final List<PlatformFile> _selectedFiles = [];

  @override
  void initState() {
    super.initState();
    _chargerStructures();
  }

  Future<void> _chargerStructures() async {
    try {
      final liste = await sl<AdminService>().getStructures();
      if (!mounted) return;
      setState(() {
        _structures = liste;
        _loadingStructures = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingStructures = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de charger les structures : $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  void dispose() {
    _objetCtrl.dispose();
    _numeroRefCtrl.dispose();
    _villeCtrl.dispose();
    _lieuCtrl.dispose();
    _nbCtrl.dispose();
    _contenuCtrl.dispose();
    _ampliationCtrl.dispose();
    _signataireNomCtrl.dispose();
    _signataireQualiteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isDebut) async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
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
        setState(() => _selectedFiles.addAll(result.files));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sélection des fichiers : $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  void _removeFile(int index) => setState(() => _selectedFiles.removeAt(index));

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  void _submit() {
    if (_objetCtrl.text.trim().isEmpty ||
        _dateDebut == null ||
        _dateFin == null ||
        _structuresDestinatairesIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
          'Veuillez remplir les champs obligatoires (*) et choisir au moins une structure destinataire.',
        ),
        backgroundColor: AppColors.danger,
      ));
      return;
    }

    final List<MapEntry<String, Uint8List>> fileBytes = _selectedFiles
        .where((f) => f.bytes != null)
        .map((f) => MapEntry(f.name, f.bytes!))
        .toList();

    context.read<InvitationBloc>().add(CreateInvitation(
      {
        'objet': _objetCtrl.text.trim(),
        if (_structureEmettrice != null) 'structureEmettriceId': _structureEmettrice!.id,
        'lieu': _lieuCtrl.text.trim(),
        'dateDebut':
            '${_dateDebut!.year}-${_dateDebut!.month.toString().padLeft(2, '0')}-${_dateDebut!.day.toString().padLeft(2, '0')}',
        'dateFin':
            '${_dateFin!.year}-${_dateFin!.month.toString().padLeft(2, '0')}-${_dateFin!.day.toString().padLeft(2, '0')}',
        'nombreParticipants': int.tryParse(_nbCtrl.text.trim()) ?? 0,
        'numeroReference': _numeroRefCtrl.text.trim(),
        'ville': _villeCtrl.text.trim().isEmpty ? 'Ouagadougou' : _villeCtrl.text.trim(),
        'contenu': _contenuCtrl.text.trim(),
        'ampliation': _ampliationCtrl.text.trim(),
        'signataireNom': _signataireNomCtrl.text.trim(),
        'signataireQualite': _signataireQualiteCtrl.text.trim(),
        'structureIds': _structuresDestinatairesIds.toList(),
        'modeCreation': 'CREER',
      },
      filePaths: const [],
      fileBytes: fileBytes,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<InvitationBloc, InvitationState>(
      listener: (context, state) {
        if (state is InvitationSuccess && mounted) {
          Navigator.of(context).maybePop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          title: const Text("Créer une lettre d'invitation"),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Aperçu de l'en-tête officiel ───────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 0.6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _loadingStructures
                              ? const SizedBox(
                                  height: 40,
                                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                )
                              : DropdownButtonFormField<Structure>(
                                  value: _structureEmettrice,
                                  isExpanded: true,
                                  decoration: const InputDecoration(labelText: 'Structure émettrice'),
                                  items: _structures
                                      .map((s) => DropdownMenuItem(
                                            value: s,
                                            child: Text(s.nom, overflow: TextOverflow.ellipsis),
                                          ))
                                      .toList(),
                                  onChanged: (s) => setState(() => _structureEmettrice = s),
                                ),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('BURKINA FASO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            SizedBox(height: 2),
                            Text(
                              'La Patrie ou la Mort,\nNous vaincrons',
                              textAlign: TextAlign.right,
                              style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: AppColors.muted),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _numeroRefCtrl,
                            decoration: const InputDecoration(
                              labelText: 'N° référence',
                              hintText: 'ex: 2025/000749/MESFPT/SG/DGAS',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _villeCtrl,
                            decoration: const InputDecoration(labelText: 'Ville'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Qualité du signataire ──────────────────────────────
              TextField(
                controller: _signataireQualiteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Qualité du signataire',
                  hintText: 'ex: Le Secrétaire général',
                ),
              ),
              const SizedBox(height: 16),

              // ── Structures destinataires (table structure_invitee) ─
              const Text('Structure(s) destinataire(s) *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              const Text(
                'Sélectionnez une ou plusieurs structures invitées, enregistrées dans la base.',
                style: TextStyle(fontSize: 11, color: AppColors.muted),
              ),
              const SizedBox(height: 8),
              if (_loadingStructures)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else if (_structures.isEmpty)
                const Text('Aucune structure trouvée dans la base.', style: TextStyle(color: AppColors.muted))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _structures.map((s) {
                    final selected = s.id != null && _structuresDestinatairesIds.contains(s.id);
                    return FilterChip(
                      label: Text(s.nom),
                      selected: selected,
                      selectedColor: AppColors.primary.withOpacity(0.15),
                      checkmarkColor: AppColors.primary,
                      onSelected: (v) {
                        if (s.id == null) return;
                        setState(() {
                          if (v) {
                            _structuresDestinatairesIds.add(s.id!);
                          } else {
                            _structuresDestinatairesIds.remove(s.id!);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              const SizedBox(height: 16),

              TextField(
                controller: _objetCtrl,
                decoration: const InputDecoration(labelText: 'Objet *'),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _pickDate(true),
                      child: AbsorbPointer(
                        child: TextField(
                          controller: TextEditingController(text: _dateDebut != null ? _fmt(_dateDebut!) : ''),
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
                          controller: TextEditingController(text: _dateFin != null ? _fmt(_dateFin!) : ''),
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

              const Text('Corps de la lettre', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              const Text(
                "Laissez vide pour générer automatiquement un texte standard à partir de l'objet, des dates et du lieu.",
                style: TextStyle(fontSize: 11, color: AppColors.muted),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _contenuCtrl,
                maxLines: 8,
                decoration: const InputDecoration(
                  alignLabelWithHint: true,
                  hintText: "Madame, Monsieur,\n\nNous avons l'honneur de vous inviter à...",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              const Text('Pièces jointes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: _pickFiles,
                icon: const Icon(Icons.attach_file, size: 18),
                label: const Text('Joindre un fichier (ex: chronogramme)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 0.8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              if (_selectedFiles.isNotEmpty) ...[
                const SizedBox(height: 8),
                ...List.generate(_selectedFiles.length, (index) {
                  final f = _selectedFiles[index];
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.insert_drive_file_outlined, size: 20),
                    title: Text(f.name, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => _removeFile(index),
                    ),
                  );
                }),
              ],
              const SizedBox(height: 16),

              TextField(
                controller: _ampliationCtrl,
                decoration: const InputDecoration(labelText: 'Ampliation', hintText: 'ex: MESFPT/ATCR'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _signataireNomCtrl,
                decoration: const InputDecoration(labelText: 'Nom du signataire', hintText: 'ex: Rachid BARRO'),
              ),
              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.send_outlined),
                label: const Text('Créer et enregistrer la lettre'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 6, 69, 21),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}