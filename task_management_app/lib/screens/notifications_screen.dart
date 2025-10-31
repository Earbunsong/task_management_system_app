import 'package:flutter/material.dart';
import 'package:task_management_app/models/app_notification.dart';
import 'package:task_management_app/services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _service = NotificationService();
  List<AppNotification> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _items = await _service.getNotifications();
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markRead(AppNotification n) async {
    try {
      await _service.markAsRead(n.id);
      await _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                itemCount: _items.length,
                itemBuilder: (ctx, i) {
                  final n = _items[i];
                  return ListTile(
                    title: Text(n.message),
                    subtitle: Text(n.createdAt),
                    trailing: n.isRead
                        ? const Icon(Icons.check, color: Colors.green)
                        : TextButton(
                            onPressed: () => _markRead(n),
                            child: const Text('Mark read'),
                          ),
                  );
                },
              ),
            ),
    );
  }
}
