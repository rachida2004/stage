import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher; 
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widget/shared_widget.dart';
import '../bloc/all_blocs.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});
  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  String _search = '';
  TicketStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    context.read<TicketBloc>().add(LoadTickets());
  }

  List<Ticket> _applyFilters(List<Ticket> all) {
    return all.where((t) {
      final matchSearch = t.description.toLowerCase().contains(_search.toLowerCase()) ||
          t.id.contains(_search);
      final matchStatus = _filterStatus == null || t.status == _filterStatus;
      return matchSearch && matchStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TicketBloc, TicketState>(
      builder: (context, state) {
        List<Ticket> allTickets = [];
        bool isLoading = state is TicketLoading;

        if (state is TicketsLoaded) {
          allTickets = state.page.items;
        } else if (state is TicketError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Tickets')),
            body: Center(child: Text('Erreur : ${state.msg}', style: const TextStyle(color: Colors.red))),
          );
        } else {
          allTickets = SampleData.tickets;
        }

        final filtered = _applyFilters(allTickets);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Tickets'),
            actions: [
              if (isLoading)
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
                  onChanged: (v) => setState(() => _search = v),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    _FilterChip(
                      label: 'Tous',
                      selected: _filterStatus == null,
                      onTap: () => setState(() => _filterStatus = null),
                    ),
                    const SizedBox(width: 6),
                    ...TicketStatus.values.map((s) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _FilterChip(
                          label: s.label,
                          selected: _filterStatus == s,
                          onTap: () => setState(
                              () => _filterStatus = _filterStatus == s ? null : s),
                        ),
                      )),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filtered.isEmpty && !isLoading
                  ? const Center(
                      child: Text(
                        'Aucun ticket trouvé',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async =>
                          context.read<TicketBloc>().add(LoadTickets()),
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) => _TicketCard(
                          ticket: filtered[i],
                          onTap: () => Navigator.push(
                            ctx,
                            MaterialPageRoute(
                              builder: (_) =>
                                  _TicketDetailScreen(ticket: filtered[i]),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ]),
        );
      },
    );
  }

  void _showCreateTicketSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CreateTicketSheet(), 
      backgroundColor: Colors.white,
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

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
              width: 0.5),
        ),
        child: Text(label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: selected ? Colors.white : AppColors.muted)),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback onTap;
  const _TicketCard({required this.ticket, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Color iconBg;
    switch (ticket.priority) {
      case TicketPriority.haute:
        iconBg = AppColors.dangerLight;
        break;
      case TicketPriority.normale:
        iconBg = AppColors.warningLight;
        break;
      case TicketPriority.basse:
        iconBg = AppColors.successLight;
        break;
    }
    return AppCard(
      onTap: onTap,
      child: Row(children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
              color: iconBg, borderRadius: BorderRadius.circular(10)),
          child: Center(
              child: Text('#${ticket.id}',
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(ticket.description,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Text(
              ticket.agentAssigneNom != null
                  ? 'Agent: ${ticket.agentAssigneNom}'
                  : 'Non affecté',
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
            const SizedBox(height: 6),
            Row(children: [
              StatusBadge.fromTicketStatus(ticket.status),
              const SizedBox(width: 8),
              PriorityBadge(priority: ticket.priority),
            ]),
          ]),
        ),
        const Icon(Icons.chevron_right, size: 18, color: AppColors.muted),
      ]),
    );
  }
}

class _TicketDetailScreen extends StatefulWidget {
  final Ticket ticket;
  const _TicketDetailScreen({required this.ticket});

  @override
  State<_TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<_TicketDetailScreen> {
  final _msgCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<TicketBloc>().add(LoadTicketDetail(widget.ticket.id));
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_msgCtrl.text.trim().isEmpty) return;
    
