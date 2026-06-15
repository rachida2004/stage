import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widget/shared_widget.dart';
import '../bloc/all_blocs.dart';
import '../services/services.dart';

// ════════════════════════════════════════════════════════════════════
// ADMIN SCREEN — 4 onglets : Utilisateurs | Rôles | Structures/Services | Paramètres
// ════════════════════════════════════════════════════════════════════

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;

  // Listes chargées depuis l'API
  List<Structure> _structures = [];
  List<Service>   _services   = [];
  bool _metaLoading = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    _loadMetadata();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  // ── Chargement des listes depuis le backend ──────────────────────
  Future<void> _loadMetadata() async {
    if (!mounted) return;
    setState(() => _metaLoading = true);
    try {
      final structures = await sl<AdminService>().getStructures();
      final services   = await sl<AdminService>().getServices();
      if (mounted) setState(() { _structures = structures; _services = services; });
    } catch (_) {
      // Silencieux — le CRUD tab affichera "Aucune donnée"
    } finally {
      if (mounted) setState(() => _metaLoading = false);
    }
  }

  void _showUserFormSheet(BuildContext context, AdminBloc adminBloc, {AppUser? user}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => BlocProvider.value(
        value: adminBloc,
        child: _UserFormSheet(
          user: user,
          structures: _structures,
          services: _services,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AdminBloc>(
      create: (context) => AdminBloc(sl<AdminService>())
        ..add(LoadUsers())
        ..add(LoadSettings()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Administration'),
          bottom: TabBar(
            controller: _tab,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Utilisateurs'),
              Tab(text: 'Rôles'),
              Tab(text: 'Structures & Services'),
              Tab(text: 'Paramètres'),
            ],
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            unselectedLabelStyle: const TextStyle(fontSize: 13),
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.black,
            indicatorColor: AppColors.primary,
            indicatorSize: TabBarIndicatorSize.tab,
          ),
        ),
        floatingActionButton: BlocBuilder<AdminBloc, AdminState>(
          builder: (context, state) {
            // FAB uniquement sur l'onglet Utilisateurs
            return AnimatedBuilder(
              animation: _tab,
              builder: (_, __) {
                if (_tab.index != 0) return const SizedBox.shrink();
                return FloatingActionButton(
                  heroTag: 'fab_admin_user',
                  onPressed: () => _showUserFormSheet(context, context.read<AdminBloc>()),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.person_add_outlined),
                );
              },
            );
          },
        ),
        body: TabBarView(
          controller: _tab,
          children: [
            _UsersTab(onShowForm: _showUserFormSheet),
            const _RolesTab(),
            _StructuresServicesTab(
              structures: _structures,
              services: _services,
              onRefresh: _loadMetadata,
              loading: _metaLoading,
            ),
            const _SettingsTab(),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// USERS TAB
// ════════════════════════════════════════════════════════════════════

class _UsersTab extends StatelessWidget {
  final void Function(BuildContext, AdminBloc, {AppUser? user}) onShowForm;
  const _UsersTab({required this.onShowForm});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminBloc, AdminState>(
      listener: (context, state) {
        if (state is AdminSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.msg), backgroundColor: AppColors.success));
        } else if (state is AdminError) {
          final isForbidden = state.msg.contains("403") || state.msg.contains("Forbidden");
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(isForbidden ? "Action non autorisée." : state.msg),
            backgroundColor: isForbidden ? Colors.orange : AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ));
        }
      },
      builder: (context, state) {
        if (state is AdminLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        List<AppUser> users = [];
        if (state is UsersLoaded) users = state.users;

        return RefreshIndicator(
          onRefresh: () async => context.read<AdminBloc>().add(LoadUsers()),
          child: ListView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Row(children: [
                Expanded(child: StatCard(value: '${users.length}', label: 'Utilisateurs')),
                const SizedBox(width: 10),
                const Expanded(child: StatCard(value: '4', label: 'Rôles définis')),
              ]),
              const SizedBox(height: 16),
              const SectionHeader(title: 'Liste des utilisateurs'),
              const SizedBox(height: 8),
              if (users.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: Text('Aucun utilisateur trouvé.')),
                )
              else
                AppCard(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 14),
                  child: Column(
                    children: users.map((u) => _UserTile(
                      user: u,
                      isLast: u == users.last,
                      onShowForm: onShowForm,
                    )).toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _UserTile extends StatelessWidget {
  final AppUser user;
  final bool isLast;
  final void Function(BuildContext, AdminBloc, {AppUser? user}) onShowForm;
  const _UserTile({required this.user, required this.isLast, required this.onShowForm});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(children: [
            UserAvatar(initials: user.initiales, size: 38),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user.nom,
                  style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500,
                    decoration: !user.isActive ? TextDecoration.lineThrough : null,
                  )),
                Text(user.email, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
              ]),
            ),
            StatusBadge.fromUserRole(user.role),
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 18, color: AppColors.muted),
              onSelected: (action) {
                if (action == 'toggle') {
                  context.read<AdminBloc>().add(ToggleUser(user.id));
                } else if (action == 'edit') {
                  onShowForm(context, context.read<AdminBloc>(), user: user);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Modifier')),
                PopupMenuItem(
                  value: 'toggle',
                  child: Text(
                    !user.isActive ? 'Activer le compte' : 'Désactiver',
                    style: TextStyle(color: !user.isActive ? AppColors.success : AppColors.danger),
                  ),
                ),
              ],
            ),
          ]),
        ),
        if (!isLast) const Divider(),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// ROLES TAB
