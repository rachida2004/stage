import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/services.dart';
import '../core/api_constants.dart';
import '../theme/app_theme.dart';

/// 🎯 Écran dédié à l'archivage physique des lettres officielles
/// (invitations créées en mode "CREER", donc avec numéro de référence).
/// Volontairement indépendant du InvitationBloc / de la liste Reçu-Envoyer :
/// sa propre recherche (numéro / année) et son propre état local, pour
/// éviter tout partage d'état fragile avec l'écran principal des invitations.
class ArchivageInvitationsScreen extends StatefulWidget {
  const ArchivageInvitationsScreen({super.key});

  @override
  State<ArchivageInvitationsScreen> createState() => _ArchivageInvitationsScreenState();
}

class _ArchivageInvitationsScreenState extends State<ArchivageInvitationsScreen> {
  final _numeroCtrl = TextEditingController();
  String? _anneeFiltre;
  List<Map<String, dynamic>> _resultats = [];
  String? _dernierNumero;
  bool _loading = true;
  String? _erreur;
  Timer? _debounce;

  static final List<String> _annees = List.generate(
    6, (i) => (DateTime.now().year - i).toString());

  @override
  void initState() {
    super.initState();
    _chargerDernierNumero();
    _rechercher();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _numeroCtrl.dispose();
    super.dispose();
  }

  Future<void> _chargerDernierNumero() async {
    try {
      final n = await sl<InvitationService>().dernierNumeroReference();
      if (mounted) setState(() => _dernierNumero = n);
    } catch (_) {
      // 🎯 Purement informatif : une erreur ici ne doit pas bloquer le reste de l'écran.
    }
  }

  Future<void> _rechercher() async {
    setState(() { _loading = true; _erreur = null; });
    try {
      final res = await sl<InvitationService>().rechercherArchives(
        numeroReference: _numeroCtrl.text.trim().isEmpty ? null : _numeroCtrl.text.trim(),
        annee: _anneeFiltre,
      );
      if (mounted) setState(() { _resultats = res; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _erreur = e.toString(); _loading = false; });
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _rechercher);
  }

