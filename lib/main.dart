import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/repositories/local_repositories.dart';
import 'data/services/ssh_service.dart';
import 'presentation/pages/connect_page.dart';
import 'presentation/pages/lock_page.dart';
import 'presentation/providers/auth_connection_provider.dart';
import 'presentation/providers/dashboard_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  // Composition root: satu-satunya tempat implementasi konkret dirangkai.
  final ssh = DartSshGateway();
  final passcodeRepo = LocalPasscodeRepository(prefs);
  final profileRepo = LocalServerProfileRepository(prefs);
  final actionRepo = LocalActionRepository(prefs);

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider(passcodeRepo)),
      ChangeNotifierProvider(create: (_) => ConnectionProvider(ssh, profileRepo)),
      ChangeNotifierProvider(create: (_) => DashboardProvider(ssh, actionRepo)),
    ],
    child: const RemoteKuApp(),
  ));
}

class RemoteKuApp extends StatelessWidget {
  const RemoteKuApp({super.key});

  @override
  Widget build(BuildContext context) {
    final stage = context.select<AuthProvider, AuthStage>((a) => a.stage);
    return MaterialApp(
      title: 'RemoteKu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: stage == AuthStage.locked ? const LockPage() : const ConnectPage(),
    );
  }
}
