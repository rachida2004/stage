import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../theme/app_theme.dart';
import '../widget/shared_widget.dart';
import 'tickets_screen.dart' show TicketCard;

// 🎯 Base de connaissances partagée : liste TOUS les tickets résolus du
// système (pas seulement ceux de l'utilisateur connecté), avec la
// description du problème et la solution apportée — utile pour qu'un
// usager voie si un problème similaire au sien a déjà été résolu.
// Volontairement indépendant du TicketBloc (utilisé par l'onglet "Tickets")
// pour ne pas interférer avec sa pagination/son filtrage propre.
class MesTicketsSolutionsScreen extends StatefulWidget {
  const MesTicketsSolutionsScreen({super.key});

  @override
  State<MesTicketsSolutionsScreen> createState() => _MesTicketsSolutionsScreenState();
}

class _MesTicketsSolutionsScreenState extends State<MesTicketsSolutionsScreen> {
  List<Ticket> _tickets = [];
  bool _loading = true;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() { _loading = true; _erreur = null; });
    try {
      final tickets = await sl<TicketService>().getResolus();
      setState(() { _tickets = tickets; _loading = false; });
    } catch (e) {
      setState(() { _erreur = e.toString(); _loading = false; });
    }
  }

  // 🎯 Fenêtre dédiée à la lecture de la solution complète, plutôt que de
  // tout afficher en permanence dans chaque carte de la liste (illisible
  // dès qu'il y a beaucoup de tickets résolus avec des solutions longues).
  void _voirSolution(Ticket t) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Row(children: [
                Expanded(
                  child: Text('N°${t.id}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.muted)),
                ),
                StatusBadge.fromTicketStatus(t.status),
              ]),
              const SizedBox(height: 6),
              Text(t.description,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: 1.3)),
              const SizedBox(height: 10),
              Wrap(spacing: 14, runSpacing: 6, children: [
                _infoPuce(Icons.apartment_outlined, t.structure.isEmpty ? '—' : t.structure),
                if (t.agentAssigneNom != null) _infoPuce(Icons.person_outline, t.agentAssigneNom!),
                _infoPuce(Icons.schedule_outlined,
                    '${t.createdAt.day.toString().padLeft(2, '0')}/${t.createdAt.month.toString().padLeft(2, '0')}/${t.createdAt.year}'),
              ]),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF25A25A).withOpacity(0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: const [
                      Icon(Icons.lightbulb_outline, size: 16, color: Color(0xFF1B7A43)),
                      SizedBox(width: 6),
                      Text('Solution apportée',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF1B7A43))),
                    ]),
                    const SizedBox(height: 8),
                    Text(
                      (t.solution != null && t.solution!.isNotEmpty) ? t.solution! : 'Aucun détail renseigné.',
                      style: const TextStyle(fontSize: 13.5, color: Color(0xFF244B36), height: 1.45),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoPuce(IconData icone, String texte) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icone, size: 13, color: AppColors.muted),
      const SizedBox(width: 4),
      Text(texte, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tickets résolus')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _erreur != null
              ? Center(child: Text(_erreur!, style: const TextStyle(color: Colors.red)))
              : _tickets.isEmpty
                  ? const Center(child: Text("Aucun ticket résolu pour le moment."))
                  : RefreshIndicator(
                      onRefresh: _charger,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // 🎯 Même grille de cartes carrées que l'écran
                          // Tickets, pour une présentation cohérente.
                          final int colonnes = (constraints.maxWidth / 220).floor().clamp(2, 4);
                          return GridView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _tickets.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: colonnes,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.92,
                            ),
                            itemBuilder: (context, i) {
                              final t = _tickets[i];
                              // 🎯 Ici, taper une carte ouvre directement la
                              // solution (plutôt que le détail du ticket,
                              // pas pertinent dans une base de connaissance).
                              return TicketCard(ticket: t, onTap: () => _voirSolution(t));
                            },
                          );
                        },
                      ),
                    ),
    );
  }
}