  // 🎯 CORRECTIF : le `chemin` brut renvoyé par le backend pour un document
  // archivé (ex: "invitations/26/507a07b4-..._invitation_26.pdf") n'est PAS
  // servable directement à la racine — il faut passer par la route publique
  // /api/files/download/, comme c'est déjà fait pour les autres pièces
  // jointes (voir edit_invitation_screen.dart / invitations_screen.dart).
  // L'ancien code ouvrait "${baseUrl}/$chemin" (sans ce préfixe), qui tombe
  // sur une route non explicitement publique côté Spring Security → 403.
  Future<void> _ouvrirDocument(String chemin) async {
    String urlFinale;
    if (chemin.startsWith('http')) {
      urlFinale = chemin;
    } else {
      final cheminSansSlash = chemin.startsWith('/') ? chemin.substring(1) : chemin;
      urlFinale = '${ApiConstants.baseUrl}/api/files/download/$cheminSansSlash';
    }
    final url = Uri.parse(urlFinale);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Impossible d'ouvrir le document."), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _ouvrirChoixCapture(Map<String, dynamic> archive) async {
    // 🎯 On demande d'abord la date réellement écrite/signée sur le
    // courrier papier — distincte de la date d'import technique, qui sera,
    // elle, générée automatiquement par le serveur au moment de l'envoi.
    final DateTime? dateSignature = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      helpText: 'Date écrite sur la lettre',
      cancelText: 'Annuler',
      confirmText: 'Continuer',
      builder: (ctx, child) => Theme(data: AppTheme.lightTheme, child: child!),
    );
    if (dateSignature == null) return; // annulé par l'utilisateur
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Ajouter le document imprimé et signé',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: Color.fromARGB(255, 5, 65, 30)),
              title: const Text('Prendre une photo',
                  style: TextStyle(fontSize: 15, color: Color(0xFF1A1A2E), fontWeight: FontWeight.w500)),
              onTap: () { Navigator.pop(sheetContext); _capturerDepuisCamera(archive, dateSignature); },
            ),
            ListTile(
              leading: const Icon(Icons.upload_file_outlined, color: Color.fromARGB(255, 5, 65, 30)),
              title: const Text('Importer un fichier',
                  style: TextStyle(fontSize: 15, color: Color(0xFF1A1A2E), fontWeight: FontWeight.w500)),
              subtitle: const Text('Scan PDF ou image depuis l\'appareil',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              onTap: () { Navigator.pop(sheetContext); _importerFichier(archive, dateSignature); },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _capturerDepuisCamera(Map<String, dynamic> archive, DateTime dateSignature) async {
    try {
      final XFile? photo = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 85);
      if (photo == null) return; // annulé par l'utilisateur
      final bytes = await photo.readAsBytes();
      await _envoyerDocument(archive, bytes, photo.name, dateSignature);
    } catch (e) {
      _afficherErreur('Capture photo impossible : $e');
    }
  }

  Future<void> _importerFichier(Map<String, dynamic> archive, DateTime dateSignature) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
        withData: true, // 🎯 nécessaire pour obtenir les bytes sur Web
      );
      if (result == null || result.files.isEmpty) return; // annulé
      final file = result.files.first;
      if (file.bytes == null) {
        _afficherErreur("Impossible de lire ce fichier depuis cet appareil.");
        return;
      }
      await _envoyerDocument(archive, file.bytes!, file.name, dateSignature);
    } catch (e) {
      _afficherErreur('Import du fichier impossible : $e');
    }
  }

  Future<void> _envoyerDocument(Map<String, dynamic> archive, Uint8List bytes, String filename, DateTime dateSignature) async {
    setState(() => _loading = true);
    try {
      await sl<InvitationService>().archiverDocument(
        archive['id'].toString(), bytes, filename, dateSignature: dateSignature);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Document archivé avec succès'),
          backgroundColor: Color.fromARGB(255, 11, 67, 32),
        ));
      }
      await _rechercher();
    } catch (e) {
      _afficherErreur('Échec de l\'archivage : $e');
      setState(() => _loading = false);
    }
  }

  void _afficherErreur(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 5, 65, 30),
        foregroundColor: Colors.white,
        title: const Text('Archivage des invitations'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_outlined), onPressed: _rechercher),
        ],
      ),
      body: Column(
        children: [
          // ── Rappel du dernier numéro utilisé ──────────────────────────
          if (_dernierNumero != null)
            Container(
              width: double.infinity,
              color: const Color(0xFFE8F5E9),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Color(0xFF1B5E20)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Dernier numéro utilisé : $_dernierNumero',
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF1B5E20), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

          // ── Recherche ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                TextField(
                  controller: _numeroCtrl,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Rechercher par numéro de référence…',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                ),
                const SizedBox(height: 8),
                // 🎯 Remplace la rangée de chips par un dropdown, pour rester
                // cohérent avec l'écran Invitations.
                DropdownButtonFormField<String?>(
                  value: _anneeFiltre,
                  isExpanded: true,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    prefixIcon: const Icon(Icons.event_outlined, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('Toutes années')),
                    // 🎯 _annees est recalculée à partir de DateTime.now().year :
                    // les années futures apparaissent automatiquement.
                    ..._annees.map((a) => DropdownMenuItem<String?>(value: a, child: Text(a))),
                  ],
                  onChanged: (val) { setState(() => _anneeFiltre = val); _rechercher(); },
                ),
              ],
            ),
          ),

          // ── Liste des résultats ───────────────────────────────────────
          Expanded(child: _buildListe()),
        ],
      ),
    );
  }

  Widget _chipAnnee(String label, String? valeur) {
    final selectionne = _anneeFiltre == valeur;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: selectionne ? Colors.white : Colors.black87)),
      selected: selectionne,
      onSelected: (_) { setState(() => _anneeFiltre = valeur); _rechercher(); },
      selectedColor: const Color.fromARGB(255, 5, 65, 30),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFFE2E8F0))),
    );
  }

  Widget _buildListe() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_erreur != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_erreur!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
        ),
      );
    }
    if (_resultats.isEmpty) {
      return const Center(
        child: Text('Aucune lettre officielle archivable trouvée', style: TextStyle(color: Color(0xFF94A3B8))),
      );
    }
    return RefreshIndicator(
      onRefresh: _rechercher,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        itemCount: _resultats.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final a = _resultats[i];
          final bool estArchive = a['estArchive'] == true;
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        (a['numeroReference'] as String?) ?? '—',
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: estArchive ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        estArchive ? 'Archivé' : 'À archiver',
                        style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600,
                          color: estArchive ? const Color(0xFF1B5E20) : const Color(0xFFE65100),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text((a['objet'] as String?) ?? '', style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
                if (estArchive && a['dateSignature'] != null) ...[
                  const SizedBox(height: 2),
                  Text('Signée le ${a['dateSignature']}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                ],
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: estArchive
                      ? OutlinedButton.icon(
                          onPressed: () => _ouvrirDocument(a['cheminDocumentArchive'] as String),
                          icon: const Icon(Icons.visibility_outlined, size: 16),
                          label: const Text('Voir le document archivé', style: TextStyle(fontSize: 12.5)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color.fromARGB(255, 5, 65, 30),
                            side: const BorderSide(color: Color.fromARGB(255, 5, 65, 30)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: () => _ouvrirChoixCapture(a),
                          icon: const Icon(Icons.add_a_photo_outlined, size: 16),
                          label: const Text('Ajouter le document', style: TextStyle(fontSize: 12.5)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 5, 65, 30),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}