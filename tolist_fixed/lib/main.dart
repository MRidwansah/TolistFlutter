import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User; // Tambahkan hide User di sini
import 'theme.dart';
import 'models/models.dart';
import 'services/storage_service.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Supabase (Perhatikan huruf K kapital pada anonKey)
  await Supabase.initialize(
    url: 'https://vbjgfjhdtkkowzcuacwc.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZiamdmamhkdGtrb3d6Y3VhY3djIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODExMjA1NTMsImV4cCI6MjA5NjY5NjU1M30.VUIhZE7_3D5Xdl4xAozuC7q9-WHKEhwF0WW_6BfMsWM',
  );

  // Set status bar style to match dark theme
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF111827),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Cek apakah user sudah login di Supabase
  final session = Supabase.instance.client.auth.currentSession;
  User? user;
  
  if (session != null) {
    user = await StorageService.getUserProfile();
  }

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