// ════════════════════════════════════════════════════════════════════

class _RolesTab extends StatelessWidget {
  const _RolesTab();

  static const roles = [
    ('Administrateur', 'Accès complet à toutes les fonctionnalités', AppColors.primaryLight, AppColors.primaryDark),
    ('Agent DSI', 'Gestion invitations, tickets, affectations', AppColors.warningLight, AppColors.warning),
    ('Superviseur', 'Lecture + affectation, sans administration', AppColors.successLight, AppColors.success),
    ('Usager', 'Création et suivi de tickets uniquement', AppColors.surface, AppColors.muted),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: roles.map((r) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AppCard(
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: r.$3, borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.shield_outlined, color: r.$4, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.$1, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              Text(r.$2, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            ])),
          ]),
        ),
      )).toList(),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// STRUCTURES & SERVICES TAB — CRUD COMPLET
// ════════════════════════════════════════════════════════════════════

class _StructuresServicesTab extends StatefulWidget {
  final List<Structure> structures;
  final List<Service>   services;
  final Future<void> Function() onRefresh;
  final bool loading;

  const _StructuresServicesTab({
    required this.structures,
    required this.services,
    required this.onRefresh,
    required this.loading,
  });

  @override
  State<_StructuresServicesTab> createState() => _StructuresServicesTabState();
}

class _StructuresServicesTabState extends State<_StructuresServicesTab> {

  // ── STRUCTURE CRUD ───────────────────────────────────────────────