    context.read<TicketBloc>().add(
          EnvoyerMessage(widget.ticket.id, _msgCtrl.text.trim()),
        );
    _msgCtrl.clear();
  }

  void _ouvrirDialogueAffectation(BuildContext context, String ticketId) {
    AppUser? agentSelectionne;
    context.read<AdminBloc>().add(LoadUsers());

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Affecter un agent au ticket"),
          content: BlocBuilder<AdminBloc, AdminState>(
            bloc: context.read<AdminBloc>(),
            builder: (context, state) {
              if (state is AdminLoading) {
                return const SizedBox(
                  height: 60,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (state is UsersLoaded) {
                return DropdownButtonFormField<AppUser>(
                  decoration: const InputDecoration(
                    labelText: "Sélectionner un agent",
                    border: OutlineInputBorder(),
                  ),
                  value: agentSelectionne,
                  items: state.users.map((user) {
                    return DropdownMenuItem<AppUser>(
                      value: user,
                      child: Text("${user.nom} ${user.prenom}"),
                    );
                  }).toList(),
                  onChanged: (val) => agentSelectionne = val,
                );
              }
              return const Text("Erreur lors de la récupération des agents.");
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () {
                if (agentSelectionne != null) {
                  context.read<TicketBloc>().add(
                    AffecterAgentTkt(ticketId, agentSelectionne!.id.toString()),
                  );
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text("Affecter"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TicketBloc, TicketState>(
      builder: (context, state) {
        Ticket t = widget.ticket;
        
        if (state is TicketDetailL) {
          t = state.ticket;
        }

        if (state is TicketError && state.msg.isNotEmpty) {
          return Scaffold(
            appBar: AppBar(title: Text('#${widget.ticket.id}')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      state.msg,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => context.read<TicketBloc>().add(LoadTicketDetail(widget.ticket.id)),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final List<TicketMessage> currentMessages = t.communications;

        return Scaffold(
          appBar: AppBar(
            title: Text('#${t.id}', style: const TextStyle(fontSize: 15)),
            actions: [
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'assign') {
                    _ouvrirDialogueAffectation(context, t.id);
                  } else if (v == 'pause') {
                    context.read<TicketBloc>().add(UpdateStatut(t.id, TicketStatus.enPause));
                  } else if (v == 'resolve') {
                    context.read<TicketBloc>().add(UpdateStatut(t.id, TicketStatus.resolu));
                  } else if (v == 'close') {
                    context.read<TicketBloc>().add(UpdateStatut(t.id, TicketStatus.ferme));
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'assign', child: Text('Affecter un agent')),
                  const PopupMenuItem(value: 'pause', child: Text('Mettre en pause')),
                  const PopupMenuItem(value: 'resolve', child: Text('Marquer résolu')),
                  const PopupMenuItem(value: 'close', child: Text('Fermer le ticket')),
                ],
              ),
            ],
          ),
          body: Column(children: [
            if (state is TicketLoading)
              const LinearProgressIndicator(minHeight: 2),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t.description,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Row(children: [
                  StatusBadge.fromTicketStatus(t.status),
                  const SizedBox(width: 8),
                  PriorityBadge(priority: t.priority),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.business_outlined, size: 14, color: AppColors.muted),
                  const SizedBox(width: 4),
                  Text(t.structure,
                      style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                  const SizedBox(width: 12),
                  const Icon(Icons.person_outline, size: 14, color: AppColors.muted),
                  const SizedBox(width: 4),
                  Text(t.agentAssigneNom ?? 'Non affecté',
                      style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                ]),

                if (t.attachmentUrl != null && t.attachmentUrl!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final String baseUrl = "http://localhost:8085";
                      final String fullUrl = t.attachmentUrl!.startsWith('http')
                          ? t.attachmentUrl!
                          : '$baseUrl${t.attachmentUrl!}';

                      final Uri url = Uri.parse(fullUrl);
                      try {
                        if (await url_launcher.canLaunchUrl(url)) {
                          await url_launcher.launchUrl(
                            url,
                            mode: url_launcher.LaunchMode.externalApplication,
                          );
                        } else {
                          throw "Impossible d'accéder au fichier";
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Impossible d\'ouvrir la pièce jointe : $e')),
                          );
                        }
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.attach_file, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              t.attachmentUrl!.split('/').last,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.primary,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.open_in_new, size: 14, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        context.read<TicketBloc>().add(UpdateStatut(t.id, TicketStatus.enPause));
                      },
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10)),
                      child: const Text('En pause', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<TicketBloc>().add(UpdateStatut(t.id, TicketStatus.resolu));
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(vertical: 10)),
                      child: const Text('Résolu', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ]),
              ]),
            ),
            const Divider(height: 0),
            
            Expanded(
              child: currentMessages.isEmpty
                  ? const Center(
                      child: Text('Aucun message',
                          style: TextStyle(color: AppColors.muted)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: currentMessages.length,
                      itemBuilder: (context, i) {
                        return _MessageBubble(msg: currentMessages[i]);
                      },
                    ),
            ),
            const Divider(height: 0),
            Container(
              padding: EdgeInsets.only(
                left: 12,
                right: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom + 12,
                top: 8,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
              ),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Ajouter un message...',
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: AppColors.primary),
                  onPressed: _sendMessage,
                ),
              ]),
            ),
          ]),
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final TicketMessage msg;

  const _MessageBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: msg.isSelf ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: msg.isSelf ? AppColors.primary : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!msg.isSelf)
                Text(
                  msg.auteur,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              Text(
                msg.message,
                style: TextStyle(color: msg.isSelf ? Colors.white : Colors.black),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateTicketSheet extends StatefulWidget {
  @override
  State<_CreateTicketSheet> createState() => _CreateTicketSheetState();
}

class _CreateTicketSheetState extends State<_CreateTicketSheet> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _structureCtrl = TextEditingController(); 
  TicketPriority _priority = TicketPriority.normale;
  PlatformFile? _selectedFile;
  final TextEditingController _serviceCtrl = TextEditingController();

  @override
  void dispose() {
    _descCtrl.dispose();
    _structureCtrl.dispose();
    _serviceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFile = result.files.first;
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<TicketBloc>().add(
        CreateTicket(
          description: _descCtrl.text.trim(),
          structure: _structureCtrl.text.trim().isEmpty ? "Non spécifiée" : _structureCtrl.text.trim(),
          priority: _priority,
          attachmentBytes: _selectedFile?.bytes, 
          attachmentName: _selectedFile?.name,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView( 
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Créer un nouveau Ticket', 
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Description / Problème'),
                maxLines: 3,
                validator: (v) => v == null || v.trim().isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _structureCtrl,
                decoration: const InputDecoration(labelText: 'Structure '),
                validator: (v) => v == null || v.trim().isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _serviceCtrl,
                decoration: const InputDecoration(labelText: ' Service concerné'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<TicketPriority>(
                value: _priority,
                decoration: const InputDecoration(labelText: 'Priorité'),
                items: TicketPriority.values.map((p) {
                  return DropdownMenuItem(value: p, child: Text(p.name.toUpperCase()));
                }).toList(),
                onChanged: (val) => setState(() => _priority = val!),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Joindre un fichier'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedFile?.name ?? 'Aucun fichier sélectionné',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 37, 235, 40)),
                  child: const Text('Soumettre', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}