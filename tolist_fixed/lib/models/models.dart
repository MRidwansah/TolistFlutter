class User {
  final String id; // Ubah ke String
  final String username;
  final String email;
  final String? avatarUrl;

  User({required this.id, required this.username, this.email = '', this.avatarUrl});
}

class Note {
  String? id; // String dan nullable karena di-generate Supabase
  final String title;
  final String description;
  final String tags;
  final String filePath;
  final DateTime createdAt;
  bool isBookmarked;
  bool isDraft;
  String? imageUrl; // Ganti imageData base64 ke URL gambar dari Supabase Storage

  Note({
    this.id,
    required this.title,
    required this.description,
    required this.tags,
    required this.filePath,
    required this.createdAt,
    this.isBookmarked = false,
    this.isDraft = false,
    this.imageUrl,
  });

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id'],
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        tags: json['tags'] ?? 'general',
        filePath: json['file_path'] ?? '',
        createdAt: DateTime.tryParse(json['created_at']) ?? DateTime.now(),
        isBookmarked: json['is_bookmarked'] ?? false,
        isDraft: json['is_draft'] ?? false,
        imageUrl: json['image_url'],
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'tags': tags,
        'file_path': filePath,
        'is_bookmarked': isBookmarked,
        'is_draft': isDraft,
        'image_url': imageUrl,
      };
}

class Todo {
  String? id; // Ubah ke String
  final String task;
  String status;

  Todo({this.id, required this.task, required this.status});

  factory Todo.fromJson(Map<String, dynamic> json) => Todo(
        id: json['id'],
        task: json['task'] ?? '',
        status: json['status'] ?? 'todo',
      );

  Map<String, dynamic> toJson() => {
        'task': task,
        'status': status,
      };
}