  void _showStructureForm({Structure? structure}) {
    final nomCtrl  = TextEditingController(text: structure?.nom ?? '');
    final adrCtrl  = TextEditingController(text: structure?.adresse ?? '');
    final telCtrl  = TextEditingController(text: structure?.telephone ?? '');
    final mailCtrl = TextEditingController(text: structure?.email ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(structure == null ? 'Nouvelle structure' : 'Modifier la structure',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _dialogField(nomCtrl,  'Nom *',       Icons.domain),
            const SizedBox(height: 10),
            _dialogField(adrCtrl,  'Adresse',     Icons.location_on_outlined),
            const SizedBox(height: 10),
            _dialogField(telCtrl,  'Téléphone',   Icons.phone_outlined),
            const SizedBox(height: 10),
            _dialogField(mailCtrl, 'Email',       Icons.mail_outline),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (nomCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Le nom est obligatoire')));
                return;
              }
              Navigator.pop(context);
              final payload = {
                'nom': nomCtrl.text.trim(),
                'adresse': adrCtrl.text.trim(),
                'telephone': telCtrl.text.trim(),
                'email': mailCtrl.text.trim(),
              };
              try {
                if (structure == null) {
                  await sl<AdminService>().createStructure(payload);
                } else {
                  await sl<AdminService>().updateStructure(structure.id!, payload);
                }
                await widget.onRefresh();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(structure == null ? 'Structure créée' : 'Structure modifiée'),
                    backgroundColor: AppColors.success));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur : $e'), backgroundColor: AppColors.danger));
              }
            },
            child: Text(structure == null ? 'Créer' : 'Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _deleteStructure(Structure s) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Supprimer la structure ?', style: TextStyle(fontSize: 15)),
        content: Text('Cette action supprimera "${s.nom}" définitivement.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await sl<AdminService>().deleteStructure(s.id!);
                await widget.onRefresh();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Structure supprimée'), backgroundColor: AppColors.success));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur : $e'), backgroundColor: AppColors.danger));
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── SERVICE CRUD ─────────────────────────────────────────────────

  void _showServiceForm({Service? service}) {
    final nomCtrl  = TextEditingController(text: service?.nom ?? '');
    final descCtrl = TextEditingController(text: service?.description ?? '');
    Structure? selectedStructure = service?.structure ??
        (widget.structures.isNotEmpty ? widget.structures.first : null);

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          title: Text(service == null ? 'Nouveau service' : 'Modifier le service',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _dialogField(nomCtrl,  'Nom *',        Icons.miscellaneous_services),
              const SizedBox(height: 10),
              _dialogField(descCtrl, 'Description',  Icons.notes_outlined),
              const SizedBox(height: 10),
              DropdownButtonFormField<Structure>(
                value: selectedStructure,
                decoration: const InputDecoration(
                  labelText: 'Structure parente',
                  prefixIcon: Icon(Icons.domain, size: 18),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: widget.structures
                    .map((s) => DropdownMenuItem(value: s, child: Text(s.nom)))
                    .toList(),
                onChanged: (v) => setDialogState(() => selectedStructure = v),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                if (nomCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Le nom est obligatoire')));
                  return;
                }
                Navigator.pop(ctx);
                final payload = {
                  'nom': nomCtrl.text.trim(),
                  'description': descCtrl.text.trim(),
                  if (selectedStructure?.id != null) 'structureId': selectedStructure!.id,
                };
                try {
                  if (service == null) {
                    await sl<AdminService>().createService(payload);
                  } else {
                    await sl<AdminService>().updateService(service.id!, payload);
                  }
                  await widget.onRefresh();
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(service == null ? 'Service créé' : 'Service modifié'),
                      backgroundColor: const Color.fromARGB(255, 3, 54, 22)));
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur : $e'), backgroundColor: AppColors.danger));
                }
              },
              child: Text(service == null ? 'Créer' : 'Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteService(Service s) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Supprimer le service ?', style: TextStyle(fontSize: 15)),
        content: Text('Cette action supprimera "${s.nom}" définitivement.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await sl<AdminService>().deleteService(s.id!);
                await widget.onRefresh();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Service supprimé'), backgroundColor: AppColors.success));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur : $e'), backgroundColor: AppColors.danger));
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── BUILD ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (widget.loading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── Structures ──────────────────────────────────────────
          Row(children: [
            const Expanded(child: SectionHeader(title: 'Structures')),
            TextButton.icon(
              onPressed: () => _showStructureForm(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Ajouter', style: TextStyle(fontSize: 12)),
            ),
          ]),
          const SizedBox(height: 8),
          if (widget.structures.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: Text('Aucune structure. Cliquez sur Ajouter.',
                  style: TextStyle(color: AppColors.muted))),
            )
          else
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 14),
              child: Column(
                children: widget.structures.asMap().entries.map((entry) {
                  final s   = entry.value;
                  final isLast = entry.key == widget.structures.length - 1;
                  return Column(children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.domain, size: 18, color: AppColors.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(s.nom, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          if (s.adresse != null && s.adresse!.isNotEmpty)
                            Text(s.adresse!, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                        ])),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 17, color: AppColors.muted),
                          onPressed: () => _showStructureForm(structure: s),
                          tooltip: 'Modifier',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 17, color: AppColors.danger),
                          onPressed: () => _deleteStructure(s),
                          tooltip: 'Supprimer',
                        ),
                      ]),
                    ),
                    if (!isLast) const Divider(height: 1),
                  ]);
                }).toList(),
              ),
            ),

          const SizedBox(height: 24),

          // ── Services ────────────────────────────────────────────
          Row(children: [
            const Expanded(child: SectionHeader(title: 'Services')),
            TextButton.icon(
              onPressed: widget.structures.isEmpty
                  ? null  // Désactivé si aucune structure n'existe
                  : () => _showServiceForm(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Ajouter', style: TextStyle(fontSize: 12)),
            ),
          ]),
          if (widget.structures.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('Créez d\'abord une structure avant d\'ajouter des services.',
                style: TextStyle(fontSize: 12, color: AppColors.muted)),
            ),
          const SizedBox(height: 8),
          if (widget.services.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: Text('Aucun service. Cliquez sur Ajouter.',
                  style: TextStyle(color: AppColors.muted))),
            )
          else
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 14),
              child: Column(
                children: widget.services.asMap().entries.map((entry) {
                  final s      = entry.value;
                  final isLast = entry.key == widget.services.length - 1;
                  return Column(children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.successLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.miscellaneous_services, size: 18, color: Color.fromARGB(255, 7, 59, 26)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(s.nom, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          if (s.structure != null)
                            Text('→ ${s.structure!.nom}',
                                style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                        ])),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 17, color: AppColors.muted),
                          onPressed: () => _showServiceForm(service: s),
                          tooltip: 'Modifier',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 17, color: AppColors.danger),
                          onPressed: () => _deleteService(s),
                          tooltip: 'Supprimer',
                        ),
                      ]),
                    ),
                    if (!isLast) const Divider(height: 1),
                  ]);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // Helper
  Widget _dialogField(TextEditingController ctrl, String label, IconData icon) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// SETTINGS TAB
