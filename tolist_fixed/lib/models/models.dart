class User {
  final int id;
  final String username;
  final String email;

  User({required this.id, required this.username, this.email = ''});

  Map<String, dynamic> toJson() => {
        'user_id': id,
        'username': username,
        'email': email,
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['user_id'],
        username: json['username'],
        email: json['email'] ?? '',
      );
}

class Note {
  final int id;
  final String title;
  final String description;
  final String tags;
  final String filePath;
  final DateTime createdAt;
  bool isBookmarked;
  bool isDraft; // true = tersimpan di draft, belum dipublish ke Home
  String? imageData;

  Note({
    required this.id,
    required this.title,
    required this.description,
    required this.tags,
    required this.filePath,
    required this.createdAt,
    this.isBookmarked = false,
    this.isDraft = false,
    this.imageData,
  });

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id'],
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        tags: json['tags'] ?? '',
        filePath: json['file_path'] ?? '',
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
            : DateTime.now(),
        isBookmarked: (json['is_bookmarked'] ?? 0) > 0,
        isDraft: (json['is_draft'] ?? 0) > 0,
        imageData: json['image_data'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'tags': tags,
        'file_path': filePath,
        'created_at': createdAt.toIso8601String(),
        'is_bookmarked': isBookmarked ? 1 : 0,
        'is_draft': isDraft ? 1 : 0,
        'image_data': imageData,
      };
}

class Todo {
  final int id;
  final String task;
  String status;

  Todo({required this.id, required this.task, required this.status});

  factory Todo.fromJson(Map<String, dynamic> json) => Todo(
        id: json['id'],
        task: json['task'] ?? '',
        status: json['status'] ?? 'todo',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'task': task,
        'status': status,
      };
}
