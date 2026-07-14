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
  List<AppRole>   _roles      = [];
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
      final roles      = await sl<AdminService>().getRoles();
      if (mounted) setState(() { _structures = structures; _services = services; _roles = roles; });
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
          roles: _roles,
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
            _UsersTab(onShowForm: _showUserFormSheet, rolesCount: _roles.length),
            _RolesTab(
              roles: _roles,
              onRefresh: _loadMetadata,
              loading: _metaLoading,
            ),
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

class _UsersTab extends StatefulWidget {
  final void Function(BuildContext, AdminBloc, {AppUser? user}) onShowForm;
  final int rolesCount;
  const _UsersTab({required this.onShowForm, required this.rolesCount});

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

// 🎯 IMPORTANT — NE PAS reconvertir cette classe en StatelessWidget.
//
// L'AdminBloc est PARTAGÉ entre cet onglet "Utilisateurs" et l'onglet
// "Paramètres" (LoadSettings()/SaveSettings() passent par le MÊME flux
// AdminState). Quand on ouvre l'écran Admin, la séquence est :
//   LoadUsers()    -> AdminLoading() -> UsersLoaded(users)
//   LoadSettings() -> AdminLoading() -> SettingsLoaded(settings)
// Sans cache local, le 2nd appel fait disparaître la liste : le `state`
// n'est plus UsersLoaded (donc users = []) dès que les paramètres se
// chargent — c'est exactement le bug "la liste s'affiche puis repart".
// On garde donc la dernière liste connue (_cachedUsers) et on ne la
// remplace QUE quand l'état reçu est effectivement UsersLoaded.
class _UsersTabState extends State<_UsersTab> {
  List<AppUser> _cachedUsers = [];
  bool _hasLoadedOnce = false;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminBloc, AdminState>(
      listener: (context, state) {
        if (state is AdminSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.msg), backgroundColor: AppColors.success));
        } else if (state is AdminError) {
          showErrorSnack(context, state.msg);
        }
      },
      builder: (context, state) {
        // On ne met à jour le cache que lorsque l'état concerne bien les utilisateurs.
        if (state is UsersLoaded) {
          _cachedUsers = state.users;
          _hasLoadedOnce = true;
        }

        // Spinner uniquement avant le tout premier chargement réussi —
        // ensuite on garde toujours la dernière liste connue à l'écran.
        if (!_hasLoadedOnce && state is AdminLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = [..._cachedUsers]
          ..sort((a, b) {
            // 🎯 Utilisateurs désactivés toujours en bas de la liste.
            if (a.isActive == b.isActive) return 0;
            return a.isActive ? -1 : 1;
          });

        return RefreshIndicator(
          onRefresh: () async => context.read<AdminBloc>().add(LoadUsers()),
          child: ListView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Row(children: [
                Expanded(child: StatCard(value: '${users.length}', label: 'Utilisateurs')),
                const SizedBox(width: 10),
                Expanded(child: StatCard(value: '${widget.rolesCount}', label: 'Rôles définis')),
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
                      onShowForm: widget.onShowForm,
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
            UserAvatar(initials: user.initiales.isEmpty ? '?' : user.initiales, size: 38),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user.nom.trim().isEmpty ? '(Nom non renseigné)' : user.nom,
                  style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500,
                    fontStyle: user.nom.trim().isEmpty ? FontStyle.italic : FontStyle.normal,
                    color: user.nom.trim().isEmpty ? AppColors.muted : null,
                    decoration: !user.isActive ? TextDecoration.lineThrough : null,
                  )),
                Text(user.email.trim().isEmpty ? '(Email non renseigné) — id: ${user.id}' : user.email,
                  style: const TextStyle(fontSize: 11, color: AppColors.muted)),
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

class _RolesTab extends StatefulWidget {
  final List<AppRole> roles;
  final Future<void> Function() onRefresh;
  final bool loading;

  const _RolesTab({
    required this.roles,
    required this.onRefresh,
    required this.loading,
  });

  @override
  State<_RolesTab> createState() => _RolesTabState();
}

class _RolesTabState extends State<_RolesTab> {
  // Couleurs/icône selon le nom du rôle, pour les 4 rôles "système" connus.
  // Les rôles personnalisés créés via le CRUD utilisent une couleur neutre.
  static const _connus = {
    'ADMIN':       (AppColors.primaryLight, AppColors.primaryDark),
    'AGENT_DSI':   (AppColors.warningLight, AppColors.warning),
    'SUPERVISEUR': (AppColors.successLight, AppColors.success),
    'USAGER':      (AppColors.surface, AppColors.muted),
    'SECRETAIRE':  (AppColors.primaryLight, AppColors.primary),
  };

  // 🎯 Libellés lisibles pour les permissions (le backend ne connaît que les
  // noms bruts de l'enum Permission, ex: "AFFECTER_AGENT").
  static const _libellesPermissions = {
    'GERER_INVITATIONS': 'Gérer les invitations (créer, enregistrer, générer une lettre)',
    'AFFECTER_AGENT':    'Affecter un agent (invitation ou ticket)',
    'GERER_TICKETS':     'Gérer les tickets',
  };

  List<String> _permissionsCatalogue = [];

  @override
  void initState() {
    super.initState();
    sl<AdminService>().getPermissionsDisponibles().then((p) {
      if (mounted) setState(() => _permissionsCatalogue = p);
    }).catchError((_) {});
  }

  void _showRoleForm({AppRole? role}) {
    final nomCtrl  = TextEditingController(text: role?.nom ?? '');
    final descCtrl = TextEditingController(text: role?.description ?? '');
    final estSysteme = role != null && _connus.containsKey(role.nom);
    final permsSelectionnees = Set<String>.from(role?.permissions ?? []);

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(role == null ? 'Nouveau rôle' : 'Modifier le rôle',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: nomCtrl,
              enabled: role == null, // le nom pilote les droits d'accès, non modifiable après création
              decoration: InputDecoration(
                labelText: 'Nom *',
                hintText: 'ex: SUPERVISEUR_RH',
                prefixIcon: const Icon(Icons.shield_outlined, size: 18),
                border: const OutlineInputBorder(),
                isDense: true,
                helperText: role != null
                    ? 'Le nom n\'est plus modifiable une fois le rôle créé.'
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description',
                prefixIcon: Icon(Icons.notes_outlined, size: 18),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            if (role == null) ...[
              const SizedBox(height: 10),
              const Text(
                "Les permissions ci-dessous donnent de vrais droits, vérifiés "
                "par le serveur à chaque requête — aucune modification de code "
                "n'est nécessaire.",
                style: TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ] else if (estSysteme) ...[
              const SizedBox(height: 10),
              const Text(
                'Rôle système : seule la description et les permissions sont modifiables.',
                style: TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ],

            // ── Permissions ──────────────────────────────────────────
            const SizedBox(height: 16),
            const Align(alignment: Alignment.centerLeft,
                child: Text('Permissions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,color: Colors.black87,))),
            const SizedBox(height: 4),
            if (_permissionsCatalogue.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Aucune permission disponible.', style: TextStyle(fontSize: 12, color: AppColors.muted)),
              )
            else
              ..._permissionsCatalogue.map((p) => CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,

                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(
          _libellesPermissions[p] ?? p, 
          style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500),
        ),
                    value: permsSelectionnees.contains(p),
                    onChanged: (v) => setDialogState(() {
                      if (v == true) permsSelectionnees.add(p); else permsSelectionnees.remove(p);
                    }),
                  )),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (nomCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Le nom est obligatoire')));
                return;
              }
              Navigator.pop(dialogContext);
              final payload = {
                'nom': nomCtrl.text.trim(),
                'description': descCtrl.text.trim(),
              };
              try {
                int roleId;
                if (role == null) {
                  final cree = await sl<AdminService>().createRole(payload);
                  roleId = cree.id!;
                } else {
                  await sl<AdminService>().updateRole(role.id!, payload);
                  roleId = role.id!;
                }
                // 🎯 On pousse toujours l'ensemble des permissions cochées —
                // marche aussi bien à la création qu'à la modification.
                await sl<AdminService>().updateRolePermissions(roleId, permsSelectionnees.toList());
                await widget.onRefresh();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(role == null ? 'Rôle créé' : 'Rôle modifié'),
                    backgroundColor: AppColors.success));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur : $e'), backgroundColor: AppColors.danger));
              }
            },
            child: Text(role == null ? 'Créer' : 'Enregistrer'),
          ),
        ],
        ),
      ),
    );
  }

  void _deleteRole(AppRole r) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Supprimer le rôle ?', style: TextStyle(fontSize: 15)),
        content: Text('Cette action supprimera "${r.nom}" définitivement.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await sl<AdminService>().deleteRole(r.id!);
                await widget.onRefresh();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Rôle supprimé'), backgroundColor: AppColors.success));
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

  @override
  Widget build(BuildContext context) {
    if (widget.loading && widget.roles.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            const Expanded(child: SectionHeader(title: 'Rôles')),
            TextButton.icon(
              onPressed: () => _showRoleForm(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Ajouter', style: TextStyle(fontSize: 12)),
            ),
          ]),
          const SizedBox(height: 8),
          if (widget.roles.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('Aucun rôle trouvé.', style: TextStyle(color: AppColors.muted))),
            )
          else
            ...widget.roles.map((r) {
              final couleurs = _connus[r.nom] ?? (AppColors.surface, AppColors.muted);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  child: Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: couleurs.$1, borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.shield_outlined, color: couleurs.$2, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(r.nom, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      Text(
                        (r.description != null && r.description!.isNotEmpty) ? r.description! : 'Aucune description',
                        style: const TextStyle(fontSize: 11, color: AppColors.muted),
                      ),
                      if (r.permissions.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text('${r.permissions.length} permission(s) accordée(s)',
                              style: const TextStyle(fontSize: 10, color: AppColors.primary)),
                        ),
                    ])),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 18, color: AppColors.muted),
                      onSelected: (action) {
                        if (action == 'edit') _showRoleForm(role: r);
                        if (action == 'delete') _deleteRole(r);
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'edit', child: Text('Modifier')),
                        const PopupMenuItem(value: 'delete', child: Text('Supprimer', style: TextStyle(color: AppColors.danger))),
                      ],
                    ),
                  ]),
                ),
              );
            }),
        ],
      ),
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

                // 🎯 CONSTITUTION DU PAYLOAD AVEC LA RELATION STRUCTURE IMBRIQUÉE
                final payload = {
                  'nom': nomCtrl.text.trim(),
                  'description': descCtrl.text.trim(),
                 if (selectedStructure != null) 'structureId': selectedStructure!.id,
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
  final List<AppRole>   roles;
  const _UserFormSheet({this.user, required this.structures, required this.services, required this.roles});

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
  List<Service> _filteredServices = [];  // Sera remplie dynamiquement via l'API
  UserRole?  _selectedRole; // gardé pour compat d'affichage (badges) en mode édition
  String?    _selectedRoleNom; // 🎯 nom réel du rôle choisi — alimente le dropdown dynamique
  bool _loadingServices = false; // Pour afficher un indicateur de chargement si besoin

  bool get _isEditing => widget.user != null;

  /// Libellé lisible pour les rôles standards ; nom brut pour un rôle personnalisé.
  String _roleLabel(String nom) {
    switch (nom) {
      case 'ADMIN':       return 'Administrateur';
      case 'AGENT_DSI':   return 'Agent DSI';
      case 'SUPERVISEUR': return 'Superviseur';
      case 'USAGER':       return 'Usager';
      case 'SECRETAIRE':   return 'Secrétaire';
      default: return nom;
    }
  }

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final u = widget.user!;
      _nomCtrl.text    = u.nom;
      _prenomCtrl.text = u.prenom ?? '';
      _emailCtrl.text  = u.email;
      _selectedRole    = u.role;
      _selectedRoleNom = u.role.apiValue;
      
      // Initialisation en mode édition
      _initEditionData(u);
    }
  }

  // Fonction pour pré-charger les données de la structure et ses services en mode édition
  void _initEditionData(AppUser u) async {
    try {
      _selectedStructure = widget.structures.firstWhere((s) => s.nom == u.structure);
      if (_selectedStructure != null) {
        // Appeler le service API pour récupérer les services de la structure
        final services = await sl<AdminService>().getServicesByStructure(_selectedStructure!.id!);
        setState(() {
          _filteredServices = services;
          _selectedService  = _filteredServices.firstWhere((s) => s.nom == u.service);
        });
      }
    } catch (_) {}
  }

  // 🎯 C'est ici qu'on appelle l'API lors du changement de structure
  void _onStructureChanged(Structure? s) async {
    setState(() {
      _selectedStructure = s;
      _selectedService   = null; // Réinitialise le service sélectionné
      _filteredServices  = [];  // Vide la liste précédente
    });

    if (s != null) {
      setState(() => _loadingServices = true);
      try {
        // 🚀 Appel à votre méthode d'API fraîchement créée
        final services = await sl<AdminService>().getServicesByStructure(s.id!);
        setState(() {
          _filteredServices = services;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des services : $e'), backgroundColor: AppColors.danger),
        );
      } finally {
        setState(() => _loadingServices = false);
      }
    }
  }

  @override
  void dispose() {
    _nomCtrl.dispose(); _prenomCtrl.dispose(); _emailCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final payload = {
      'nom':       _nomCtrl.text.trim(),
      'prenom':    _prenomCtrl.text.trim(),
      'email':     _emailCtrl.text.trim(),
      'structure': _selectedStructure?.nom,
      'service':   _selectedService?.nom,
      'role':      _selectedRoleNom,
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

                // Dropdown Structure
                DropdownButtonFormField<Structure>(
                  value: _selectedStructure,
                  isExpanded: true,
                  menuMaxHeight: 200,
                  decoration: const InputDecoration(labelText: 'Structure', prefixIcon: Icon(Icons.domain, size: 18)),
                  items: widget.structures
                      .map((s) => DropdownMenuItem(value: s, child: Text(s.nom, overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: _onStructureChanged,
                  validator: (v) => v == null ? 'Sélectionnez une structure' : null,
                ),
                const SizedBox(height: 12),

                // Dropdown Service filtré dynamiquement
                DropdownButtonFormField<Service>(
                  value: _selectedService,
                  isExpanded: true,
                  menuMaxHeight: 200,
                  decoration: const InputDecoration(labelText: 'Service', prefixIcon: Icon(Icons.miscellaneous_services, size: 18)),
                  hint: Text(_loadingServices
                      ? 'Chargement des services...'
                      : _selectedStructure == null
                          ? 'Choisissez d\'abord une structure'
                          : _filteredServices.isEmpty
                              ? 'Aucun service pour cette structure'
                              : 'Sélectionner un service'),
                  items: _filteredServices
                      .map((s) => DropdownMenuItem(value: s, child: Text(s.nom, overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: _filteredServices.isEmpty ? null : (v) => setState(() => _selectedService = v),
                  validator: (v) => v == null ? 'Sélectionnez un service' : null,
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: _selectedRoleNom,
                  isExpanded: true,
                  menuMaxHeight: 200,
                  decoration: const InputDecoration(labelText: 'Rôle', prefixIcon: Icon(Icons.shield_outlined, size: 18)),
                  items: widget.roles
                      .map((r) => DropdownMenuItem(value: r.nom, child: Text(_roleLabel(r.nom), overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedRoleNom = v),
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