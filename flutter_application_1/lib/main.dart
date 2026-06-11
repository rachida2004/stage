import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// Ajouter cet import pour gérer la traduction en français
import 'package:flutter_localizations/flutter_localizations.dart'; 
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
        // userId non disponible au démarrage — updateUserId() est appelé dès AuthOk
        BlocProvider(create: (_) => TicketBloc(sl.tickets)),
        BlocProvider(create: (_) => NotifBloc(sl.notifications)),
        BlocProvider(create: (_) => AdminBloc(sl.admin)),
      ],
      child: MaterialApp(
        title: 'DSI Connect',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        
        // --- AJOUTS POUR LE FRANÇAIS ---
        supportedLocales: const [
          Locale('fr', 'FR'),
          Locale('en', 'US'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        locale: const Locale('fr', 'FR'), // Force l'application en français
        // -------------------------------

        home: const _AppRouter(),
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