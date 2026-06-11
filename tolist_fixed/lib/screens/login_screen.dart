import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../models/models.dart';
import '../services/storage_service.dart';
import 'main_shell.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscure = true;

  // Akun bawaan (demo)
  static const _builtinUsers = [
    {'username': 'admin',  'password': '123',      'email': 'admin@tolist.app'},
    {'username': 'nopal',  'password': '1234',     'email': 'nopal@tolist.app'},
    {'username': 'amsal',  'password': '000',      'email': 'amsal@tolist.app'},
    {'username': 'tes',    'password': 'tes',      'email': 'tes@tolist.app'},
    {'username': 'ilham',  'password': 'ilham123', 'email': 'ilham@tolist.app'},
  ];

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    await Future.delayed(const Duration(milliseconds: 600));

    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    // 1. Cek akun builtin
    Map<String, dynamic>? match = _builtinUsers.cast<Map<String, dynamic>>().firstWhere(
      (u) => u['username'] == username && u['password'] == password,
      orElse: () => {},
    );

    // 2. Kalau tidak ketemu, cek akun yang didaftarkan user
    if (match.isEmpty) {
      final registered = await StorageService.getRegisteredUsers();
      match = registered.firstWhere(
        (u) => (u['username'] == username || u['email'] == username) && u['password'] == password,
        orElse: () => {},
      );
    }

    if (match.isEmpty) {
      setState(() { _loading = false; _error = 'Username/email atau password salah.'; });
      return;
    }

    final user = User(
      id: (match['id'] as int?) ?? (_builtinUsers.indexWhere((u) => u['username'] == username) + 1),
      username: match['username'] as String,
      email: match['email'] as String? ?? '',
    );
    await StorageService.saveUser(user);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => MainShell(user: user)),
    );
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
    _usernameCtrl.dispose();
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
                              Icon(Icons.error_outline, color: AppColors.rose, size: 16),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_error!, style: TextStyle(color: AppColors.rose, fontSize: 13))),
                            ]),
                          ),
                          const SizedBox(height: 20),
                        ],

                        _label('Email / Username'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _usernameCtrl,
                          style: const TextStyle(color: AppColors.textSlate200, fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'username atau email',
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
// Forgot Password Bottom Sheet
// ─────────────────────────────────────────────
class _ForgotPasswordSheet extends StatefulWidget {
  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  // Step: 0 = input email, 1 = input kode verifikasi, 2 = reset password
  int _step = 0;
  final _emailCtrl     = TextEditingController();
  final _codeCtrl      = TextEditingController();
  final _newPassCtrl   = TextEditingController();
  final _confirmCtrl   = TextEditingController();

  bool _loading = false;
  String? _error;
  bool _obscure = true;

  // Kode verifikasi yang "dikirim" (simulasi)
  String _sentCode = '';
  String _verifiedEmail = '';

  @override
  void dispose() {
    _emailCtrl.dispose(); _codeCtrl.dispose();
    _newPassCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  // Step 0 → kirim kode ke email
  Future<void> _sendCode() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Masukkan email yang valid.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    await Future.delayed(const Duration(milliseconds: 800));

    // Cek apakah email terdaftar (builtin atau registered)
    bool found = false;
    final builtins = [
      'admin@tolist.app', 'nopal@tolist.app', 'amsal@tolist.app',
      'tes@tolist.app', 'ilham@tolist.app'
    ];
    if (builtins.any((e) => e.toLowerCase() == email.toLowerCase())) found = true;
    if (!found) {
      final registered = await StorageService.getRegisteredUsers();
      found = registered.any((u) => (u['email'] as String).toLowerCase() == email.toLowerCase());
    }

    if (!found) {
      setState(() { _loading = false; _error = 'Email tidak terdaftar di sistem.'; });
      return;
    }

    // Generate kode 6 digit (simulasi — di prod dikirim via email)
    _sentCode = (100000 + DateTime.now().millisecondsSinceEpoch % 900000).toString().substring(0, 6);
    _verifiedEmail = email;

    setState(() { _loading = false; _step = 1; });

    // Tampilkan kode di snackbar (simulasi email)
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.mark_email_read_outlined, color: Color(0xFF6366F1), size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text('Kode verifikasi: $_sentCode  (simulasi — cek "email" Anda)',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12))),
      ]),
      backgroundColor: const Color(0xFF1E293B),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 8),
    ));
  }

  // Step 1 → verifikasi kode
  void _verifyCode() {
    if (_codeCtrl.text.trim() != _sentCode) {
      setState(() => _error = 'Kode verifikasi salah. Coba lagi.');
      return;
    }
    setState(() { _error = null; _step = 2; });
  }

  // Step 2 → reset password
  Future<void> _resetPassword() async {
    final newPass = _newPassCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();
    if (newPass.length < 6) { setState(() => _error = 'Password minimal 6 karakter.'); return; }
    if (newPass != confirm) { setState(() => _error = 'Password tidak cocok.'); return; }

    setState(() { _loading = true; _error = null; });
    await Future.delayed(const Duration(milliseconds: 600));

    final ok = await StorageService.updatePassword(_verifiedEmail, newPass);

    if (!mounted) return;
    setState(() => _loading = false);

    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 16),
          const SizedBox(width: 8),
          Text('Password berhasil diperbarui! Silakan login.', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
        ]),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ));
    } else {
      setState(() => _error = 'Gagal memperbarui password. Email builtin tidak bisa diubah.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Handle bar
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.borderSlate700, borderRadius: BorderRadius.circular(4)))),
        const SizedBox(height: 20),

        // Header
        Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.indigo.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.lock_reset_rounded, color: AppColors.indigo, size: 20),
          ),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Lupa Password', style: GoogleFonts.inter(color: AppColors.textWhite, fontWeight: FontWeight.w800, fontSize: 18)),
            Text(_stepSubtitle(), style: GoogleFonts.inter(color: AppColors.textSlate500, fontSize: 12)),
          ]),
        ]),

        // Progress dots
        const SizedBox(height: 20),
        Row(children: List.generate(3, (i) => Expanded(
          child: Container(
            height: 3, margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: i <= _step ? AppColors.indigo : AppColors.borderSlate800,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ))),
        const SizedBox(height: 24),

        // Error
        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: AppColors.rose.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.rose.withOpacity(0.3))),
            child: Row(children: [
              Icon(Icons.error_outline, color: AppColors.rose, size: 15),
              const SizedBox(width: 8),
              Expanded(child: Text(_error!, style: TextStyle(color: AppColors.rose, fontSize: 12))),
            ]),
          ),
          const SizedBox(height: 16),
        ],

        // Step content
        if (_step == 0) ..._stepEmail()
        else if (_step == 1) ..._stepCode()
        else ..._stepReset(),
      ]),
    );
  }

  String _stepSubtitle() {
    if (_step == 0) return 'Masukkan email yang terdaftar';
    if (_step == 1) return 'Cek email kamu untuk kode verifikasi';
    return 'Buat password baru';
  }

  List<Widget> _stepEmail() => [
    _label('Alamat Email'),
    const SizedBox(height: 8),
    TextField(
      controller: _emailCtrl,
      keyboardType: TextInputType.emailAddress,
      style: const TextStyle(color: AppColors.textSlate200, fontSize: 14),
      decoration: const InputDecoration(
        hintText: 'example@email.com',
        prefixIcon: Icon(Icons.mail_outline, color: AppColors.textSlate500, size: 18),
      ),
    ),
    const SizedBox(height: 20),
    _actionBtn('Kirim Kode Verifikasi', Icons.send_rounded, _loading ? null : _sendCode),
  ];

  List<Widget> _stepCode() => [
    Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.indigo.withOpacity(0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.indigo.withOpacity(0.2))),
      child: Row(children: [
        const Icon(Icons.mark_email_read_outlined, color: AppColors.indigo, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(
          'Kode 6 digit telah "dikirim" ke $_verifiedEmail\n(Lihat notifikasi di atas)',
          style: GoogleFonts.inter(color: AppColors.textSlate200, fontSize: 12, height: 1.5),
        )),
      ]),
    ),
    const SizedBox(height: 18),
    _label('Kode Verifikasi'),
    const SizedBox(height: 8),
    TextField(
      controller: _codeCtrl,
      keyboardType: TextInputType.number,
      maxLength: 6,
      style: GoogleFonts.inter(color: AppColors.textSlate200, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 8),
      decoration: const InputDecoration(
        hintText: '------',
        counterText: '',
        prefixIcon: Icon(Icons.tag_rounded, color: AppColors.textSlate500, size: 18),
      ),
    ),
    const SizedBox(height: 20),
    _actionBtn('Verifikasi Kode', Icons.verified_rounded, _verifyCode),
    const SizedBox(height: 12),
    Center(child: GestureDetector(
      onTap: () => setState(() { _step = 0; _error = null; _codeCtrl.clear(); }),
      child: Text('Kirim ulang kode', style: GoogleFonts.inter(color: AppColors.indigo, fontSize: 12, fontWeight: FontWeight.w600)),
    )),
  ];

  List<Widget> _stepReset() => [
    _label('Password Baru'),
    const SizedBox(height: 8),
    TextField(
      controller: _newPassCtrl,
      obscureText: _obscure,
      style: const TextStyle(color: AppColors.textSlate200, fontSize: 14),
      decoration: InputDecoration(
        hintText: '••••••••',
        prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSlate500, size: 18),
        suffixIcon: IconButton(
          onPressed: () => setState(() => _obscure = !_obscure),
          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: AppColors.textSlate500, size: 18),
        ),
      ),
    ),
    const SizedBox(height: 14),
    _label('Konfirmasi Password Baru'),
    const SizedBox(height: 8),
    TextField(
      controller: _confirmCtrl,
      obscureText: _obscure,
      style: const TextStyle(color: AppColors.textSlate200, fontSize: 14),
      onSubmitted: (_) => _resetPassword(),
      decoration: const InputDecoration(
        hintText: '••••••••',
        prefixIcon: Icon(Icons.lock_outline, color: AppColors.textSlate500, size: 18),
      ),
    ),
    const SizedBox(height: 20),
    _actionBtn('Simpan Password Baru', Icons.save_rounded, _loading ? null : _resetPassword),
  ];

  Widget _actionBtn(String label, IconData icon, VoidCallback? onTap) => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.indigo,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      child: _loading
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, size: 16),
              const SizedBox(width: 8),
              Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14)),
            ]),
    ),
  );

  Widget _label(String text) => Text(
    text.toUpperCase(),
    style: GoogleFonts.inter(color: AppColors.textSlate500, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5),
  );
}
