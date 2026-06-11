import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../theme.dart';
import '../services/storage_service.dart';
import 'main_shell.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscure = true;

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });

    final input = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (input.isEmpty || password.isEmpty) {
      setState(() { _loading = false; _error = 'Kolom tidak boleh kosong.'; });
      return;
    }

    try {
      String emailToLogin = input;

      // 1. Cek apakah yang diketik user adalah Email atau Username
      if (!input.contains('@')) {
        // Cari email pasangan dari username ini di database Supabase
        final response = await supa.Supabase.instance.client
            .from('profiles')
            .select('email')
            .eq('username', input)
            .maybeSingle();

        // Kalau username tidak ditemukan di database
        if (response == null) {
          setState(() { _loading = false; _error = 'Username tidak ditemukan.'; });
          return;
        }
        
        // Ambil email aslinya untuk dipakai login
        emailToLogin = response['email'];
      }

      // 2. Login menggunakan Supabase Auth
      await supa.Supabase.instance.client.auth.signInWithPassword(
        email: emailToLogin,
        password: password,
      );

      // 3. Ambil profile lengkap
      final user = await StorageService.getUserProfile();
      
      if (!mounted) return;
      if (user != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => MainShell(user: user)),
        );
      } else {
        setState(() => _error = 'Gagal memuat profil pengguna.');
      }
    } on supa.AuthException catch (_) {
      setState(() => _error = 'Kombinasi Username/Email atau password salah.');
    } catch (e) {
      setState(() => _error = 'Terjadi kesalahan sistem.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showForgotPassword() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => _ForgotPasswordSheet(),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Stack(children: [
        Positioned(top: -100, left: -100, child: Container(width: 500, height: 500,
          decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.indigo.withOpacity(0.2)))),
        Positioned(bottom: -100, right: -100, child: Container(width: 400, height: 400,
          decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.emerald.withOpacity(0.1)))),

        SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                const SizedBox(height: 20),

                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.bgCard.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: AppColors.borderSlate800.withOpacity(0.5)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 48, offset: const Offset(0, 16))],
                  ),
                  child: Column(children: [
                    // ── Branding panel ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                          colors: [AppColors.indigo.withOpacity(0.2), AppColors.bgPrimary.withOpacity(0.4)]),
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
                        border: Border(bottom: BorderSide(color: AppColors.borderSlate800.withOpacity(0.5))),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Transform.rotate(
                          angle: 0.05,
                          child: Container(
                            width: 52, height: 52,
                            decoration: BoxDecoration(color: AppColors.indigo, borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: AppColors.indigo.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 4))]),
                            child: Center(child: Text('ToList', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11))),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text('Tulis ide,\nEksekusi tugas.',
                          style: GoogleFonts.inter(color: AppColors.textWhite, fontWeight: FontWeight.w900, fontSize: 28, height: 1.2)),
                        const SizedBox(height: 10),
                        Text('Satu tempat untuk mengatur seluruh\nritme produktivitasmu sehari-hari.',
                          style: GoogleFonts.inter(color: AppColors.textSlate400, fontSize: 13, fontWeight: FontWeight.w500, height: 1.6)),
                      ]),
                    ),

                    // ── Form panel ──
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Selamat Datang!',
                          style: GoogleFonts.inter(color: AppColors.textWhite, fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: -0.5)),
                        const SizedBox(height: 4),
                        Text('Masuk untuk melanjutkan catatanmu.',
                          style: GoogleFonts.inter(color: AppColors.textSlate500, fontSize: 13)),
                        const SizedBox(height: 28),

                        // Error
                        if (_error != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.rose.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.rose.withOpacity(0.4)),
                            ),
                            child: Row(children: [
                              const Icon(Icons.error_outline, color: AppColors.rose, size: 16),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.rose, fontSize: 13))),
                            ]),
                          ),
                          const SizedBox(height: 20),
                        ],

                        _label('Username / Email'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.text,
                          style: const TextStyle(color: AppColors.textSlate200, fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'Masukkan Username atau Email',
                            prefixIcon: Icon(Icons.person_outline, color: AppColors.textSlate500, size: 18),
                          ),
                        ),
                        const SizedBox(height: 16),

                        _label('Password'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _passwordCtrl,
                          obscureText: _obscure,
                          style: const TextStyle(color: AppColors.textSlate200, fontSize: 14),
                          onSubmitted: (_) => _login(),
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSlate500, size: 18),
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => _obscure = !_obscure),
                              icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                                  color: AppColors.textSlate500, size: 18),
                            ),
                          ),
                        ),

                        // ── Lupa Password ──
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: _showForgotPassword,
                            child: Text(
                              'Lupa Password?',
                              style: GoogleFonts.inter(color: AppColors.indigo, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),

                        const SizedBox(height: 22),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.indigo,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              elevation: 0,
                            ),
                            child: _loading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text('Login', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 15)),
                          ),
                        ),

                        const SizedBox(height: 24),
                        Center(
                          child: GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                            child: RichText(
                              text: TextSpan(
                                style: GoogleFonts.inter(color: AppColors.textSlate500, fontSize: 13),
                                children: [
                                  const TextSpan(text: 'Belum punya akun? '),
                                  TextSpan(text: 'Daftar', style: GoogleFonts.inter(color: AppColors.indigo, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ]),
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _label(String text) => Text(
    text.toUpperCase(),
    style: GoogleFonts.inter(color: AppColors.textSlate500, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5),
  );
}

// ─────────────────────────────────────────────
// Simple Forgot Password Bottom Sheet (2 Steps Tanpa OTP)
// ─────────────────────────────────────────────
class _ForgotPasswordSheet extends StatefulWidget {
  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  int _step = 0; // 0 = Lupa Password (Email), 1 = Buat Password Baru
  final _emailCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _loading = false;
  String? _error;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Masukkan email yang valid.');
      return;
    }
    setState(() {
      _error = null;
      _step = 1;
    });
  }

  Future<void> _saveNewPassword() async {
    final newPass = _newPassCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (newPass.length < 6) {
      setState(() => _error = 'Password minimal 6 karakter.');
      return;
    }
    if (newPass != confirm) {
      setState(() => _error = 'Password tidak cocok.');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      // CATATAN PENTING:
      // Fungsi Supabase updateUser() standar akan GAGAL di sini karena user belum login 
      // dan tidak ada OTP yang diverifikasi. 
      // Kamu harus memanggil API Custom milikmu di sini.
      
      /* Contoh pemanggilan API:
         await myCustomBackend.forceResetPassword(
           email: _emailCtrl.text.trim(),
           newPassword: newPass,
         );
      */

      // Simulasi loading sementara (Hapus ini jika API sudah dipasang)
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 16),
          const SizedBox(width: 8),
          Text('Password berhasil diperbarui!', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
        ]),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ));
    } catch (e) {
      setState(() => _error = 'Gagal memperbarui password.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Handle Indicator
          Container(
            width: 40, height: 4, 
            decoration: BoxDecoration(color: AppColors.borderSlate700, borderRadius: BorderRadius.circular(4))
          ),
          const SizedBox(height: 24),
          
          Text(
            _step == 0 ? 'Lupa Password' : 'Buat Password Baru',
            style: GoogleFonts.inter(color: AppColors.textWhite, fontWeight: FontWeight.w800, fontSize: 20),
          ),
          
          if (_step == 0) ...[
            const SizedBox(height: 8),
            Text(
              'Masukkan email terdaftar untuk mereset password langsung\ntanpa email.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppColors.textSlate400, fontSize: 13, height: 1.5),
            ),
          ],
          
          const SizedBox(height: 24),

          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: AppColors.rose.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.rose.withOpacity(0.3))),
              child: Row(children: [
                const Icon(Icons.error_outline, color: AppColors.rose, size: 15),
                const SizedBox(width: 8),
                Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.rose, fontSize: 12))),
              ]),
            ),
          ],

          if (_step == 0) ..._stepOneUI() else ..._stepTwoUI(),
        ],
      ),
    );
  }

  // --- TAMPILAN 1: INPUT EMAIL ---
  List<Widget> _stepOneUI() => [
    Align(
      alignment: Alignment.centerLeft,
      child: Text('Email', style: GoogleFonts.inter(color: AppColors.textSlate300, fontSize: 12, fontWeight: FontWeight.w600)),
    ),
    const SizedBox(height: 8),
    TextField(
      controller: _emailCtrl,
      keyboardType: TextInputType.emailAddress,
      style: const TextStyle(color: AppColors.textSlate200, fontSize: 14),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        filled: true,
        fillColor: const Color(0xFF1E293B), // Warna background input sesuai gambar
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    ),
    const SizedBox(height: 24),
    Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6), // Warna biru "Lanjutkan"
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Lanjutkan', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF475569), // Warna abu-abu "Batal"
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Batal', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    )
  ];

  // -- BUAT PASSWORD BARU ---
  List<Widget> _stepTwoUI() => [
    Align(
      alignment: Alignment.centerLeft,
      child: Text('Password Baru', style: GoogleFonts.inter(color: AppColors.textSlate300, fontSize: 12, fontWeight: FontWeight.w600)),
    ),
    const SizedBox(height: 8),
    TextField(
      controller: _newPassCtrl,
      obscureText: _obscure,
      style: const TextStyle(color: AppColors.textSlate200, fontSize: 14),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        filled: true,
        fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        suffixIcon: IconButton(
          onPressed: () => setState(() => _obscure = !_obscure),
          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: AppColors.textSlate500, size: 18),
        ),
      ),
    ),
    const SizedBox(height: 16),
    Align(
      alignment: Alignment.centerLeft,
      child: Text('Konfirmasi Password', style: GoogleFonts.inter(color: AppColors.textSlate300, fontSize: 12, fontWeight: FontWeight.w600)),
    ),
    const SizedBox(height: 8),
    TextField(
      controller: _confirmCtrl,
      obscureText: _obscure,
      style: const TextStyle(color: AppColors.textSlate200, fontSize: 14),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        filled: true,
        fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    ),
    const SizedBox(height: 24),
    SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loading ? null : _saveNewPassword,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981), // Warna hijau "Simpan Password" sesuai gambar
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _loading 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text('Simpan Password', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
      ),
    ),
    const SizedBox(height: 12),
    TextButton(
      onPressed: () => setState(() { _step = 0; _error = null; }),
      child: Text('Kembali', style: GoogleFonts.inter(color: AppColors.textSlate400, fontSize: 12)),
    )
  ];
}