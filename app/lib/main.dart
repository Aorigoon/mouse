import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth/auth_service.dart';
import 'auth/profile_store.dart';
import 'connection/server_connection.dart';
import 'connection/settings_store.dart';
import 'connection/windows.dart';
import 'theme.dart';
import 'views/home_shell.dart';

void main() {
  runApp(const MousifyApp());
}

class MousifyApp extends StatelessWidget {
  const MousifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppSettings()),
        ChangeNotifierProvider(create: (_) => MousifyConnection()),
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ProfileStore()),
        // WindowsService ko connection chahiye — upar wali provider
        // se leta hai (create order me pehle aati hai).
        ChangeNotifierProvider(
          create: (ctx) => WindowsService(ctx.read<MousifyConnection>()),
        ),
      ],
      child: Consumer<AppSettings>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'Mousify',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: settings.themeMode,
            home: const HomeShell(),
          );
        },
      ),
    );
  }
}
