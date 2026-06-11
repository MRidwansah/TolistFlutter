import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../theme.dart';
import '../models/models.dart';
import '../services/storage_service.dart';

class UploadScreen extends StatefulWidget {
  final User user;
  const UploadScreen({super.key, required this.user});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  final _tagsCtrl  = TextEditingController();
  bool _saving = false;
  String? _savedAs;

  PlatformFile? _pickedFile;

  final _tagSuggestions = ['database', 'coding', 'algorithm', 'network', 'web', 'software', 'data'];

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() { _pickedFile = result.files.first; });
      }
    } catch (e) {
      _toast('Gagal membuka file: $e', false);
    }
  }

  void _removeFile() => setState(() { _pickedFile = null; });

  Future<void> _submit({required bool asDraft}) async {
    if (_titleCtrl.text.trim().isEmpty) {
      _toast('Judul tidak boleh kosong!', false);
      return;
    }
    setState(() { _saving = true; _savedAs = null; });

    String? imageUrl;

    // Upload gambar ke Supabase Storage 
    if (_pickedFile != null && ['jpg', 'jpeg', 'png'].contains(_pickedFile!.extension?.toLowerCase())) {
      if (_pickedFile!.path != null) {
        final file = File(_pickedFile!.path!);
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${_pickedFile!.name}';
        imageUrl = await StorageService.uploadNoteImage(file, fileName);
      }
    }

    final note = Note(
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      tags: _tagsCtrl.text.trim().isEmpty ? 'general' : _tagsCtrl.text.trim(),
      filePath: _pickedFile?.name ?? '',
      createdAt: DateTime.now(),
      isDraft: asDraft,
      imageUrl: imageUrl, // Menggunakan URL dari Supabase
    );

    await StorageService.saveNote(note);

    _titleCtrl.clear();
    _descCtrl.clear();
    _tagsCtrl.clear();
    setState(() {
      _saving = false;
      _savedAs = asDraft ? 'draft' : 'publish';
      _pickedFile = null;
    });

    _toast(
      asDraft ? 'Tersimpan di Draft! Bisa diedit & publish nanti.' : 'Catatan berhasil dipublish!',
      true,
    );

    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _savedAs = null);
  }

  void _toast(String msg, bool success) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(success ? Icons.check_circle_outline : Icons.error_outline,
            color: success ? AppColors.emerald : AppColors.rose, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13))),
      ]),
      backgroundColor: AppColors.bgCard,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ));
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _fileIcon(String? ext) {
    switch (ext?.toLowerCase()) {
      case 'pdf': return Icons.picture_as_pdf_outlined;
      case 'jpg': case 'jpeg': case 'png': return Icons.image_outlined;
      default: return Icons.insert_drive_file_outlined;
    }
  }

  Color _fileColor(String? ext) {
    switch (ext?.toLowerCase()) {
      case 'pdf': return AppColors.rose;
      case 'jpg': case 'jpeg': case 'png': return AppColors.sky;
      default: return AppColors.indigo;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose(); _descCtrl.dispose(); _tagsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 80),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        Text('Tambah Catatan 📝',
            style: GoogleFonts.inter(color: AppColors.textWhite, fontWeight: FontWeight.w700, fontSize: 18)),
        const SizedBox(height: 4),
        Text('Simpan ide dan materi kuliahmu di sini.',
            style: GoogleFonts.inter(color: AppColors.textSlate500, fontSize: 12)),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.borderSlate800),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            _label('Judul Catatan'),
            const SizedBox(height: 8),
            TextField(
              controller: _titleCtrl,
              style: GoogleFonts.inter(color: AppColors.textSlate200, fontSize: 14),
              decoration: const InputDecoration(hintText: 'Masukkan judul catatan...'),
            ),
            const SizedBox(height: 18),

            _label('Deskripsi'),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              style: GoogleFonts.inter(color: AppColors.textSlate200, fontSize: 14),
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Tulis deskripsi atau isi materi... (bisa diisi nanti jika draft)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 18),

            _label('Tags'),
            const SizedBox(height: 8),
            TextField(
              controller: _tagsCtrl,
              style: GoogleFonts.inter(color: AppColors.textSlate200, fontSize: 14),
              decoration: const InputDecoration(hintText: 'Contoh: database, coding, network'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _tagSuggestions.map((tag) => GestureDetector(
                onTap: () => setState(() => _tagsCtrl.text = tag),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _tagsCtrl.text == tag
                        ? AppColors.indigo.withOpacity(0.2) : AppColors.bgPrimary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _tagsCtrl.text == tag
                          ? AppColors.indigo.withOpacity(0.5) : AppColors.borderSlate800,
                    ),
                  ),
                  child: Text(tag, style: GoogleFonts.inter(
                    color: _tagsCtrl.text == tag ? AppColors.indigo : AppColors.textSlate500,
                    fontSize: 11, fontWeight: FontWeight.w600,
                  )),
                ),
              )).toList(),
            ),
            const SizedBox(height: 20),

            _label('File / Gambar Lampiran'),
            const SizedBox(height: 10),

            if (_pickedFile == null)
              GestureDetector(
                onTap: _pickFile,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  decoration: BoxDecoration(
                    color: AppColors.bgPrimary.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSlate700),
                  ),
                  child: Column(children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.indigo.withOpacity(0.12), shape: BoxShape.circle),
                      child: const Icon(Icons.upload_file_outlined, color: AppColors.indigo, size: 24),
                    ),
                    const SizedBox(height: 12),
                    Text('Tap untuk pilih file atau gambar',
                        style: GoogleFonts.inter(color: AppColors.textSlate200, fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('PDF, JPG, PNG, DOC (maks 5MB)',
                        style: GoogleFonts.inter(color: AppColors.textSlate600, fontSize: 11)),
                  ]),
                ),
              )
            else
              Column(children: [
                if (['jpg', 'jpeg', 'png'].contains(_pickedFile!.extension?.toLowerCase()) && _pickedFile!.path != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(File(_pickedFile!.path!),
                        width: double.infinity, height: 180, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 10),
                ],
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.bgPrimary,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _fileColor(_pickedFile!.extension).withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: _fileColor(_pickedFile!.extension).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(_fileIcon(_pickedFile!.extension),
                          color: _fileColor(_pickedFile!.extension), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_pickedFile!.name,
                          style: GoogleFonts.inter(color: AppColors.textSlate200, fontSize: 13, fontWeight: FontWeight.w600),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(_pickedFile!.size > 0 ? _formatSize(_pickedFile!.size) : 'File dipilih',
                          style: GoogleFonts.inter(color: AppColors.textSlate500, fontSize: 11)),
                    ])),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _removeFile,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.rose.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.close, color: AppColors.rose, size: 16),
                      ),
                    ),
                  ]),
                ),
              ]),

            const SizedBox(height: 28),

            if (_savedAs != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: (_savedAs == 'draft' ? AppColors.amber : AppColors.emerald).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: (_savedAs == 'draft' ? AppColors.amber : AppColors.emerald).withOpacity(0.3)),
                ),
                child: Row(children: [
                  Icon(
                    _savedAs == 'draft' ? Icons.drafts_outlined : Icons.check_circle_outline,
                    color: _savedAs == 'draft' ? AppColors.amber : AppColors.emerald,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(
                    _savedAs == 'draft'
                        ? 'Tersimpan di Draft — bisa diedit & publish kapan saja dari tab Draft di Profil.'
                        : 'Catatan berhasil dipublish ke Home!',
                    style: GoogleFonts.inter(
                      color: _savedAs == 'draft' ? AppColors.amber : AppColors.emerald,
                      fontSize: 12, fontWeight: FontWeight.w600, height: 1.4,
                    ),
                  )),
                ]),
              ),

            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => _submit(asDraft: true),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: _savedAs == 'draft' ? AppColors.amber : AppColors.amber.withOpacity(0.5),
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    backgroundColor: AppColors.amber.withOpacity(0.05),
                  ),
                  child: _saving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: AppColors.amber, strokeWidth: 2))
                      : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(_savedAs == 'draft' ? Icons.check_rounded : Icons.drafts_outlined, color: AppColors.amber, size: 16),
                          const SizedBox(width: 6),
                          Text(_savedAs == 'draft' ? 'Tersimpan!' : 'Simpan Draft', style: GoogleFonts.inter(color: AppColors.amber, fontWeight: FontWeight.w700, fontSize: 13)),
                        ]),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: ElevatedButton(
                  onPressed: _saving ? null : () => _submit(asDraft: false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _savedAs == 'publish' ? AppColors.emerald : AppColors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(_savedAs == 'publish' ? Icons.check_rounded : Icons.cloud_upload_outlined, size: 16),
                          const SizedBox(width: 6),
                          Text(_savedAs == 'publish' ? 'Terpublish!' : 'Publish', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13)),
                        ]),
                ),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _label(String text) => Text(
    text.toUpperCase(),
    style: GoogleFonts.inter(
        color: AppColors.textSlate500, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5),
  );
}