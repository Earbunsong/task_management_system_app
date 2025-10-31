import 'package:flutter/material.dart';
import 'package:task_management_app/models/task.dart';
import 'package:task_management_app/services/auth_service.dart';
import 'package:task_management_app/services/task_service.dart';
import 'package:task_management_app/utils/ui.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final _service = TaskService();
  final _auth = AuthService();
  List<Task> _tasks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _tasks = await _service.getTasks();
    } catch (e) {
      if (mounted) showSnack(context, 'Failed to load tasks');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createOrEdit({Task? task}) async {
    final titleCtrl = TextEditingController(text: task?.title ?? '');
    final descCtrl = TextEditingController(text: task?.description ?? '');
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(task == null ? 'Create Task' : 'Edit Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                if (task == null) {
                  await _service.createTask({'title': titleCtrl.text, 'description': descCtrl.text});
                } else {
                  await _service.updateTask(task.id, {'title': titleCtrl.text, 'description': descCtrl.text});
                }
                if (mounted) Navigator.pop(ctx);
                await _load();
              } catch (e) {
                showSnack(context, 'Save failed');
              }
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  Future<void> _delete(Task task) async {
    try {
      await _service.deleteTask(task.id);
      await _load();
    } catch (e) {
      showSnack(context, 'Delete failed');
    }
  }

  Future<void> _logout() async {
    await _auth.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          IconButton(onPressed: () => Navigator.pushNamed(context, '/payments'), icon: const Icon(Icons.payment)),
          IconButton(onPressed: () => Navigator.pushNamed(context, '/notifications'), icon: const Icon(Icons.notifications)),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createOrEdit(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                itemCount: _tasks.length,
                itemBuilder: (ctx, i) {
                  final t = _tasks[i];
                  return ListTile(
                    title: Text(t.title),
                    subtitle: Text(t.description ?? ''),
                    onTap: () => _createOrEdit(task: t),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _delete(t),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
