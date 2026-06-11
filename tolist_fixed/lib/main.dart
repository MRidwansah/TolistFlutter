import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';
import 'models/models.dart';
import 'services/storage_service.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set status bar style to match dark theme
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF111827),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Portrait orientation only
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Check for saved session
  final user = await StorageService.getUser();

  runApp(ToListApp(initialUser: user));
}

class ToListApp extends StatelessWidget {
  final User? initialUser;
  const ToListApp({super.key, this.initialUser});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ToList',
      debugShowCheckedModeBanner: false,
      theme: appTheme(),
      home: initialUser != null
          ? MainShell(user: initialUser!)
          : const LoginScreen(),
    );
  }
}
