import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widget/shared_widget.dart';
import '../bloc/all_blocs.dart';
import '../services/services.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AdminBloc>(
      // CORRECTION DU SERVICE LOCATOR : La syntaxe sl<Type>() est maintenant 100% opérationnelle
      create: (context) => AdminBloc(sl<AdminService>())..add(LoadUsers()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Administration'),
          bottom: TabBar(
            controller: _tab,
            tabs: const [
              Tab(text: 'Utilisateurs'),
              Tab(text: 'Rôles'),
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
            return FloatingActionButton(
              onPressed: () => _showAddUserSheet(context, context.read<AdminBloc>()),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.person_add_outlined),
            );
          },
        ),
        body: TabBarView(
          controller: _tab,
          children: const [
            _UsersTab(),
            _RolesTab(),
            _SettingsTab(),
          ],
        ),
      ),
    );
  }

  void _showAddUserSheet(BuildContext context, AdminBloc adminBloc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => BlocProvider.value(
        value: adminBloc,
        child: const _AddUserSheet(),
      ),
      backgroundColor: Colors.white,
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// USERS TAB (DYNAMIQUE)
// ════════════════════════════════════════════════════════════════════

class _UsersTab extends StatelessWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminBloc, AdminState>(
      listener: (context, state) {
        if (state is AdminSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.msg), backgroundColor: AppColors.success),
          );
        } else if (state is AdminError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.msg), backgroundColor: AppColors.danger),
          );
        }
      },
      builder: (context, state) {
        if (state is AdminLoading && state is! UsersLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        List<AppUser> listUsers = [];
        if (state is UsersLoaded) {
          listUsers = state.users;
        }

        return RefreshIndicator(
          onRefresh: () async => context.read<AdminBloc>().add(LoadUsers()),
          child: ListView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              // Stats Dynamiques
              Row(
                children: [
                  Expanded(child: StatCard(value: '${listUsers.length}', label: 'Utilisateurs')),
                  const SizedBox(width: 10),
                  const Expanded(child: StatCard(value: '4', label: 'Rôles définis')),
                  const SizedBox(width: 10),
                  const Expanded(child: StatCard(value: '4', label: 'Structures')),
                ],
              ),
              const SizedBox(height: 16),
              const SectionHeader(title: 'Liste des utilisateurs'),
              const SizedBox(height: 8),
              if (listUsers.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: Text('Aucun utilisateur trouvé dans PostgreSQL.')),
                )
              else
                AppCard(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 14),
                  child: Column(
                    children: listUsers.map((u) => _UserTile(user: u, isLast: u == listUsers.last)).toList(),
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
  const _UserTile({required this.user, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              UserAvatar(initials: user.initiales, size: 38),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.nom,
                      style: TextStyle(
                        fontSize: 13, 
                        fontWeight: FontWeight.w500,
                        decoration: user.isActive == false ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    Text(user.email, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                  ],
                ),
              ),
              StatusBadge.fromUserRole(user.role),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18, color: AppColors.muted),
                onSelected: (action) {
                  if (action == 'toggle') {
                    context.read<AdminBloc>().add(ToggleUser(user.id));
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Modifier')),
                  PopupMenuItem(
                    value: 'toggle', 
                    child: Text(
                      user.isActive == false ? 'Activer le compte' : 'Désactiver', 
                      style: TextStyle(color: user.isActive == false ? AppColors.success : AppColors.danger),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
      children: [
        ...roles.map((r) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AppCard(
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: r.$3, borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.shield_outlined, color: r.$4, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.$1, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      Text(r.$2, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 17, color: AppColors.muted),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        )),
      ],
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionHeader(title: 'Notifications (Spring Boot Properties)'),
        const SizedBox(height: 8),
        AppCard(
          child: Column(
            children: const [
              ToggleRow(label: 'Notifications par email', initial: true),
              Divider(),
              ToggleRow(label: 'Notifications internes', initial: true),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const SectionHeader(title: 'Paramètres système'),
        const SizedBox(height: 8),
        AppCard(
          child: Column(
            children: const [
              _SettingRow(label: 'Délai max. sans affectation', value: '48h'),
              Divider(),
              _SettingRow(label: 'Langue de l\'interface', value: 'Français'),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String label;
  final String value;
  const _SettingRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          Text(value, style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500)),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right, size: 16, color: Colors.black),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// ADD USER SHEET (FORMULAIRE SPRING BOOT)
// ════════════════════════════════════════════════════════════════════

class _AddUserSheet extends StatefulWidget {
  const _AddUserSheet();

  @override
  State<_AddUserSheet> createState() => _AddUserSheetState();
}

class _AddUserSheetState extends State<_AddUserSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  
  String? _selectedStructure;
  String? _selectedService;
  UserRole? _selectedRole;

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final String backendRoleValue = _selectedRole == UserRole.agent 
          ? 'AGENT_DSI' 
          : _selectedRole.toString().split('.').last.toUpperCase();

      final payload = {
        'nom': _nomController.text.trim(),
        'prenom': _prenomController.text.trim(),
        'email': _emailController.text.trim(),
        'structure': _selectedStructure,
        'service': _selectedService,
        'role': backendRoleValue,
        'password': 'Password123!', 
      };

      context.read<AdminBloc>().add(CreateUser(payload));
      Navigator.pop(context);
    }
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
                  const Text('Ajouter un utilisateur', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ]),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nomController,
                  decoration: const InputDecoration(labelText: 'Nom', prefixIcon: Icon(Icons.person_outline, size: 18)),
                  validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _prenomController,
                  decoration: const InputDecoration(labelText: 'Prénom', prefixIcon: Icon(Icons.person_outline, size: 18)),
                  validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Adresse email', prefixIcon: Icon(Icons.mail_outline, size: 18)),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v == null || !v.contains('@') ? 'Email invalide' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Structure', prefixIcon: Icon(Icons.domain, size: 18)),
                  items: ['Administratif', 'Financier', 'IT', 'Gestion matériel'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (v) => setState(() => _selectedStructure = v),
                  validator: (v) => v == null ? 'Sélectionnez une structure' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Service', prefixIcon: Icon(Icons.miscellaneous_services, size: 18)),
                  items: ['Statistique', 'DMP', 'RH', 'BCMP'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (v) => setState(() => _selectedService = v),
                  validator: (v) => v == null ? 'Sélectionnez un service' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<UserRole>(
                  decoration: const InputDecoration(labelText: 'Rôle', prefixIcon: Icon(Icons.text_fields_outlined, size: 18)),
                  items: UserRole.values.map((role) => DropdownMenuItem(
                    value: role, 
                    child: Text(role.label),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedRole = v),
                  validator: (v) => v == null ? 'Sélectionnez un rôle' : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submit, 
                  child: const Text('Créer l\'utilisateur'),
                ),
              ],
            ),
          ),
        ),
      ),
    ); 
  }
}