// ════════════════════════════════════════════════════════════════════

class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminBloc, AdminState>(
      builder: (context, state) {
        if (state is AdminLoading) return const Center(child: CircularProgressIndicator());

        Map<String, dynamic> settings = {
          "notificationsEmail": true,
          "notificationsInternes": true,
          "delaiMaxSansAffectation": "48h",
          "langue": "Français",
        };
        if (state is SettingsLoaded) settings = state.settings;

        void update(String key, dynamic val) {
          final next = Map<String, dynamic>.from(settings)..[key] = val;
          context.read<AdminBloc>().add(SaveSettings(next));
        }

        return RefreshIndicator(
          onRefresh: () async => context.read<AdminBloc>().add(LoadSettings()),
          child: ListView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SectionHeader(title: 'Notifications'),
              const SizedBox(height: 8),
              AppCard(child: Column(children: [
                _ToggleRow(
                  label: 'Notifications par email',
                  value: settings['notificationsEmail'] ?? true,
                  onChanged: (v) => update('notificationsEmail', v),
                ),
                const Divider(),
                _ToggleRow(
                  label: 'Notifications internes',
                  value: settings['notificationsInternes'] ?? true,
                  onChanged: (v) => update('notificationsInternes', v),
                ),
              ])),
              const SizedBox(height: 16),
              const SectionHeader(title: 'Paramètres système'),
              const SizedBox(height: 8),
              AppCard(child: Column(children: [
                _SettingRow(
                  label: 'Délai max. sans affectation',
                  value: settings['delaiMaxSansAffectation'] ?? '48h',
                  onTap: () => _showSelection(context,
                    title: 'Délai max. sans affectation',
                    options: ['12h', '24h', '48h', '72h'],
                    current: settings['delaiMaxSansAffectation'] ?? '48h',
                    onSelected: (v) => update('delaiMaxSansAffectation', v),
                  ),
                ),
                const Divider(),
                _SettingRow(
                  label: "Langue de l'interface",
                  value: settings['langue'] ?? 'Français',
                  onTap: () => _showSelection(context,
                    title: "Langue de l'interface",
                    options: ['Français', 'English'],
                    current: settings['langue'] ?? 'Français',
                    onSelected: (v) => update('langue', v),
                  ),
                ),
              ])),
            ],
          ),
        );
      },
    );
  }

  void _showSelection(BuildContext context, {
    required String title,
    required List<String> options,
    required String current,
    required ValueChanged<String> onSelected,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((opt) => RadioListTile<String>(
            title: Text(opt, style: TextStyle(
              fontSize: 13,
              color: opt == current ? AppColors.primary : Colors.black87,
              fontWeight: opt == current ? FontWeight.bold : FontWeight.normal,
            )),
            value: opt,
            groupValue: current,
            activeColor: AppColors.primary,
            onChanged: (v) { if (v != null) { onSelected(v); Navigator.pop(context); } },
          )).toList(),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: Colors.black87))),
        Switch(value: value, activeColor: AppColors.primary, onChanged: onChanged),
      ]),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _SettingRow({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          Text(value, style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500)),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right, size: 16, color: Colors.black54),
        ]),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// USER FORM SHEET — Avec dropdowns dynamiques Structure/Service
// ════════════════════════════════════════════════════════════════════

class _UserFormSheet extends StatefulWidget {
  final AppUser?        user;
  final List<Structure> structures;
  final List<Service>   services;
  const _UserFormSheet({this.user, required this.structures, required this.services});

  @override
  State<_UserFormSheet> createState() => _UserFormSheetState();
}

class _UserFormSheetState extends State<_UserFormSheet> {
  final _formKey   = GlobalKey<FormState>();
  final _nomCtrl   = TextEditingController();
  final _prenomCtrl= TextEditingController();
  final _emailCtrl = TextEditingController();

  Structure? _selectedStructure;
  Service?   _selectedService;
  List<Service> _filteredServices = [];  // Services filtrés par structure
  UserRole?  _selectedRole;

