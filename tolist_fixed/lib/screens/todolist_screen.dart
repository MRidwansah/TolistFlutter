import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../models/models.dart';
import '../services/storage_service.dart';

class TodolistScreen extends StatefulWidget {
  final User user;
  const TodolistScreen({super.key, required this.user});

  @override
  State<TodolistScreen> createState() => _TodolistScreenState();
}

class _TodolistScreenState extends State<TodolistScreen> with SingleTickerProviderStateMixin {
  List<Todo> _todos = [];
  bool _loading = true;
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final todos = await StorageService.getTodos();
    if (mounted) {
      setState(() {
        _todos = todos;
        _loading = false;
      });
    }
  }

  List<Todo> _byStatus(String s) => _todos.where((t) => t.status == s).toList();

  Future<void> _addTask(String status, String text) async {
    if (text.trim().isEmpty) return;
    
    // UUID akan di-generate otomatis oleh Supabase
    final todo = Todo(task: text.trim(), status: status);
    
    await StorageService.saveTodo(todo);
    await _load(); // Load ulang untuk mendapatkan ID dari Supabase
    _toast('Tugas ditambahkan!', true);
  }

  Future<void> _moveTask(Todo todo, String newStatus) async {
    todo.status = newStatus;
    await StorageService.saveTodo(todo);
    await _load();
    _toast('Status diperbarui', true);
  }

  Future<void> _deleteTask(Todo todo) async {
    if (todo.id != null) {
      await StorageService.deleteTodo(todo.id!);
      await _load();
      _toast('Tugas dihapus', false);
    }
  }

  void _toast(String msg, bool success) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(success ? Icons.check_circle_outline : Icons.delete_outline,
            color: success ? AppColors.emerald : AppColors.rose, size: 16),
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

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.indigo));

    final statuses = ['todo', 'in_progress', 'done'];
    final labels = ['To Do', 'In Progress', 'Done'];
    final colors = [AppColors.indigo, AppColors.amber, AppColors.emerald];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Papan Tugas 🎯',
                style: GoogleFonts.inter(color: AppColors.textWhite, fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 2),
            Text('Atur prioritasmu dengan cara yang seru!',
                style: GoogleFonts.inter(color: AppColors.textSlate500, fontSize: 12)),
          ]),
        ),

        Container(
          margin: const EdgeInsets.symmetric(horizontal: 14),
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderSlate800),
          ),
          child: TabBar(
            controller: _tabCtrl,
            isScrollable: false,
            padding: const EdgeInsets.all(4),
            labelPadding: EdgeInsets.zero,
            indicator: BoxDecoration(
              color: AppColors.indigo.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.indigo.withOpacity(0.3)),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: AppColors.textWhite,
            unselectedLabelColor: AppColors.textSlate500,
            tabs: List.generate(3, (i) {
              final count = _byStatus(statuses[i]).length;
              return Tab(
                height: 36,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: colors[i])),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(labels[i], style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 11), overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(color: colors[i].withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                      child: Text('$count', style: GoogleFonts.inter(color: colors[i], fontSize: 10, fontWeight: FontWeight.w900)),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),

        const SizedBox(height: 12),

        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: List.generate(3, (i) => _KanbanColumn(
              status: statuses[i],
              color: colors[i],
              todos: _byStatus(statuses[i]),
              onAdd: (text) => _addTask(statuses[i], text),
              onMove: _moveTask,
              onDelete: _deleteTask,
            )),
          ),
        ),
      ],
    );
  }
}

class _KanbanColumn extends StatefulWidget {
  final String status;
  final Color color;
  final List<Todo> todos;
  final Function(String) onAdd;
  final Function(Todo, String) onMove;
  final Function(Todo) onDelete;

  const _KanbanColumn({
    required this.status, required this.color, required this.todos,
    required this.onAdd, required this.onMove, required this.onDelete,
  });

  @override
  State<_KanbanColumn> createState() => _KanbanColumnState();
}

class _KanbanColumnState extends State<_KanbanColumn> {
  final _ctrl = TextEditingController();

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  List<Map<String, String>> _moveOptions(String status) {
    if (status == 'todo') return [{'status': 'in_progress', 'icon': 'forward'}];
    if (status == 'in_progress') {
      return [
      {'status': 'todo', 'icon': 'back'},
      {'status': 'done', 'icon': 'check'},
    ];
    }
    return [{'status': 'in_progress', 'icon': 'back'}];
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderSlate700),
          ),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                style: GoogleFonts.inter(color: AppColors.textSlate200, fontSize: 13),
                onSubmitted: (v) { widget.onAdd(v); _ctrl.clear(); },
                decoration: InputDecoration(
                  hintText: 'Tambah tugas baru...',
                  hintStyle: GoogleFonts.inter(color: AppColors.textSlate600, fontSize: 13),
                  border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            GestureDetector(
              onTap: () { widget.onAdd(_ctrl.text); _ctrl.clear(); },
              child: Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Text('+', style: GoogleFonts.inter(color: widget.color, fontSize: 22, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 10),
      Expanded(
        child: widget.todos.isEmpty
            ? Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.inbox_outlined, color: AppColors.textSlate600, size: 38),
                  const SizedBox(height: 10),
                  Text('Tidak ada tugas', style: GoogleFonts.inter(color: AppColors.textSlate600, fontSize: 13)),
                ]),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 80),
                itemCount: widget.todos.length,
                itemBuilder: (_, i) => _TaskCard(
                  todo: widget.todos[i],
                  color: widget.color,
                  moveOptions: _moveOptions(widget.status),
                  onMove: (s) => widget.onMove(widget.todos[i], s),
                  onDelete: () => widget.onDelete(widget.todos[i]),
                ),
              ),
      ),
    ]);
  }
}

class _TaskCard extends StatelessWidget {
  final Todo todo;
  final Color color;
  final List<Map<String, String>> moveOptions;
  final Function(String) onMove;
  final VoidCallback onDelete;

  const _TaskCard({
    required this.todo, required this.color, required this.moveOptions,
    required this.onMove, required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = todo.status == 'done';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSlate800),
      ),
      child: Row(children: [
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Column(children: List.generate(3, (_) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 1.5),
            child: Container(width: 14, height: 2, decoration: BoxDecoration(color: AppColors.textSlate600, borderRadius: BorderRadius.circular(2))),
          ))),
        ),
        Expanded(
          child: Text(
            todo.task,
            style: GoogleFonts.inter(
              color: isDone ? AppColors.textSlate600 : AppColors.textSlate200,
              fontSize: 13, fontWeight: FontWeight.w500,
              decoration: isDone ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
        Row(mainAxisSize: MainAxisSize.min, children: [
          ...moveOptions.map((opt) {
            IconData icon;
            Color btnColor;
            if (opt['icon'] == 'forward') { icon = Icons.arrow_forward_ios_rounded; btnColor = AppColors.indigo; }
            else if (opt['icon'] == 'check') { icon = Icons.check_rounded; btnColor = AppColors.emerald; }
            else { icon = Icons.arrow_back_ios_rounded; btnColor = AppColors.textSlate400; }
            return GestureDetector(
              onTap: () => onMove(opt['status']!),
              child: Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(color: btnColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: btnColor, size: 14),
              ),
            );
          }),
          GestureDetector(
            onTap: onDelete,
            child: Container(
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: AppColors.rose.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.delete_outline, color: AppColors.rose, size: 14),
            ),
          ),
        ]),
      ]),
    );
  }
}