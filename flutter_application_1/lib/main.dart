import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; 
import 'package:flutter_quill/flutter_quill.dart'; // <-- Ne pas oublier l'import
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'services/services.dart';
import 'bloc/all_blocs.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await sl.init();
  runApp(const DSIApp());
}

class DSIApp extends StatelessWidget {
  const DSIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthBloc(sl.auth)..add(CheckAuth())),
        BlocProvider(create: (_) => DashboardBloc(sl.dashboard)),
        BlocProvider(create: (_) => InvitationBloc(sl.invitations)),
        BlocProvider(create: (_) => TicketBloc(sl.tickets)),
        BlocProvider(create: (_) => NotifBloc(sl.notifications)),
        // Chargement initial des paramètres pour récupérer la langue sauvegardée
        BlocProvider(create: (_) => AdminBloc(sl.admin)..add(LoadSettings())), 
      ],
      // BlocBuilder pour reconstruire la MaterialApp quand la langue change
      child: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          // Détermination dynamique de la locale
          Locale currentLocale = const Locale('fr', 'FR');
          
          if (state is SettingsLoaded && state.settings.containsKey('langue')) {
            final lang = state.settings['langue'];
            currentLocale = (lang == 'English') 
                ? const Locale('en', 'US') 
                : const Locale('fr', 'FR');
          }

          return MaterialApp(
            title: 'DSI Connect',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            
            // Locale dynamique
            locale: currentLocale, 
            
            supportedLocales: const [
              Locale('fr', 'FR'),
              Locale('en', 'US'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              FlutterQuillLocalizations.delegate, // <-- AJOUTÉ ICI pour l'éditeur Word
            ],
            
            home: const _AppRouter(),
          );
        },
      ),
    );
  }
}

class _AppRouter extends StatelessWidget {
  const _AppRouter();

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
        if (state is AuthOut) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
        // Dès que l'utilisateur est connecté, injecter son userId dans TicketBloc
        if (state is AuthOk) {
          final uid = await sl.storage.userId;
          if (context.mounted) {
            context.read<TicketBloc>().updateUserId(uid);
          }
        }
      },
      child: const LoginScreen(),
    );
  }
}