  bool get _isEditing => widget.user != null;

  @override
  void initState() {
    super.initState();
    _filteredServices = widget.services;
    if (_isEditing) {
      final u = widget.user!;
      _nomCtrl.text    = u.nom;
      _prenomCtrl.text = u.prenom ?? '';
      _emailCtrl.text  = u.email;
      _selectedRole    = u.role;
      // Pré-sélection structure/service par nom
      try {
        _selectedStructure = widget.structures.firstWhere((s) => s.nom == u.structure);
        _filteredServices  = widget.services.where((s) => s.structure?.nom == u.structure).toList();
        _selectedService   = _filteredServices.firstWhere((s) => s.nom == u.service);
      } catch (_) {}
    }
  }

  void _onStructureChanged(Structure? s) {
    setState(() {
      _selectedStructure = s;
      _selectedService   = null;
      // ✅ Filtrer les services qui appartiennent à cette structure
      _filteredServices  = s == null
          ? widget.services
          : widget.services.where((svc) => svc.structure?.id == s.id).toList();
    });
  }

  @override
  void dispose() {
    _nomCtrl.dispose(); _prenomCtrl.dispose(); _emailCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final roleStr = _selectedRole == UserRole.agent
        ? 'AGENT_DSI'
        : _selectedRole.toString().split('.').last.toUpperCase();

    final payload = {
      'nom':       _nomCtrl.text.trim(),
      'prenom':    _prenomCtrl.text.trim(),
      'email':     _emailCtrl.text.trim(),
      'structure': _selectedStructure?.nom,
      'service':   _selectedService?.nom,
      'role':      roleStr,
    };

    if (_isEditing) {
      context.read<AdminBloc>().add(UpdateUser(widget.user!.id, payload));
    } else {
      payload['password'] = 'Password123!';
      context.read<AdminBloc>().add(CreateUser(payload));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  Text(_isEditing ? "Modifier l'utilisateur" : 'Ajouter un utilisateur',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ]),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nomCtrl,
                  decoration: const InputDecoration(labelText: 'Nom', prefixIcon: Icon(Icons.person_outline, size: 18)),
                  validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _prenomCtrl,
                  decoration: const InputDecoration(labelText: 'Prénom', prefixIcon: Icon(Icons.person_outline, size: 18)),
                  validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailCtrl,
                  enabled: !_isEditing,
                  decoration: const InputDecoration(labelText: 'Adresse email', prefixIcon: Icon(Icons.mail_outline, size: 18)),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v == null || !v.contains('@') ? 'Email invalide' : null,
                ),
                const SizedBox(height: 12),

                // ✅ Dropdown Structure dynamique
                DropdownButtonFormField<Structure>(
                  value: _selectedStructure,
                  decoration: const InputDecoration(labelText: 'Structure', prefixIcon: Icon(Icons.domain, size: 18)),
                  items: widget.structures
                      .map((s) => DropdownMenuItem(value: s, child: Text(s.nom)))
                      .toList(),
                  onChanged: _onStructureChanged,
                  validator: (v) => v == null ? 'Sélectionnez une structure' : null,
                ),
                const SizedBox(height: 12),

                // ✅ Dropdown Service filtré par structure sélectionnée
                DropdownButtonFormField<Service>(
                  value: _selectedService,
                  decoration: const InputDecoration(labelText: 'Service', prefixIcon: Icon(Icons.miscellaneous_services, size: 18)),
                  hint: Text(_selectedStructure == null
                      ? 'Choisissez d\'abord une structure'
                      : _filteredServices.isEmpty
                          ? 'Aucun service pour cette structure'
                          : 'Sélectionner un service'),
                  items: _filteredServices
                      .map((s) => DropdownMenuItem(value: s, child: Text(s.nom)))
                      .toList(),
                  onChanged: _filteredServices.isEmpty ? null : (v) => setState(() => _selectedService = v),
                  validator: (v) => v == null ? 'Sélectionnez un service' : null,
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<UserRole>(
                  value: _selectedRole,
                  decoration: const InputDecoration(labelText: 'Rôle', prefixIcon: Icon(Icons.shield_outlined, size: 18)),
                  items: UserRole.values
                      .map((r) => DropdownMenuItem(value: r, child: Text(r.label)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedRole = v),
                  validator: (v) => v == null ? 'Sélectionnez un rôle' : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submit,
                  child: Text(_isEditing ? 'Enregistrer les modifications' : 'Créer l\'utilisateur'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}