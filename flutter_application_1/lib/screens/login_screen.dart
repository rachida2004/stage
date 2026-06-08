import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/all_blocs.dart';
import '../theme/app_theme.dart';
import '../services/services.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
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
        } else if (state is AuthForgotSent) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lien envoyé si le compte existe.')));
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
                      width: 56, height: 56,
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
                      child: const Icon(Icons.domain, color: Colors.white, size: 30),
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
                                  icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => _showForgotDialog(context),
                                style: TextButton.styleFrom(foregroundColor: AppColors.primary, padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                child: const Text('Mot de passe oublié ?', style: TextStyle(fontSize: 12)),
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: loading ? null : () => context.read<AuthBloc>().add(
                                LoginSubmitted(_emailCtrl.text.trim(), _passCtrl.text.trim())),
                              child: loading
                                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Se connecter'),
                            ),
                            const SizedBox(height: 16),
                            Row(children: const [
                              Expanded(child: Divider()),
                              Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('ou', style: TextStyle(fontSize: 12, color: AppColors.muted))),
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
                    const Text('DSI Ministère — Burkina Faso', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showForgotDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Réinitialiser le mot de passe', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Entrez votre adresse email pour recevoir un lien.', style: TextStyle(fontSize: 13, color: AppColors.muted)),
          const SizedBox(height: 14),
          TextField(controller: ctrl, keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Adresse email', prefixIcon: Icon(Icons.mail_outline, size: 18))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(ForgotPwdSubmitted(ctrl.text.trim()));
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }

  void _showCreateAccountDialog(BuildContext context) {
    final nomCtrl    = TextEditingController();
    final prenomCtrl = TextEditingController();
    final emailCtrl  = TextEditingController();
    final passCtrl   = TextEditingController();
    final telCtrl    = TextEditingController();
    final iuCtrl     = TextEditingController();
    String? structure, service, role;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Créer un compte', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nomCtrl,    decoration: const InputDecoration(labelText: 'Nom',       prefixIcon: Icon(Icons.person_outline, size: 18))),
              const SizedBox(height: 10),
              TextField(controller: prenomCtrl, decoration: const InputDecoration(labelText: 'Prénom',    prefixIcon: Icon(Icons.person_outline, size: 18))),
              const SizedBox(height: 10),
              TextField(controller: emailCtrl,  decoration: const InputDecoration(labelText: 'Email',     prefixIcon: Icon(Icons.mail_outline, size: 18)), keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 10),
              TextField(controller: passCtrl,   decoration: const InputDecoration(labelText: 'Mot de passe', prefixIcon: Icon(Icons.lock_outline, size: 18)), obscureText: true),
              const SizedBox(height: 10),
              TextField(controller: telCtrl,    decoration: const InputDecoration(labelText: 'Téléphone', prefixIcon: Icon(Icons.phone, size: 18)), keyboardType: TextInputType.phone),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Structure', prefixIcon: Icon(Icons.domain, size: 18)),
                items: ['Administratif', 'Financier', 'IT', 'Gestion materiel'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (v) => setState(() => structure = v),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Service', prefixIcon: Icon(Icons.miscellaneous_services, size: 18)),
                items: ['Statistique', 'DMP', 'RH', 'BCMP'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (v) => setState(() => service = v),
              ),
              const SizedBox(height: 10),
              TextField(controller: iuCtrl, decoration: const InputDecoration(labelText: 'Identifiant unique', prefixIcon: Icon(Icons.badge, size: 18))),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Rôle', prefixIcon: Icon(Icons.shield_outlined, size: 18)),
                items: {'ADMIN': 'Administrateur', 'AGENT_DSI': 'Agent DSI', 'SUPERVISEUR': 'Superviseur', 'USAGER': 'Usager'}
                    .entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                onChanged: (v) => setState(() => role = v),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.read<AuthBloc>().add(RegisterSubmitted({
                  'nom':    nomCtrl.text.trim(),
                  'prenom': prenomCtrl.text.trim(),
                  'email':  emailCtrl.text.trim(),
                  'password': passCtrl.text.trim(),
                  'telephone': telCtrl.text.trim(),
                  if (structure != null) 'structure': structure,
                  if (service != null) 'service': service,
                  if (iuCtrl.text.isNotEmpty) 'identifiantUnique': iuCtrl.text.trim(),
                  'role': role ?? 'USAGER',
                }));
              },
              child: const Text('Créer le compte'),
            ),
          ],
        ),
      ),
    );
  }
}
