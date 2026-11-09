import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'connection/server_connection.dart';
import 'connection/settings_store.dart';
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
      ],
      child: Consumer<AppSettings>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'Mousify',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: settings.isDark ? ThemeMode.dark : ThemeMode.light,
            home: const HomeShell(),
          );
        },
      ),
    );
  }
}
