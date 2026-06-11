import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../models/models.dart';

class StorageService {
  static final _supabase = supa.Supabase.instance.client;

  // ─── Auth & Profile ───
  static Future<User?> getUserProfile() async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) return null;

    final data = await _supabase.from('profiles').select().eq('id', authUser.id).single();
    return User(
      id: data['id'],
      username: data['username'],
      email: data['email'],
      avatarUrl: data['avatar_url'],
    );
  }

  static Future<void> clearUser() async {
    await _supabase.auth.signOut();
  }

  // ─── Bookmarks (Sistem Baru) ───
  static Future<List<String>> _getMyBookmarkedNoteIds() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];
    
    final response = await _supabase.from('bookmarks').select('note_id').eq('user_id', userId);
    return response.map((e) => e['note_id'] as String).toList();
  }

  static Future<void> toggleBookmark(String noteId, bool isCurrentlyBookmarked) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    if (isCurrentlyBookmarked) {
      // Jika sudah di-bookmark, maka hapus dari keranjang
      await _supabase.from('bookmarks').delete().match({'user_id': userId, 'note_id': noteId});
    } else {
      // Jika belum, masukkan ke keranjang
      await _supabase.from('bookmarks').insert({'user_id': userId, 'note_id': noteId});
    }
  }

  static Future<List<Note>> getBookmarkedNotes() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];
    
    // Tarik data catatan yang ada di dalam keranjang bookmark user ini
    final response = await _supabase
        .from('bookmarks')
        .select('notes(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    
    return response.map((e) {
      final noteData = e['notes'] as Map<String, dynamic>;
      final note = Note.fromJson(noteData);
      note.isBookmarked = true; // Set UI menjadi true
      return note;
    }).toList();
  }

  // ─── Notes ───
  static Future<List<Note>> getAllNotes() async {
    final response = await _supabase.from('notes').select().order('created_at', ascending: false);
    final notes = response.map((e) => Note.fromJson(e)).toList();
    
    // Cek mana saja catatan yang sudah di-bookmark oleh user yang sedang login
    final bookmarkedIds = await _getMyBookmarkedNoteIds();
    for (var n in notes) {
      if (n.id != null) n.isBookmarked = bookmarkedIds.contains(n.id);
    }
    return notes;
  }

  static Future<List<Note>> getNotes() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase.from('notes').select().eq('user_id', userId).order('created_at', ascending: false);
    final notes = response.map((e) => Note.fromJson(e)).toList();
    
    final bookmarkedIds = await _getMyBookmarkedNoteIds();
    for (var n in notes) {
      if (n.id != null) n.isBookmarked = bookmarkedIds.contains(n.id);
    }
    return notes;
  }

  static Future<void> saveNote(Note note) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final noteData = note.toJson();
    noteData['user_id'] = userId;

    if (note.id != null) {
      await _supabase.from('notes').update(noteData).eq('id', note.id!);
    } else {
      await _supabase.from('notes').insert(noteData);
    }
  }

  static Future<void> deleteNote(String noteId) async {
    await _supabase.from('notes').delete().eq('id', noteId);
  }

  // ─── Todos ───
  static Future<List<Todo>> getTodos() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase.from('todos').select().eq('user_id', userId).order('created_at');
    return response.map((e) => Todo.fromJson(e)).toList();
  }

  static Future<void> saveTodo(Todo todo) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final todoData = todo.toJson();
    todoData['user_id'] = userId;

    if (todo.id != null) {
      await _supabase.from('todos').update(todoData).eq('id', todo.id!);
    } else {
      await _supabase.from('todos').insert(todoData);
    }
  }

  static Future<void> deleteTodo(String todoId) async {
    await _supabase.from('todos').delete().eq('id', todoId);
  }

  // ─── Storage (Images) ───
  static Future<String?> uploadNoteImage(File file, String fileName) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      final path = '$userId/$fileName';
      
      await _supabase.storage.from('note-images').upload(path, file);
      return _supabase.storage.from('note-images').getPublicUrl(path);
    } catch (e) {
      return null;
    }
  }
}