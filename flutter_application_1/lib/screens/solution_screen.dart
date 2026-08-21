import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../theme/app_theme.dart';
import '../widget/shared_widget.dart';

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
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _tickets.length,
                        itemBuilder: (context, i) {
                          final t = _tickets[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: AppCard(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Expanded(
                                      child: Text('N°${t.id} — ${t.description}',
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                          maxLines: 2, overflow: TextOverflow.ellipsis),
                                    ),
                                    StatusBadge.fromTicketStatus(t.status),
                                  ]),
                                  const SizedBox(height: 10),
                                  const Text('Solution apportée',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.success)),
                                  const SizedBox(height: 4),
                                  Text(
                                    (t.solution != null && t.solution!.isNotEmpty) ? t.solution! : 'Aucun détail renseigné.',
                                    style: const TextStyle(fontSize: 12, color: AppColors.muted),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}