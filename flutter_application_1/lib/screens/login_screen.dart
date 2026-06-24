import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/all_blocs.dart';
import '../theme/app_theme.dart';
import '../services/services.dart';
import '../models/models.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() { _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthOk) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()));
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.msg), backgroundColor: AppColors.danger));
        }
      },
      builder: (context, state) {
        final loading = state is AuthLoading;
        return Scaffold(
          backgroundColor: AppColors.pageBg,
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                   Container(
  width: 56, 
  height: 56,
  decoration: BoxDecoration(
    color: const Color.fromARGB(255, 3, 49, 34), 
    borderRadius: BorderRadius.circular(16),
    image: const DecorationImage(
      image: AssetImage('assets/images/logo.jpg'),
      fit: BoxFit.cover,
    ),
  ),
),
                    const SizedBox(height: 16),
                    const Text('DSI Connect', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                    const Text('Plateforme de gestion interne', style: TextStyle(fontSize: 13, color: AppColors.muted)),
                    const SizedBox(height: 32),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text('Entrez vos identifiants pour accéder à votre espace',
                                style: TextStyle(fontSize: 14, color: AppColors.muted)),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Adresse email',
                                hintText: 'agent@ministere.gov',
                                prefixIcon: Icon(Icons.mail_outline, size: 18),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _passCtrl,
                              obscureText: _obscure,
                              decoration: InputDecoration(
                                labelText: 'Mot de passe',
                                hintText: '••••••••',
                                prefixIcon: const Icon(Icons.lock_outline, size: 18),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => _showForgotDialog(context),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text('Mot de passe oublié ?', style: TextStyle(fontSize: 12)),
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: loading ? null : () => context.read<AuthBloc>().add(
                                LoginSubmitted(_emailCtrl.text.trim(), _passCtrl.text.trim())),
                              child: loading
                                ? const SizedBox(height: 18, width: 18,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Se connecter'),
                            ),
                            const SizedBox(height: 16),
                            Row(children: const [
                              Expanded(child: Divider()),
                              Padding(padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text('ou', style: TextStyle(fontSize: 12, color: AppColors.muted))),
                              Expanded(child: Divider()),
                            ]),
                            const SizedBox(height: 16),
                            OutlinedButton(
                              onPressed: () => _showCreateAccountDialog(context),
                              child: const Text('Créer un compte'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('DSI Ministère — Burkina Faso',
                        style: TextStyle(fontSize: 11, color: AppColors.muted)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Mot de passe oublié ──────────────────────────────────────────

  void _showForgotDialog(BuildContext context) {
    final emailCtrl = TextEditingController();
    final authBloc  = context.read<AuthBloc>();

    showDialog(
      context: context,
      builder: (ctx) => BlocProvider.value(
        value: authBloc,
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (ctx, state) {
            if (state is AuthForgotSent) {
              Navigator.pop(ctx);
              _showResetCodeDialog(context, authBloc);
            } else if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.msg), backgroundColor: AppColors.danger));
            }
          },
          builder: (ctx, state) {
            final loading = state is AuthLoading;
            return AlertDialog(
              title: const Text('Mot de passe oublié',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Entrez votre email. Vous recevrez un code à 6 chiffres valable 15 minutes.',
                    style: TextStyle(fontSize: 13, color: AppColors.muted)),
                const SizedBox(height: 14),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Adresse email',
                    prefixIcon: Icon(Icons.mail_outline, size: 18),
                  ),
                ),
              ]),
              actions: [
                TextButton(onPressed: loading ? null : () => Navigator.pop(ctx), child: const Text('Annuler')),
                ElevatedButton(
                  onPressed: loading ? null : () => ctx.read<AuthBloc>().add(
                    ForgotPwdSubmitted(emailCtrl.text.trim())),
                  child: loading
                    ? const SizedBox(height: 16, width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Envoyer le code'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showResetCodeDialog(BuildContext context, AuthBloc authBloc) {
    final codeCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    bool obscure   = true;

    showDialog(
      context: context,
      builder: (ctx) => BlocProvider.value(
        value: authBloc,
        child: StatefulBuilder(
          builder: (ctx2, setDialogState) => BlocConsumer<AuthBloc, AuthState>(
            listener: (ctx2, state) {
              if (state is AuthResetOk) {
                Navigator.pop(ctx2);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mot de passe réinitialisé ! Connectez-vous.'),
                    backgroundColor: Color.fromARGB(255, 7, 62, 30)));
              } else if (state is AuthError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.msg), backgroundColor: AppColors.danger));
              }
            },
            builder: (ctx2, state) {
              final loading = state is AuthLoading;
              return AlertDialog(
                title: const Text('Nouveau mot de passe',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('Entrez le code reçu par email et votre nouveau mot de passe.',
                      style: TextStyle(fontSize: 13, color: AppColors.muted)),
                  const SizedBox(height: 14),
                  TextField(
                    controller: codeCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: 'Code à 6 chiffres',
                      prefixIcon: Icon(Icons.pin_outlined, size: 18),
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passCtrl,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: 'Nouveau mot de passe',
                      hintText: '8 caractères minimum',
                      prefixIcon: const Icon(Icons.lock_outline, size: 18),
                      suffixIcon: IconButton(
                        icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
                        onPressed: () => setDialogState(() => obscure = !obscure),
                      ),
                    ),
                  ),
                ]),
                actions: [
                  TextButton(onPressed: loading ? null : () => Navigator.pop(ctx2), child: const Text('Annuler')),
                  ElevatedButton(
                    onPressed: loading ? null : () {
                      if (codeCtrl.text.length != 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Entrez un code à 6 chiffres')));
                        return;
                      }
                      if (passCtrl.text.length < 8) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Mot de passe trop court (8 min)')));
                        return;
                      }
                      ctx2.read<AuthBloc>().add(
                        ResetPwdSubmitted(codeCtrl.text.trim(), passCtrl.text.trim()));
                    },
                    child: loading
                      ? const SizedBox(height: 16, width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Confirmer'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ── Créer un compte — avec dropdowns dynamiques ──────────────────

  void _showCreateAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const _CreateAccountDialog(),
    );
  }
}

// Dialogue séparé avec StatefulWidget pour charger les structures/services depuis l'API
class _CreateAccountDialog extends StatefulWidget {
  const _CreateAccountDialog();
  @override
  State<_CreateAccountDialog> createState() => _CreateAccountDialogState();
}

class _CreateAccountDialogState extends State<_CreateAccountDialog> {
  final _nomCtrl    = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  final _telCtrl    = TextEditingController();
  final _iuCtrl     = TextEditingController();

  List<Structure> _structures        = [];
  List<Service>   _services          = [];
  List<Service>   _filteredServices  = [];
  Structure?      _selectedStructure;
  Service?        _selectedService;
  String?         _selectedRole;
  bool            _loading           = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final structures = await sl<AdminService>().getStructures();
      final services   = await sl<AdminService>().getServices();
      if (mounted) setState(() {
        _structures       = structures;
        _services         = services;
        _filteredServices = services;
        _loading          = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onStructureChanged(Structure? s) {
    setState(() {
      _selectedStructure = s;
      _selectedService   = null;
      _filteredServices  = s == null
          ? _services
          : _services.where((svc) => svc.structure?.id == s.id).toList();
    });
  }

  @override
  void dispose() {
    _nomCtrl.dispose(); _prenomCtrl.dispose(); _emailCtrl.dispose();
    _passCtrl.dispose(); _telCtrl.dispose(); _iuCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text('Créer un compte', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      content: _loading
        ? const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()))
        : SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: _nomCtrl,
                decoration: const InputDecoration(labelText: 'Nom', prefixIcon: Icon(Icons.person_outline, size: 18))),
              const SizedBox(height: 10),
              TextField(controller: _prenomCtrl,
                decoration: const InputDecoration(labelText: 'Prénom', prefixIcon: Icon(Icons.person_outline, size: 18))),
              const SizedBox(height: 10),
              TextField(controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline, size: 18)),
                keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 10),
              TextField(controller: _passCtrl,
                decoration: const InputDecoration(labelText: 'Mot de passe', prefixIcon: Icon(Icons.lock_outline, size: 18)),
                obscureText: true),
              const SizedBox(height: 10),
              TextField(controller: _telCtrl,
                decoration: const InputDecoration(labelText: 'Téléphone', prefixIcon: Icon(Icons.phone, size: 18)),
                keyboardType: TextInputType.phone),
              const SizedBox(height: 10),

              // ✅ Dropdown Structure dynamique (depuis API)
              DropdownButtonFormField<Structure>(
                value: _selectedStructure,
                decoration: const InputDecoration(
                  labelText: 'Structure',
                  prefixIcon: Icon(Icons.domain, size: 18),
                ),
                hint: Text(_structures.isEmpty ? 'Aucune structure disponible' : 'Sélectionner'),
                items: _structures
                    .map((s) => DropdownMenuItem(value: s, child: Text(s.nom)))
                    .toList(),
                onChanged: _structures.isEmpty ? null : _onStructureChanged,
              ),
              const SizedBox(height: 10),

              // ✅ Dropdown Service filtré par structure
              DropdownButtonFormField<Service>(
                value: _selectedService,
                decoration: const InputDecoration(
                  labelText: 'Service',
                  prefixIcon: Icon(Icons.miscellaneous_services, size: 18),
                ),
                hint: Text(_selectedStructure == null
                    ? 'Choisissez d\'abord une structure'
                    : _filteredServices.isEmpty
                        ? 'Aucun service disponible'
                        : 'Sélectionner'),
                items: _filteredServices
                    .map((s) => DropdownMenuItem(value: s, child: Text(s.nom)))
                    .toList(),
                onChanged: _filteredServices.isEmpty ? null : (v) => setState(() => _selectedService = v),
              ),
              const SizedBox(height: 10),

              TextField(controller: _iuCtrl,
                decoration: const InputDecoration(labelText: 'Identifiant unique', prefixIcon: Icon(Icons.badge, size: 18))),
              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(labelText: 'Rôle', prefixIcon: Icon(Icons.shield_outlined, size: 18)),
                items: const [
                  DropdownMenuItem(value: 'ADMIN',      child: Text('Administrateur')),
                  DropdownMenuItem(value: 'AGENT_DSI',  child: Text('Agent DSI')),
                  DropdownMenuItem(value: 'SUPERVISEUR',child: Text('Superviseur')),
                  DropdownMenuItem(value: 'USAGER',     child: Text('Usager')),
                ],
                onChanged: (v) => setState(() => _selectedRole = v),
              ),
            ]),
          ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: _loading ? null : () {
            Navigator.pop(context);
            context.read<AuthBloc>().add(RegisterSubmitted({
              'nom':      _nomCtrl.text.trim(),
              'prenom':   _prenomCtrl.text.trim(),
              'email':    _emailCtrl.text.trim(),
              'password': _passCtrl.text.trim(),
              'telephone': _telCtrl.text.trim(),
              if (_selectedStructure != null) 'structureId': _selectedStructure!.id,
              if (_selectedService != null)   'serviceId':   _selectedService!.id,
              if (_iuCtrl.text.isNotEmpty) 'identifiantUnique': _iuCtrl.text.trim(),
              'role': _selectedRole ?? 'USAGER',
            }));
          },
          child: const Text('Créer le compte'),
        ),
      ],
    );
  }
}