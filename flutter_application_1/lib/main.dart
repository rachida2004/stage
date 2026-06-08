import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
        BlocProvider(create: (_) => AdminBloc(sl.admin)),
      ],
      child: MaterialApp(
        title: 'DSI Connect',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
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
      listener: (context, state) {
        if (state is AuthOut) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      },
      child: const LoginScreen(),
    );
  }
}
