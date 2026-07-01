import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/bloc/all_blocs.dart';
import 'package:flutter_application_1/models/models.dart';
import 'package:file_picker/file_picker.dart';
import '../services/services.dart';
import '../core/api_constants.dart';
import '../theme/app_theme.dart';
import '../widget/shared_widget.dart';
import 'invitations_screen.dart' show ouvrirPieceJointe;
import 'pdf_viewer_page.dart';

class EditInvitationPage extends StatefulWidget {
  final Invitation inv;
  const EditInvitationPage({super.key, required this.inv});

  @override
  State<EditInvitationPage> createState() => _EditInvitationPageState();
}

class _EditInvitationPageState extends State<EditInvitationPage> {
  late TextEditingController _objetCtrl;
  late TextEditingController _structCtrl;
  late TextEditingController _lieuCtrl;
  late TextEditingController _nbCtrl;
  
  late DateTime _dateDebut;
  late DateTime _dateFin;

  // 🎯 Pièces jointes : celles déjà existantes (lecture) + celles à envoyer
  late List<String> _fichiersExistants;
  final List<PlatformFile> _nouveauxFichiers = [];
  bool _envoiEnCours = false;

  @override
  void initState() {
    super.initState();
    _objetCtrl = TextEditingController(text: widget.inv.objet);
    _structCtrl = TextEditingController(text: widget.inv.structureEmettrice);
    _lieuCtrl = TextEditingController(text: widget.inv.lieu ?? '');
    _nbCtrl = TextEditingController(text: widget.inv.nombreParticipants.toString());
    _dateDebut = widget.inv.dateDebut;
    _dateFin = widget.inv.dateFin;
    _fichiersExistants = List<String>.from(widget.inv.files);
  }

  @override
  void dispose() {
    _objetCtrl.dispose();
    _structCtrl.dispose();
    _lieuCtrl.dispose();
    _nbCtrl.dispose();
    super.dispose();
  }

