import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'controllers/probe_controller.dart';
import 'screens/dashboard_screen.dart';
import 'screens/probe_detail_screen.dart';
import 'screens/charts_screen.dart';
import 'screens/sessions_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final probeController = ProbeController();
  await probeController.init();

  runApp(MyApp(probeController: probeController));
}

class MyApp extends StatelessWidget {
  final ProbeController probeController;

  const MyApp({super.key, required this.probeController});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/probe/:id',
          builder: (context, state) {
            final probeId = state.pathParameters['id']!;
            return ProbeDetailScreen(probeId: probeId);
          },
        ),
        GoRoute(
          path: '/charts',
          builder: (context, state) => const ChartsScreen(),
        ),
        GoRoute(
          path: '/sessions',
          builder: (context, state) => const SessionsScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    );

    return ChangeNotifierProvider.value(
      value: probeController,
      child: MaterialApp.router(
        title: 'ThermoPro',
        theme: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(
            primary: const Color(0xFFFF9F0A),
            secondary: const Color(0xFFFF9F0A),
            surface: const Color(0xFF1C1C1E),
            background: const Color(0xFF000000),
          ),
          scaffoldBackgroundColor: const Color(0xFF000000),
          cardTheme: CardTheme(
            color: const Color(0xFF1C1C1E),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1C1C1E),
            elevation: 0,
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xFFFF9F0A),
            foregroundColor: Colors.black,
          ),
        ),
        routerConfig: router,
      ),
    );
  }
}
