import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../models/models.dart';
import '../services/storage_service.dart';
import 'note_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final User user;
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Note> _notes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await StorageService.getAllNotes();
    if (mounted) {
      setState(() { 
        _notes = all.where((n) => !n.isDraft).toList(); 
        _loading = false; 
      });
    }
  }

  Future<void> _toggleBookmark(Note note) async {
    if (note.id == null) return;
    final isCurrentlyBookmarked = note.isBookmarked;
    
    // Ubah status UI sementara biar cepat
    setState(() => note.isBookmarked = !isCurrentlyBookmarked);
    
    // Panggil fungsi sistem keranjang bookmark baru
    await StorageService.toggleBookmark(note.id!, isCurrentlyBookmarked);
    
    _showToast(!isCurrentlyBookmarked ? 'Ditambahkan ke bookmark' : 'Dihapus dari bookmark', !isCurrentlyBookmarked);
  }

  void _showToast(String msg, bool success) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(success ? Icons.bookmark : Icons.bookmark_remove,
            color: success ? AppColors.amber : AppColors.textSlate400, size: 16),
        const SizedBox(width: 8),
        Text(msg, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
      ]),
      backgroundColor: AppColors.bgCard,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }

  Color _tagColor(String tags) {
    final t = tags.toLowerCase();
    if (t.contains('bisnis') || t.contains('ide')) return AppColors.rose;
    if (t.contains('pribadi') || t.contains('wifi')) return AppColors.emerald;
    return AppColors.sky;
  }

  Future<void> _deleteNote(Note note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Hapus Catatan', style: GoogleFonts.inter(color: AppColors.textWhite, fontWeight: FontWeight.w700)),
        content: Text('Catatan "${note.title}" akan dihapus permanen.', style: GoogleFonts.inter(color: AppColors.textSlate400, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal', style: TextStyle(color: AppColors.textSlate400))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.rose, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text('Hapus', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm == true && note.id != null) {
      try {
        await StorageService.deleteNote(note.id!);
        setState(() => _notes.removeWhere((n) => n.id == note.id));
        _showToast('Catatan dihapus', false);
      } catch (e) {
        _showToast('Gagal: Anda hanya bisa menghapus catatan Anda sendiri!', false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.indigo));
    if (_notes.isEmpty) return _emptyState();

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.indigo,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 80),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          mainAxisExtent: 230,
        ),
        itemCount: _notes.length,
        itemBuilder: (_, i) => _NoteCard(
          note: _notes[i],
          tagColor: _tagColor(_notes[i].tags),
          onBookmark: () => _toggleBookmark(_notes[i]),
          onDelete: () => _deleteNote(_notes[i]),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => NoteDetailScreen(note: _notes[i], allNotes: _notes, onUpdated: () => _load())),
            );
            _load();
          },
        ),
      ),
    );
  }

  Widget _emptyState() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 72, height: 72,
        decoration: BoxDecoration(
          color: AppColors.indigo.withOpacity(0.1), shape: BoxShape.circle,
          border: Border.all(color: AppColors.indigo.withOpacity(0.2)),
        ),
        child: const Icon(Icons.note_alt_outlined, color: AppColors.indigo, size: 32),
      ),
      const SizedBox(height: 16),
      Text('Belum ada catatan',
          style: GoogleFonts.inter(color: AppColors.textSlate400, fontWeight: FontWeight.w600, fontSize: 16)),
    ]),
  );
}

class _NoteCard extends StatelessWidget {
  final Note note;
  final Color tagColor;
  final VoidCallback onBookmark;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _NoteCard({
    required this.note, required this.tagColor,
    required this.onBookmark, required this.onDelete, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = note.imageUrl != null && note.imageUrl!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgCard.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderSlate800),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImage)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: Image.network(
                  note.imageUrl!,
                  width: double.infinity,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(
                    height: 90,
                    child: Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                  ),
                ),
              ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 3, height: 20,
                          decoration: BoxDecoration(
                            color: tagColor, borderRadius: BorderRadius.circular(4),
                            boxShadow: [BoxShadow(color: tagColor.withOpacity(0.4), blurRadius: 6)],
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: onBookmark,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.bgPrimary, borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.borderSlate800.withOpacity(0.5)),
                            ),
                            child: Icon(
                              note.isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_outline,
                              color: note.isBookmarked ? AppColors.amber : AppColors.textSlate500,
                              size: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: onDelete,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.bgPrimary, borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.borderSlate800.withOpacity(0.5)),
                            ),
                            child: const Icon(Icons.delete_outline, color: AppColors.rose, size: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      note.title,
                      style: GoogleFonts.inter(
                        color: AppColors.textWhite, fontWeight: FontWeight.w700,
                        fontSize: 12, height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        note.description.isNotEmpty ? note.description : 'Tidak ada deskripsi.',
                        style: GoogleFonts.inter(
                          color: note.description.isNotEmpty ? AppColors.textSlate400 : AppColors.textSlate600,
                          fontSize: 10,
                          fontStyle: note.description.isEmpty ? FontStyle.italic : FontStyle.normal,
                          height: 1.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Divider(color: Color(0xFF1E293B), height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined, color: AppColors.textSlate500, size: 9),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  DateFormat('dd MMM yy').format(note.createdAt),
                                  style: GoogleFonts.inter(color: AppColors.textSlate500, fontSize: 9, fontWeight: FontWeight.w700),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.indigo.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.indigo.withOpacity(0.2)),
                          ),
                          child: Text(
                            note.tags.isNotEmpty ? note.tags : 'No Tag',
                            style: GoogleFonts.inter(color: AppColors.indigo, fontSize: 8, fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}