  // Fonction utilitaire pour choisir une date
  Future<void> _selectDate(BuildContext context, bool isDebut) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isDebut ? _dateDebut : _dateFin,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isDebut) {
          _dateDebut = picked;
        } else {
          _dateFin = picked;
        }
      });
    }
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
        withData: true,
      );
      if (result != null) {
        setState(() => _nouveauxFichiers.addAll(result.files));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sélection des fichiers: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _removeNouveauFichier(int index) {
    setState(() => _nouveauxFichiers.removeAt(index));
  }

  // 🎯 Le `chemin` brut renvoyé par le backend pour une pièce jointe (ex:
  // "/invitations/34/xxx.pdf") n'est pas une URL servable directement — il
  // faut le faire passer par la route de téléchargement /api/files/download/.
  // C'est l'oubli de ce préfixe qui causait l'erreur 400 à l'ouverture.
  String _urlTelechargement(String chemin) {
    if (chemin.startsWith('http')) return chemin;
    final chemainSansSlash = chemin.startsWith('/') ? chemin.substring(1) : chemin;
    return '${ApiConstants.baseUrl}/api/files/download/$chemainSansSlash';
  }

  // 🎯 Comme sur l'écran de détail : aperçu in-app (iframe) pour les PDF et
  // images, ouverture/téléchargement externe pour les formats qu'aucun
  // navigateur ne sait afficher nativement (docx, doc, xlsx...).
  void _ouvrirAvecApercu(String chemin) {
    final url = _urlTelechargement(chemin);
    final ext = url.split('.').last.toLowerCase().split('?').first;
    const previsualisable = ['pdf', 'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'];

    if (!previsualisable.contains(ext)) {
      ouvrirPieceJointe(url);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerPage(pdfUrl: url, title: url.split('/').last),
      ),
    );
  }

  void _submit() async {
    // 1. Validation de base
    if (_objetCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("L'objet est obligatoire"), backgroundColor: Colors.orange),
      );
      return;
    }
    
    if (_structCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("La structure émettrice est obligatoire"), backgroundColor: Colors.orange),
      );
      return;
    }

    // 🎯 Envoi des nouvelles pièces jointes en premier (s'il y en a), qu'il y
    // ait déjà des fichiers existants ou pas du tout au départ.
    if (_nouveauxFichiers.isNotEmpty) {
      setState(() => _envoiEnCours = true);
      try {
        final invMaj = await sl<InvitationService>().ajouterPiecesJointes(
          widget.inv.id,
          _nouveauxFichiers.map((f) => MapEntry(f.name, f.bytes!)).toList(),
        );
        setState(() {
          _fichiersExistants = List<String>.from(invMaj.files);
          _nouveauxFichiers.clear();
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erreur lors de l'envoi des pièces jointes : $e"), backgroundColor: Colors.red),
          );
        }
        setState(() => _envoiEnCours = false);
        return;
      }
      setState(() => _envoiEnCours = false);
    }

    // 2. Préparation des données strictement alignées avec le DTO Spring Boot
    final Map<String, dynamic> updatedData = {
      'objet': _objetCtrl.text.trim(),
      'structureEmettrice': _structCtrl.text.trim(), 
      'lieu': _lieuCtrl.text.trim().isEmpty ? null : _lieuCtrl.text.trim(),
      
      // Format LocalDate Java standard 'yyyy-MM-dd'
      'dateDebut': "${_dateDebut.year}-${_dateDebut.month.toString().padLeft(2, '0')}-${_dateDebut.day.toString().padLeft(2, '0')}",
      'dateFin': "${_dateFin.year}-${_dateFin.month.toString().padLeft(2, '0')}-${_dateFin.day.toString().padLeft(2, '0')}",
      
      'nombreParticipants': int.tryParse(_nbCtrl.text.trim()) ?? 0,
      'visibilite': 'PUBLIC', 
      'statut': widget.inv.status?.name ?? 'EN_ATTENTE', 
    };

    print("Envoi des données vers le backend: $updatedData");

    // 4. Envoi au BLoC
    context.read<InvitationBloc>().add(
      UpdateInvitation(widget.inv.id.toString(), updatedData)
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Modifier l'invitation")),
      body: BlocListener<InvitationBloc, InvitationState>(
        listener: (context, state) {
          // ════════════════════════════════════════════════════════════════════
          // INTERCEPTION DE L'ÉTAT MODIFIÉ (CORRECTION CLÉ)
          // ════════════════════════════════════════════════════════════════════
          if (state is InvitationSuccess) {
            // Affiche le snackbar AVANT de fermer la page
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Modification enregistrée !"), backgroundColor: Colors.green),
            );
            Navigator.pop(context, true); // true = signal de rafraichissement pour la page parente
          } else if (state is InvitationError) {
            showErrorSnack(context, state.msg);
          }
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(controller: _objetCtrl, decoration: const InputDecoration(labelText: "Objet")),
            const SizedBox(height: 15),
            TextField(controller: _structCtrl, decoration: const InputDecoration(labelText: "Structure émettrice")),
            const SizedBox(height: 15),
            TextField(controller: _lieuCtrl, decoration: const InputDecoration(labelText: "Lieu")),
            const SizedBox(height: 15),
            TextField(
              controller: _nbCtrl, 
              keyboardType: TextInputType.number, 
              decoration: const InputDecoration(labelText: "Nombre de Participants")
            ),
            const SizedBox(height: 20),
            
         

TextFormField(
  readOnly: true, // Empêche l'ouverture du clavier
  onTap: () => _selectDate(context, true), // Ouvre le calendrier au clic
  decoration: InputDecoration(
    labelText: "Date de début",
    hintText: "${_dateDebut.day}/${_dateDebut.month}/${_dateDebut.year}",
    floatingLabelBehavior: FloatingLabelBehavior.always, // Garde le label en haut
    suffixIcon: const Icon(Icons.calendar_today),
  ),
  // On utilise un contrôleur ou une valeur brute pour forcer l'affichage
  controller: TextEditingController(text: "${_dateDebut.day}/${_dateDebut.month}/${_dateDebut.year}"),
  style: const TextStyle(color: Colors.black87), // Force le texte en sombre
),

const SizedBox(height: 15), // Un petit espace entre les deux dates

TextFormField(
  readOnly: true,
  onTap: () => _selectDate(context, false),
  decoration: InputDecoration(
    labelText: "Date de fin",
    hintText: "${_dateFin.day}/${_dateFin.month}/${_dateFin.year}",
    floatingLabelBehavior: FloatingLabelBehavior.always,
    suffixIcon: const Icon(Icons.calendar_today),
  ),
  controller: TextEditingController(text: "${_dateFin.day}/${_dateFin.month}/${_dateFin.year}"),
  style: const TextStyle(color: Colors.black87),
),
            
            const SizedBox(height: 24),

            // ── Pièces jointes ──────────────────────────────────────
            const Text('Pièces jointes', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),

            // Fichiers déjà présents sur l'invitation
            if (_fichiersExistants.isEmpty && _nouveauxFichiers.isEmpty)
              const Text('Aucune pièce jointe pour le moment.', style: TextStyle(color: Colors.grey, fontSize: 13)),

            ..._fichiersExistants.map((url) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: InkWell(
                onTap: () => _ouvrirAvecApercu(url),
                child: Row(children: [
                  const Icon(Icons.attach_file, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(url.split('/').last,
                      style: const TextStyle(color: AppColors.primary, decoration: TextDecoration.underline, fontSize: 13),
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
                  const Icon(Icons.open_in_new, size: 14, color: AppColors.primary),
                ]),
              ),
            )),

            // Fichiers en attente d'envoi (pas encore uploadés)
            ..._nouveauxFichiers.asMap().entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                const Icon(Icons.insert_drive_file_outlined, size: 18, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(child: Text(entry.value.name,
                    style: const TextStyle(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                const Text('en attente', style: TextStyle(fontSize: 11, color: Colors.orange)),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () => _removeNouveauFichier(entry.key),
                ),
              ]),
            )),

            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _envoiEnCours ? null : _pickFiles,
              icon: const Icon(Icons.attach_file),
              label: const Text('Joindre un fichier'),
            ),

            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _envoiEnCours ? null : _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _envoiEnCours
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Enregistrer les modifications'),
            ),
          ],
        ),
      ),
    );
  }
}