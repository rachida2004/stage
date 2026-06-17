import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/bloc/all_blocs.dart';
import 'package:flutter_application_1/models/models.dart';

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

  @override
  void initState() {
    super.initState();
    _objetCtrl = TextEditingController(text: widget.inv.objet);
    _structCtrl = TextEditingController(text: widget.inv.structureEmettrice);
    _lieuCtrl = TextEditingController(text: widget.inv.lieu ?? '');
    _nbCtrl = TextEditingController(text: widget.inv.nombreParticipants.toString());
    _dateDebut = widget.inv.dateDebut;
    _dateFin = widget.inv.dateFin;
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

  void _submit() {
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.msg), backgroundColor: Colors.red),
            );
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
            
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Enregistrer les modifications'),
            ),
          ],
        ),
      ),
    );
  }
}