import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscure = true;

  void _register() async {
    final username = _usernameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Semua field harus diisi.');
      return;
    }
    if (!email.contains('@')) {
      setState(() => _error = 'Format email tidak valid.');
      return;
    }
    if (password != confirm) {
      setState(() => _error = 'Password tidak cocok.');
      return;
    }
    if (username.length < 3) {
      setState(() => _error = 'Username minimal 3 karakter.');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Password minimal 6 karakter.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Registrasi menggunakan Supabase Auth
      await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'username': username}, // Data ini akan ditangkap oleh Trigger Supabase 
      );

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 16),
          const SizedBox(width: 8),
          Text('Akun berhasil dibuat! Silakan login.', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
        ]),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ));
      
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Terjadi kesalahan sistem.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.rose.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -80,
            child: Container(
              width: 450,
              height: 450,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.emerald.withOpacity(0.12),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Main card
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.bgCard.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(
                          color: AppColors.borderSlate800.withOpacity(0.5),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 48,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // ── Branding panel ──
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.emerald.withOpacity(0.12),
                                  AppColors.bgPrimary.withOpacity(0.4),
                                ],
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(40),
                                topRight: Radius.circular(40),
                              ),
                              border: Border(
                                bottom: BorderSide(
                                  color: AppColors.borderSlate800.withOpacity(0.5),
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Transform.rotate(
                                  angle: -0.05,
                                  child: Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: AppColors.emerald,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.emerald.withOpacity(0.3),
                                          blurRadius: 20,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        'ToList',
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 28),
                                Text(
                                  'Mulai Langkah\nBarumu Di Sini.',
                                  style: GoogleFonts.inter(
                                    color: AppColors.textWhite,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 28,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Bergabunglah dengan ribuan pengguna\nyang sudah menata hidupnya lebih terstruktur.',
                                  style: GoogleFonts.inter(
                                    color: AppColors.textSlate400,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    height: 1.6,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppColors.emerald.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppColors.emerald.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Text(
                                    'JOIN FREE FOREVER',
                                    style: GoogleFonts.inter(
                                      color: AppColors.emerald,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ── Form panel ──
                          Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Buat Akun Baru',
                                  style: GoogleFonts.inter(
                                    color: AppColors.textWhite,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 24,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Lengkapi data diri untuk memulai.',
                                  style: GoogleFonts.inter(
                                    color: AppColors.textSlate500,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 28),

                                if (_error != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: AppColors.rose.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                          color: AppColors.rose.withOpacity(0.4)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.error_outline,
                                            color: AppColors.rose, size: 16),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(_error!,
                                              style: const TextStyle(
                                                  color: AppColors.rose,
                                                  fontSize: 13)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],

                                _label('Nama Lengkap / Username'),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _usernameCtrl,
                                  style: const TextStyle(
                                      color: AppColors.textSlate200,
                                      fontSize: 14),
                                  decoration: const InputDecoration(
                                    hintText: 'Username',
                                    prefixIcon: Icon(Icons.person_outline,
                                        color: AppColors.textSlate500, size: 18),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                _label('Email'),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _emailCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  style: const TextStyle(
                                      color: AppColors.textSlate200,
                                      fontSize: 14),
                                  decoration: const InputDecoration(
                                    hintText: 'example@email.com',
                                    prefixIcon: Icon(Icons.mail_outline,
                                        color: AppColors.textSlate500, size: 18),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                _label('Password'),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _passwordCtrl,
                                  obscureText: _obscure,
                                  style: const TextStyle(
                                      color: AppColors.textSlate200,
                                      fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: '••••••••',
                                    prefixIcon: const Icon(Icons.lock_outline,
                                        color: AppColors.textSlate500, size: 18),
                                    suffixIcon: IconButton(
                                      onPressed: () =>
                                          setState(() => _obscure = !_obscure),
                                      icon: Icon(
                                        _obscure
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: AppColors.textSlate500,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                _label('Konfirmasi Password'),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _confirmCtrl,
                                  obscureText: _obscure,
                                  style: const TextStyle(
                                      color: AppColors.textSlate200,
                                      fontSize: 14),
                                  onSubmitted: (_) => _register(),
                                  decoration: const InputDecoration(
                                    hintText: '••••••••',
                                    prefixIcon: Icon(Icons.lock_outline,
                                        color: AppColors.textSlate500, size: 18),
                                  ),
                                ),
                                const SizedBox(height: 28),

                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _loading ? null : _register,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.emerald,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 18),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: _loading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(
                                            'Daftar Sekarang',
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 15,
                                            ),
                                          ),
                                  ),
                                ),

                                const SizedBox(height: 24),
                                Center(
                                  child: GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: RichText(
                                      text: TextSpan(
                                        style: GoogleFonts.inter(
                                          color: AppColors.textSlate500,
                                          fontSize: 13,
                                        ),
                                        children: [
                                          const TextSpan(
                                              text: 'Sudah punya akun? '),
                                          TextSpan(
                                            text: 'Masuk',
                                            style: GoogleFonts.inter(
                                              color: AppColors.indigo,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
        text.toUpperCase(),
        style: GoogleFonts.inter(
          color: AppColors.textSlate500,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      );
}