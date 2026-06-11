import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../models/models.dart';
import '../services/storage_service.dart';

class NoteDetailScreen extends StatefulWidget {
  final Note note;
  final List<Note> allNotes;
  final VoidCallback? onUpdated;
  const NoteDetailScreen({super.key, required this.note, required this.allNotes, this.onUpdated});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late Note _note;

  @override
  void initState() {
    super.initState();
    _note = widget.note;
  }

  Color _tagColor(String tags) {
    final t = tags.toLowerCase();
    if (t.contains('bisnis') || t.contains('ide')) return AppColors.rose;
    if (t.contains('pribadi') || t.contains('wifi')) return AppColors.emerald;
    return AppColors.sky;
  }

  Future<void> _deleteNote() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Hapus Catatan', style: GoogleFonts.inter(color: AppColors.textWhite, fontWeight: FontWeight.w700)),
        content: Text('Catatan ini akan dihapus permanen.', style: GoogleFonts.inter(color: AppColors.textSlate400, fontSize: 13)),
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
    if (confirm == true && _note.id != null) {
      await StorageService.deleteNote(_note.id!);
      widget.onUpdated?.call();
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _showEditDialog() async {
    final titleCtrl = TextEditingController(text: _note.title);
    final descCtrl = TextEditingController(text: _note.description);
    final tagsCtrl = TextEditingController(text: _note.tags);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Edit Catatan', style: GoogleFonts.inter(color: AppColors.textWhite, fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: titleCtrl,
              style: GoogleFonts.inter(color: AppColors.textSlate200, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Judul',
                labelStyle: GoogleFonts.inter(color: AppColors.textSlate500, fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              style: GoogleFonts.inter(color: AppColors.textSlate200, fontSize: 14),
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Deskripsi',
                labelStyle: GoogleFonts.inter(color: AppColors.textSlate500, fontSize: 12),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: tagsCtrl,
              style: GoogleFonts.inter(color: AppColors.textSlate200, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Tags',
                labelStyle: GoogleFonts.inter(color: AppColors.textSlate500, fontSize: 12),
              ),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: AppColors.textSlate400))),
          ElevatedButton(
            onPressed: () async {
              final updated = Note(
                id: _note.id,
                title: titleCtrl.text.trim().isEmpty ? _note.title : titleCtrl.text.trim(),
                description: descCtrl.text.trim(),
                tags: tagsCtrl.text.trim().isEmpty ? _note.tags : tagsCtrl.text.trim(),
                filePath: _note.filePath,
                createdAt: _note.createdAt,
                isBookmarked: _note.isBookmarked,
                imageUrl: _note.imageUrl,
              );
              await StorageService.saveNote(updated);
              if (mounted) setState(() => _note = updated);
              widget.onUpdated?.call();
              if (mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.indigo, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text('Simpan', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tagColor = _tagColor(_note.tags);
    final hasImage = _note.imageUrl != null && _note.imageUrl!.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Stack(
        children: [
          Positioned(
            top: -60, right: -60,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(shape: BoxShape.circle, color: tagColor.withOpacity(0.08)),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.bgCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderSlate800),
                          ),
                          child: const Icon(Icons.arrow_back, color: AppColors.textSlate400, size: 18),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text('Detail Catatan', style: GoogleFonts.inter(color: AppColors.textWhite, fontWeight: FontWeight.w700, fontSize: 16)),
                      const Spacer(),
                      GestureDetector(
                        onTap: _showEditDialog,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.bgCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderSlate800),
                          ),
                          child: const Icon(Icons.edit_outlined, color: AppColors.indigo, size: 18),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _deleteNote,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.bgCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderSlate800),
                          ),
                          child: const Icon(Icons.delete_outline, color: AppColors.rose, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.borderSlate800),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hasImage) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                _note.imageUrl!,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          Row(
                            children: [
                              Container(
                                width: 4, height: 32,
                                decoration: BoxDecoration(
                                  color: tagColor,
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [BoxShadow(color: tagColor.withOpacity(0.5), blurRadius: 10)],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _note.title,
                                  style: GoogleFonts.inter(color: AppColors.textWhite, fontWeight: FontWeight.w900, fontSize: 20),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              _badge(Icons.label_outline, _note.tags.isNotEmpty ? _note.tags : 'No Tag', AppColors.indigo),
                              const SizedBox(width: 8),
                              _badge(Icons.calendar_today_outlined, DateFormat('dd MMM yyyy').format(_note.createdAt), AppColors.textSlate500),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Divider(color: AppColors.borderSlate800),
                          const SizedBox(height: 20),
                          Text('Deskripsi', style: GoogleFonts.inter(color: AppColors.textSlate500, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                          const SizedBox(height: 10),
                          Text(
                            _note.description.isNotEmpty ? _note.description : 'Tidak ada deskripsi tambahan.',
                            style: GoogleFonts.inter(
                              color: _note.description.isNotEmpty ? AppColors.textSlate200 : AppColors.textSlate600,
                              fontSize: 15,
                              fontStyle: _note.description.isEmpty ? FontStyle.italic : FontStyle.normal,
                              height: 1.7,
                            ),
                          ),
                          if (_note.isBookmarked) ...[
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.amber.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.amber.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.bookmark_rounded, color: AppColors.amber, size: 16),
                                  const SizedBox(width: 8),
                                  Text('Tersimpan di Bookmark', style: GoogleFonts.inter(color: AppColors.amber, fontSize: 12, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ],
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
    );
  }

  Widget _badge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 6),
          Text(text, style: GoogleFonts.inter(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}