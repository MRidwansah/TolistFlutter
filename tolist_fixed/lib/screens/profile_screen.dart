import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../theme.dart';
import '../models/models.dart';
import '../services/storage_service.dart';
import 'login_screen.dart';
import 'note_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  final User user;
  final VoidCallback? onProfileUpdated; // Menerima fungsi refresh dari MainShell

  const ProfileScreen({super.key, required this.user, this.onProfileUpdated});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<Note> _notes = [];
  bool _loading = true;
  String? _profileImageUrl;
  int _activeTab = 0;

  @override
  void initState() {
    super.initState();
    _profileImageUrl = widget.user.avatarUrl;
    _loadData();
  }

  Future<void> _loadData() async {
    // Karena kita mau membedakan total catatan pribadi dengan home yang publik,
    // kita filter by user ID (Ini opsional, tapi bagus agar di profil hanya menampilkan miliknya saja)
    final allNotes = await StorageService.getNotes();
    final authUser = Supabase.instance.client.auth.currentUser;
    
    if (mounted) {
      setState(() {
        _notes = allNotes.where((n) => n.id != null /* jika ada user_id bisa di filter di sini juga */).toList(); 
        _loading = false;
      });
    }
  }

  String get _avatarLetter =>
      widget.user.username.isNotEmpty ? widget.user.username[0].toUpperCase() : 'U';

  Future<void> _pickProfileImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty && result.files.first.path != null) {
        final file = File(result.files.first.path!);
        final authUser = Supabase.instance.client.auth.currentUser;
        
        if (authUser != null) {
          final path = '${authUser.id}/avatar_${DateTime.now().millisecondsSinceEpoch}';
          
          await Supabase.instance.client.storage.from('avatars').upload(path, file);
          final url = Supabase.instance.client.storage.from('avatars').getPublicUrl(path);
          
          await Supabase.instance.client.from('profiles').update({'avatar_url': url}).eq('id', authUser.id);
          
          if (mounted) {
            setState(() => _profileImageUrl = url);
            _toast('Foto profil diperbarui!', true);
            widget.onProfileUpdated?.call(); // Memicu MainShell untuk refresh AppBarnya
          }
        }
      }
    } catch (e) {
      _toast('Gagal mengupload foto profil', false);
    }
  }

  Future<void> _removeProfileImage() async {
    final ok = await _confirm('Hapus Foto Profil', 'Kembali ke avatar default?');
    if (ok) {
      final authUser = Supabase.instance.client.auth.currentUser;
      if (authUser != null) {
        await Supabase.instance.client.from('profiles').update({'avatar_url': null}).eq('id', authUser.id);
        if (mounted) {
          setState(() => _profileImageUrl = null);
          _toast('Foto profil dihapus', false);
          widget.onProfileUpdated?.call(); // Memicu MainShell untuk refresh AppBarnya
        }
      }
    }
  }

  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Foto Profil', style: GoogleFonts.inter(color: AppColors.textWhite, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 4),
          Text('Pilih aksi untuk foto profilmu', style: GoogleFonts.inter(color: AppColors.textSlate500, fontSize: 12)),
          const SizedBox(height: 20),
          _sheetOption(
            icon: Icons.photo_camera_outlined, color: AppColors.indigo,
            label: 'Ganti Foto Profil', subtitle: 'Pilih gambar dari perangkat',
            onTap: () { Navigator.pop(ctx); _pickProfileImage(); },
          ),
          if (_profileImageUrl != null) ...[
            const SizedBox(height: 12),
            _sheetOption(
              icon: Icons.delete_outline, color: AppColors.rose,
              label: 'Hapus Foto Profil', subtitle: 'Kembali ke avatar default',
              onTap: () { Navigator.pop(ctx); _removeProfileImage(); },
            ),
          ],
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _logout() async {
    final ok = await _confirm('Logout', 'Yakin ingin keluar dari akun?');
    if (ok) {
      await StorageService.clearUser();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  Future<void> _deleteNote(Note note) async {
    final ok = await _confirm('Hapus Catatan', '"${note.title}" akan dihapus permanen.');
    if (ok && note.id != null) {
      await StorageService.deleteNote(note.id!);
      setState(() => _notes.removeWhere((n) => n.id == note.id));
      _toast('Catatan dihapus', false);
    }
  }

  Future<bool> _confirm(String title, String content) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.bgCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(title, style: GoogleFonts.inter(color: AppColors.textWhite, fontWeight: FontWeight.w700)),
            content: Text(content, style: GoogleFonts.inter(color: AppColors.textSlate400, fontSize: 13)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal', style: TextStyle(color: AppColors.textSlate400))),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.rose, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text('Ya', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _toast(String msg, bool success) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(success ? Icons.check_circle_outline : Icons.info_outline,
            color: success ? AppColors.emerald : AppColors.textSlate400, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13))),
      ]),
      backgroundColor: AppColors.bgCard,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }

  Widget _sheetOption({required IconData icon, required Color color, required String label, required String subtitle, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.bgPrimary, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.borderSlate800)),
        child: Row(children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: GoogleFonts.inter(color: AppColors.textWhite, fontWeight: FontWeight.w600, fontSize: 14)),
            Text(subtitle, style: GoogleFonts.inter(color: AppColors.textSlate500, fontSize: 11)),
          ]),
          const Spacer(),
          const Icon(Icons.chevron_right, color: AppColors.textSlate600, size: 18),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasProfileImage = _profileImageUrl != null && _profileImageUrl!.isNotEmpty;

    return Container(
      color: AppColors.bgPrimary,
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.indigo))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.indigo,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: AppColors.borderSlate800),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 6))],
                    ),
                    child: Column(children: [
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        GestureDetector(
                          onTap: _showAvatarOptions,
                          child: Stack(children: [
                            Container(
                              width: 76, height: 76,
                              decoration: BoxDecoration(
                                gradient: hasProfileImage ? null : const LinearGradient(
                                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                                  colors: [Color(0xFF6366F1), Color(0xFFA855F7), Color(0xFF0EA5E9)],
                                ),
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [BoxShadow(color: AppColors.indigo.withOpacity(0.3), blurRadius: 14, offset: const Offset(0, 4))],
                              ),
                              child: hasProfileImage
                                  ? ClipRRect(borderRadius: BorderRadius.circular(22), child: Image.network(_profileImageUrl!, fit: BoxFit.cover))
                                  : Center(child: Text(_avatarLetter, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 30))),
                            ),
                            Positioned(
                              bottom: 0, right: 0,
                              child: Container(
                                width: 22, height: 22,
                                decoration: BoxDecoration(color: AppColors.indigo, borderRadius: BorderRadius.circular(7), border: Border.all(color: AppColors.bgCard, width: 2)),
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 11),
                              ),
                            ),
                          ]),
                        ),
                        const SizedBox(width: 16),

                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: AppColors.indigo.withOpacity(0.1), borderRadius: BorderRadius.circular(7), border: Border.all(color: AppColors.indigo.withOpacity(0.2))),
                              child: Text('PROFIL PENGGUNA', style: GoogleFonts.inter(color: AppColors.indigo, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                            ),
                            const SizedBox(height: 7),
                            Text(widget.user.username, style: GoogleFonts.inter(color: AppColors.textWhite, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.5)),
                            if (widget.user.email.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Row(children: [
                                const Icon(Icons.mail_outline, color: AppColors.textSlate500, size: 12),
                                const SizedBox(width: 5),
                                Expanded(child: Text(widget.user.email, style: GoogleFonts.inter(color: AppColors.textSlate400, fontSize: 11, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                              ]),
                            ],
                          ]),
                        ),

                        GestureDetector(
                          onTap: _logout,
                          child: Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: AppColors.rose.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.rose.withOpacity(0.25)),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.logout_rounded, color: AppColors.rose, size: 16),
                              const SizedBox(width: 5),
                              Text('Logout', style: GoogleFonts.inter(color: AppColors.rose, fontSize: 11, fontWeight: FontWeight.w700)),
                            ]),
                          ),
                        ),
                      ]),

                      const SizedBox(height: 18),
                      Container(height: 1, color: AppColors.borderSlate800.withOpacity(0.6)),
                      const SizedBox(height: 18),

                      Row(children: [
                        _statCard(label: 'Total Catatan', value: _notes.length.toString(), color: AppColors.indigo),
                        const SizedBox(width: 12),
                        _statCard(label: 'Tersimpan', value: _notes.where((n) => n.isBookmarked).length.toString(), color: AppColors.amber),
                      ]),
                    ]),
                  ),

                  const SizedBox(height: 20),

                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderSlate800),
                    ),
                    child: Row(children: [
                      _tabBtn(0, Icons.notes_rounded, 'Catatan Saya'),
                      _tabBtn(1, Icons.drafts_outlined, 'Draft'),
                    ]),
                  ),

                  const SizedBox(height: 16),

                  if (_activeTab == 0) _notesGrid() else _draftGrid(),
                ]),
              ),
            ),
    );
  }

  Widget _tabBtn(int idx, IconData icon, String label) {
    final isActive = _activeTab == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = idx),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isActive ? AppColors.indigo : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: isActive ? Colors.white : AppColors.textSlate500, size: 15),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.inter(color: isActive ? Colors.white : AppColors.textSlate500, fontSize: 12, fontWeight: isActive ? FontWeight.w700 : FontWeight.w500)),
          ]),
        ),
      ),
    );
  }

  Widget _notesGrid() {
    final published = _notes.where((n) => !n.isDraft).toList();
    if (published.isEmpty) return _emptyState('Belum ada catatan', 'Catatan yang kamu publish akan muncul di sini.', Icons.note_alt_outlined);
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.78),
      itemCount: published.length,
      itemBuilder: (ctx, i) => _NoteCard(
        note: published[i],
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => NoteDetailScreen(note: published[i], allNotes: _notes, onUpdated: _loadData)));
          _loadData();
        },
        onDelete: () => _deleteNote(published[i]),
      ),
    );
  }

  Widget _draftGrid() {
    final drafts = _notes.where((n) => n.isDraft).toList();
    if (drafts.isEmpty) return _emptyState(
      'Tidak ada draft',
      'Gunakan tombol "Simpan Draft" saat upload\nuntuk menyimpan catatan yang belum selesai.',
      Icons.drafts_outlined,
    );
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.78),
      itemCount: drafts.length,
      itemBuilder: (ctx, i) => _NoteCard(
        note: drafts[i],
        isDraft: true,
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => NoteDetailScreen(note: drafts[i], allNotes: _notes, onUpdated: _loadData)));
          _loadData();
        },
        onDelete: () => _deleteNote(drafts[i]),
        onPublish: () => _publishDraft(drafts[i]),
      ),
    );
  }

  Future<void> _publishDraft(Note note) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Publish Catatan', style: GoogleFonts.inter(color: AppColors.textWhite, fontWeight: FontWeight.w700)),
        content: Text('"${note.title}" akan dipindah dari Draft dan tampil di Home.', style: GoogleFonts.inter(color: AppColors.textSlate400, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal', style: TextStyle(color: AppColors.textSlate400))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.indigo, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text('Publish', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok == true) {
      note.isDraft = false;
      await StorageService.saveNote(note);
      _loadData();
      _toast('Catatan berhasil dipublish ke Home! 🚀', true);
    }
  }

  Widget _emptyState(String title, String subtitle, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.borderSlate800)),
            child: Icon(icon, color: AppColors.textSlate500, size: 28),
          ),
          const SizedBox(height: 14),
          Text(title, style: GoogleFonts.inter(color: AppColors.textSlate200, fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 6),
          Text(subtitle, textAlign: TextAlign.center, style: GoogleFonts.inter(color: AppColors.textSlate600, fontSize: 12, height: 1.5)),
        ]),
      ),
    );
  }

  Widget _statCard({required String label, required String value, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(color: AppColors.bgPrimary.withOpacity(0.7), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.borderSlate800.withOpacity(0.8))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label.toUpperCase(), style: GoogleFonts.inter(color: AppColors.textSlate500, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
          const SizedBox(height: 5),
          Text(value, style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w900, fontSize: 26)),
        ]),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final Note note;
  final bool isDraft;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onPublish;

  const _NoteCard({
    required this.note,
    this.isDraft = false,
    required this.onTap,
    required this.onDelete,
    this.onPublish,
  });

  @override
  Widget build(BuildContext context) {
    final tagColors = {
      'database': AppColors.sky, 'coding': AppColors.emerald,
      'algorithm': AppColors.indigo, 'web': AppColors.rose,
      'network': AppColors.amber,
    };
    final tagColor = tagColors[note.tags.toLowerCase()] ?? AppColors.textSlate500;
    final hasImage = note.imageUrl != null && note.imageUrl!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isDraft ? AppColors.amber.withOpacity(0.35) : AppColors.borderSlate800),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (hasImage)
            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18)),
              child: Image.network(note.imageUrl!, width: double.infinity, height: 65, fit: BoxFit.cover),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(11),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(color: tagColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: tagColor.withOpacity(0.2))),
                    child: Text(note.tags.isNotEmpty ? note.tags : 'umum', style: GoogleFonts.inter(color: tagColor, fontSize: 8, fontWeight: FontWeight.w700)),
                  ),
                  const Spacer(),
                  if (!isDraft && note.isBookmarked) const Icon(Icons.bookmark_rounded, color: AppColors.amber, size: 13),
                  GestureDetector(
                    onTap: onDelete,
                    child: Padding(padding: const EdgeInsets.only(left: 4), child: Icon(Icons.delete_outline, color: AppColors.rose.withOpacity(0.7), size: 14)),
                  ),
                ]),
                const SizedBox(height: 6),

                Text(note.title,
                    style: GoogleFonts.inter(color: AppColors.textWhite, fontWeight: FontWeight.w700, fontSize: 12, height: 1.3),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),

                if (isDraft) ...[
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.amber.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                      child: Text('DRAFT', style: GoogleFonts.inter(color: AppColors.amber, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  if (note.description.isNotEmpty)
                    Expanded(child: Text(note.description,
                        style: GoogleFonts.inter(color: AppColors.textSlate500, fontSize: 10, height: 1.4),
                        maxLines: 2, overflow: TextOverflow.ellipsis))
                  else
                    Expanded(child: Text('Belum ada deskripsi...',
                        style: GoogleFonts.inter(color: AppColors.textSlate600, fontSize: 10, fontStyle: FontStyle.italic))),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: onPublish,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.indigo.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.indigo.withOpacity(0.3)),
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.cloud_upload_outlined, color: AppColors.indigo, size: 12),
                        const SizedBox(width: 4),
                        Text('Publish', style: GoogleFonts.inter(color: AppColors.indigo, fontSize: 10, fontWeight: FontWeight.w800)),
                      ]),
                    ),
                  ),
                ] else ...[
                  Expanded(child: Text(note.description,
                      style: GoogleFonts.inter(color: AppColors.textSlate500, fontSize: 10, height: 1.5),
                      maxLines: 3, overflow: TextOverflow.ellipsis)),
                  const SizedBox(height: 5),
                  Text(_fmtDate(note.createdAt), style: GoogleFonts.inter(color: AppColors.textSlate600, fontSize: 9)),
                ],
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  String _fmtDate(DateTime dt) {
    final m = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
    return '${dt.day} ${m[dt.month - 1]} ${dt.year}';
  }
}