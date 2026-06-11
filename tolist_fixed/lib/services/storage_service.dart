import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class StorageService {
  static const _keyUser = 'user';
  static const _keyNotes = 'notes';
  static const _keyTodos = 'todos';
  static const _keyProfileImage = 'profile_image';
  static const _keyRegisteredUsers = 'registered_users';

  // ─── Auth ───
  static Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUser, jsonEncode(user.toJson()));
  }

  static Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyUser);
    if (raw == null) return null;
    return User.fromJson(jsonDecode(raw));
  }

  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUser);
  }

  // ─── Registered accounts (untuk login & lupa password) ───
  static Future<void> saveRegisteredUser(String username, String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyRegisteredUsers);
    final List<Map<String, dynamic>> users =
        raw != null ? List<Map<String, dynamic>>.from(jsonDecode(raw)) : [];
    // Update kalau sudah ada
    users.removeWhere((u) => u['username'] == username || u['email'] == email);
    users.add({'username': username, 'email': email, 'password': password, 'id': DateTime.now().millisecondsSinceEpoch});
    await prefs.setString(_keyRegisteredUsers, jsonEncode(users));
  }

  static Future<List<Map<String, dynamic>>> getRegisteredUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyRegisteredUsers);
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(raw));
  }

  static Future<bool> updatePassword(String email, String newPassword) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyRegisteredUsers);
    if (raw == null) return false;
    final users = List<Map<String, dynamic>>.from(jsonDecode(raw));
    final idx = users.indexWhere((u) => (u['email'] as String).toLowerCase() == email.toLowerCase());
    if (idx == -1) return false;
    users[idx] = {...users[idx], 'password': newPassword};
    await prefs.setString(_keyRegisteredUsers, jsonEncode(users));
    return true;
  }

  // ─── Profile Image ───
  static Future<void> saveProfileImage(String base64Image) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProfileImage, base64Image);
  }

  static Future<String?> getProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyProfileImage);
  }

  static Future<void> clearProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyProfileImage);
  }

  // ─── Notes ───
  static Future<List<Note>> getNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyNotes);
    if (raw == null) return _demoNotes();
    final list = jsonDecode(raw) as List;
    return list.map((e) => Note.fromJson(e)).toList();
  }

  static Future<void> saveNotes(List<Note> notes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyNotes, jsonEncode(notes.map((n) => n.toJson()).toList()));
  }

  // ─── Todos ───
  static Future<List<Todo>> getTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyTodos);
    if (raw == null) return _demoTodos();
    final list = jsonDecode(raw) as List;
    return list.map((e) => Todo.fromJson(e)).toList();
  }

  static Future<void> saveTodos(List<Todo> todos) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTodos, jsonEncode(todos.map((t) => t.toJson()).toList()));
  }

  // ─── Demo data ───
  static List<Note> _demoNotes() => [
    Note(id: 1, title: 'Pengenalan Basis Data Relasional', description: 'Membahas konsep dasar RDBMS, Tabel, Primary Key, dan Foreign Key.', tags: 'database', filePath: '', createdAt: DateTime(2026, 4, 1), isBookmarked: true),
    Note(id: 2, title: 'Struktur Data: Linked List', description: 'Penjelasan mengenai Single Linked List dan Double Linked List.', tags: 'coding', filePath: '', createdAt: DateTime(2026, 4, 2)),
    Note(id: 3, title: 'Algoritma Sorting', description: 'Mempelajari Bubble Sort, Quick Sort, dan Merge Sort beserta kompleksitas waktunya.', tags: 'algorithm', filePath: '', createdAt: DateTime(2026, 4, 3), isBookmarked: true),
    Note(id: 4, title: 'Query SQL Lanjutan', description: 'Latihan menggunakan JOIN, GROUP BY, dan Subqueries pada MySQL.', tags: 'database', filePath: '', createdAt: DateTime(2026, 4, 4)),
    Note(id: 5, title: 'Pemrograman Web dengan MVC', description: 'Konsep dasar Model-View-Controller dan pemisahan logika aplikasi.', tags: 'web', filePath: '', createdAt: DateTime(2026, 4, 5)),
    Note(id: 6, title: 'Dasar-Dasar Jaringan Komputer', description: 'Memahami Model OSI 7 Layer dan cara kerja protokol TCP/IP.', tags: 'network', filePath: '', createdAt: DateTime(2026, 4, 6)),
  ];

  static List<Todo> _demoTodos() => [
    Todo(id: 1, task: 'Belajar Flutter dasar', status: 'todo'),
    Todo(id: 2, task: 'Mengerjakan tugas basis data', status: 'todo'),
    Todo(id: 3, task: 'Review materi algoritma sorting', status: 'in_progress'),
    Todo(id: 4, task: 'Presentasi proyek MVC', status: 'in_progress'),
    Todo(id: 5, task: 'Ujian Kalkulus', status: 'done'),
    Todo(id: 6, task: 'Instalasi XAMPP', status: 'done'),
  ];
}
