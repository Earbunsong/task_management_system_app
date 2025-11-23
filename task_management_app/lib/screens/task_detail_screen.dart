import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:task_management_app/core/routes.dart';
import 'package:task_management_app/core/theme/app_theme.dart';
import 'package:task_management_app/models/task.dart';
import 'package:task_management_app/services/task_service.dart';
import 'package:task_management_app/services/media_service.dart';
import 'package:task_management_app/services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final _taskService = TaskService();
  final _mediaService = MediaService();
  final _authService = AuthService();
  final _imagePicker = ImagePicker();

  bool _deleting = false;
  bool _uploading = false;
  List<MediaFile> _mediaFiles = [];
  List<AssignedUser> _assignedUsers = [];
  bool _isPro = false;

  @override
  void initState() {
    super.initState();
    _mediaFiles = widget.task.mediaFiles;
    _assignedUsers = widget.task.assignedUsers;
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadMedia();
    await _checkProStatus();
  }

  Future<void> _checkProStatus() async {
    try {
      final user = await _authService.getProfile();
      setState(() {
        _isPro = user.userType.toLowerCase() == 'pro';
      });
    } catch (e) {
      // Ignore error
    }
  }

  Future<void> _loadMedia() async {
    try {
      final files = await _mediaService.getTaskMedia(widget.task.id);
      setState(() => _mediaFiles = files);
    } catch (e) {
      // Ignore errors, media is optional
    }
  }

  Future<void> _refreshTask() async {
    try {
      final tasks = await _taskService.getTasks();
      final updatedTask = tasks.firstWhere(
        (t) => t.id == widget.task.id,
        orElse: () => widget.task,
      );
      setState(() {
        _assignedUsers = updatedTask.assignedUsers;
      });
    } catch (e) {
      // Ignore error
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _uploading = true);

      final file = File(image.path);
      await _mediaService.uploadMedia(widget.task.id, file);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image uploaded successfully'),
          backgroundColor: Colors.green,
        ),
      );

      await _loadMedia();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _deleteMedia(MediaFile media) async {
    try {
      await _mediaService.deleteMedia(widget.task.id, media.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Media deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );

      await _loadMedia();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete media: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteTask() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _deleting = true);

    try {
      await _taskService.deleteTask(widget.task.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop(true); // Return true to indicate change
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete task: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  Future<void> _showAssignUserDialog() async {
    if (!_isPro) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only Pro users can assign tasks'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final users = await _taskService.getUsers();
      if (!mounted) return;

      // Filter out already assigned users
      final assignedIds = _assignedUsers.map((u) => u.id).toSet();
      final availableUsers = users.where((u) => !assignedIds.contains(u['id'])).toList();

      if (availableUsers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No users available to assign'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final selectedUser = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Assign User'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availableUsers.length,
              itemBuilder: (context, index) {
                final user = availableUsers[index];
                final isPro = (user['role'] as String?)?.toLowerCase() == 'pro';
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isPro ? Colors.amber : Colors.blue,
                    child: Text(
                      (user['username'] as String? ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(user['username'] as String? ?? 'Unknown'),
                  subtitle: Text(user['email'] as String? ?? ''),
                  trailing: isPro
                      ? const Icon(Icons.workspace_premium, color: Colors.amber, size: 20)
                      : null,
                  onTap: () => Navigator.of(context).pop(user),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );

      if (selectedUser != null) {
        await _assignUser(selectedUser['id'] as int);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load users: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _assignUser(int userId) async {
    try {
      await _taskService.assignTask(widget.task.id, userId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User assigned successfully'),
          backgroundColor: Colors.green,
        ),
      );

      await _refreshTask();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to assign user: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _unassignUser(AssignedUser user) async {
    if (!_isPro) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only Pro users can unassign tasks'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unassign User'),
        content: Text('Remove ${user.username} from this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Unassign'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _taskService.unassignTask(widget.task.id, user.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User unassigned successfully'),
          backgroundColor: Colors.green,
        ),
      );

      await _refreshTask();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to unassign user: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.of(context).pushNamed(
                AppRoutes.editTask,
                arguments: widget.task,
              );
              if (result == true) {
                Navigator.of(context).pop(true); // Pass change back
              }
            },
          ),
          if (_deleting)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteTask,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              widget.task.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),

            // Status and Priority
            Row(
              children: [
                _buildInfoChip(
                  label: 'Status',
                  value: widget.task.status.replaceAll('_', ' ').toUpperCase(),
                  color: AppTheme.statusColor(widget.task.status),
                ),
                const SizedBox(width: 12),
                _buildInfoChip(
                  label: 'Priority',
                  value: widget.task.priority.toUpperCase(),
                  color: AppTheme.priorityColor(widget.task.priority),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Due Date
            _buildInfoSection(
              icon: Icons.calendar_today,
              title: 'Due Date',
              content: widget.task.dueDate != null
                  ? _formatDate(widget.task.dueDate!)
                  : 'No due date set',
            ),
            const SizedBox(height: 16),

            // Description
            _buildInfoSection(
              icon: Icons.description,
              title: 'Description',
              content: widget.task.description.isNotEmpty
                  ? widget.task.description
                  : 'No description provided',
            ),
            const SizedBox(height: 16),

            // Created At
            if (widget.task.createdAt != null)
              _buildInfoSection(
                icon: Icons.access_time,
                title: 'Created',
                content: _formatDateTime(widget.task.createdAt!),
              ),
            const SizedBox(height: 16),

            // Updated At
            if (widget.task.updatedAt != null)
              _buildInfoSection(
                icon: Icons.update,
                title: 'Last Updated',
                content: _formatDateTime(widget.task.updatedAt!),
              ),
            const SizedBox(height: 24),

            // Assigned Users Section (Pro feature)
            Row(
              children: [
                Icon(Icons.people, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Assigned Users',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const Spacer(),
                if (_isPro)
                  IconButton(
                    icon: const Icon(Icons.person_add),
                    onPressed: _showAssignUserDialog,
                    tooltip: 'Assign User',
                  )
                else
                  Tooltip(
                    message: 'Upgrade to Pro to assign tasks',
                    child: Icon(Icons.lock, size: 20, color: Colors.grey[400]),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Assigned Users List
            if (_assignedUsers.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        _isPro
                            ? 'No users assigned yet'
                            : 'Upgrade to Pro to collaborate',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: _assignedUsers.map((user) {
                  final isPro = user.role.toLowerCase() == 'pro';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isPro ? Colors.amber : Colors.blue,
                        child: Text(
                          user.username.isNotEmpty
                              ? user.username[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(user.username),
                          if (isPro) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.workspace_premium,
                              color: Colors.amber,
                              size: 16,
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text(user.email),
                      trailing: _isPro
                          ? IconButton(
                              icon: const Icon(Icons.remove_circle, color: Colors.red),
                              onPressed: () => _unassignUser(user),
                              tooltip: 'Unassign',
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 24),

            // Attachments Section
            Row(
              children: [
                Icon(Icons.attach_file, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Attachments',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const Spacer(),
                if (!_uploading)
                  IconButton(
                    icon: const Icon(Icons.add_photo_alternate),
                    onPressed: _pickAndUploadImage,
                    tooltip: 'Add Image',
                  )
                else
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Media Grid
            if (_mediaFiles.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(
                    'No attachments yet',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: _mediaFiles.length,
                itemBuilder: (context, index) {
                  final media = _mediaFiles[index];
                  return _buildMediaCard(media);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaCard(MediaFile media) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: () async {
          final uri = Uri.parse(media.fileUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image thumbnail
            if (media.fileType == 'image')
              Image.network(
                media.fileUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                },
              )
            else
              Container(
                color: Colors.grey[200],
                child: Center(
                  child: Icon(
                    Icons.insert_drive_file,
                    size: 48,
                    color: Colors.grey[600],
                  ),
                ),
              ),

            // Delete button
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white, size: 20),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Attachment'),
                        content: const Text('Are you sure you want to delete this attachment?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await _deleteMedia(media);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference < 0) {
      return '${date.day}/${date.month}/${date.year} (Overdue)';
    } else if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
