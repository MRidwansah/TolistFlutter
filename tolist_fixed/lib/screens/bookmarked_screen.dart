import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../models/models.dart';
import '../services/storage_service.dart';
import 'note_detail_screen.dart';

class BookmarkedScreen extends StatefulWidget {
  final User user;
  const BookmarkedScreen({super.key, required this.user});

  @override
  State<BookmarkedScreen> createState() => _BookmarkedScreenState();
}

class _BookmarkedScreenState extends State<BookmarkedScreen> {
  List<Note> _bookmarked = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Memanggil data langsung dari tabel keranjang bookmark
    final notes = await StorageService.getBookmarkedNotes();
    if (mounted) {
      setState(() {
        _bookmarked = notes;
        _loading = false;
      });
    }
  }

  List<Note> get _filtered {
    if (_search.trim().isEmpty) return _bookmarked;
    final q = _search.toLowerCase();
    return _bookmarked.where((n) =>
      n.title.toLowerCase().contains(q) || n.tags.toLowerCase().contains(q)
    ).toList();
  }

  Future<void> _removeBookmark(Note note) async {
    if (note.id == null) return;
    
    // Hapus dari keranjang bookmark
    await StorageService.toggleBookmark(note.id!, true); 
    
    setState(() {
      _bookmarked.removeWhere((n) => n.id == note.id);
    });
    _showToast('Bookmark dihapus');
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.bookmark_remove, color: AppColors.rose, size: 16),
            const SizedBox(width: 8),
            Text(msg, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
        backgroundColor: AppColors.bgCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Color _tagColor(String tags) {
    final t = tags.toLowerCase();
    if (t.contains('bisnis') || t.contains('ide')) return AppColors.rose;
    if (t.contains('pribadi') || t.contains('wifi')) return AppColors.emerald;
    return AppColors.sky;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.indigo));

    final filtered = _filtered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: TextField(
            onChanged: (v) => setState(() => _search = v),
            style: GoogleFonts.inter(color: AppColors.textSlate200, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Cari catatan tersimpan...',
              prefixIcon: const Icon(Icons.search, color: AppColors.textSlate500, size: 18),
              suffixText: _search.isNotEmpty ? '${filtered.length} ditemukan' : null,
              suffixStyle: GoogleFonts.inter(color: AppColors.textSlate500, fontSize: 11),
            ),
          ),
        ),

        Expanded(
          child: _bookmarked.isEmpty
              ? _emptyState(isSearch: false)
              : filtered.isEmpty
                  ? _emptyState(isSearch: true)
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.indigo,
                      child: GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.8,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final note = filtered[i];
                          return _BookmarkCard(
                            note: note,
                            tagColor: _tagColor(note.tags),
                            onRemove: () => _removeBookmark(note),
                            onTap: () async {
                               await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => NoteDetailScreen(note: note, allNotes: _bookmarked, onUpdated: _load)),
                               );
                               _load();
                            },
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _emptyState({required bool isSearch}) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: AppColors.indigo.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.indigo.withOpacity(0.2)),
              ),
              child: Icon(
                isSearch ? Icons.search_off : Icons.bookmark_outline,
                color: AppColors.indigo.withOpacity(0.6), size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isSearch ? 'Catatan tidak ditemukan' : 'Belum ada catatan yang disimpan',
              style: GoogleFonts.inter(color: AppColors.textSlate400, fontWeight: FontWeight.w600, fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}

class _BookmarkCard extends StatelessWidget {
  final Note note;
  final Color tagColor;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  const _BookmarkCard({required this.note, required this.tagColor, required this.onRemove, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgCard.withOpacity(0.85),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.borderSlate800),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4, height: 28,
                  decoration: BoxDecoration(
                    color: tagColor,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [BoxShadow(color: tagColor.withOpacity(0.4), blurRadius: 8)],
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.bgPrimary,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.borderSlate800.withOpacity(0.5)),
                    ),
                    child: const Icon(Icons.bookmark_rounded, color: AppColors.amber, size: 14),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.bgPrimary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderSlate800.withOpacity(0.5)),
                  ),
                  child: const Icon(Icons.arrow_forward, color: AppColors.textSlate600, size: 14),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              note.title,
              style: GoogleFonts.inter(color: AppColors.textWhite, fontWeight: FontWeight.w700, fontSize: 13, height: 1.3),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Text(
                note.description.isNotEmpty ? note.description : 'Tidak ada deskripsi tambahan.',
                style: GoogleFonts.inter(
                  color: note.description.isNotEmpty ? AppColors.textSlate400 : AppColors.textSlate600,
                  fontSize: 11,
                  fontStyle: note.description.isEmpty ? FontStyle.italic : FontStyle.normal,
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Divider(color: Color(0xFF1E293B), height: 16),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, color: AppColors.textSlate500, size: 10),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd MMM yy').format(note.createdAt),
                  style: GoogleFonts.inter(color: AppColors.textSlate500, fontSize: 9, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.indigo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.indigo.withOpacity(0.2)),
                  ),
                  child: Text(
                    note.tags.isNotEmpty ? note.tags : 'No Tag',
                    style: GoogleFonts.inter(color: AppColors.indigo, fontSize: 9, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}