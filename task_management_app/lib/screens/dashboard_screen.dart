import 'dart:async';
import 'package:flutter/material.dart';
import 'package:task_management_app/core/routes.dart';
import 'package:task_management_app/models/task.dart';
import 'package:task_management_app/services/auth_service.dart';
import 'package:task_management_app/services/task_service.dart';
import 'package:task_management_app/widgets/empty_state.dart';
import 'package:task_management_app/widgets/error_view.dart';
import 'package:task_management_app/widgets/task_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final _taskService = TaskService();
  final _authService = AuthService();

  late TabController _tabController;
  int _selectedNavIndex = 0;

  List<Task> _allTasks = [];
  bool _loading = true;
  String? _error;

  // Task count info
  int _currentTaskCount = 0;
  int? _taskLimit;
  int? _remainingTasks;
  bool _isPro = false;
  bool _isAdmin = false;

  // Auto-refresh timer
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserRole();
    _loadTasks();
    _startAutoRefresh();
  }

  Future<void> _loadUserRole() async {
    try {
      final user = await _authService.getProfile();
      setState(() {
        _isAdmin = user.role.toLowerCase() == 'admin';
      });
    } catch (e) {
      // If we can't load the profile, assume not admin
      setState(() {
        _isAdmin = false;
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    // Auto-refresh tasks every 10 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        _loadTasksQuietly();
      }
    });
  }

  Future<void> _loadTasks() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final tasks = await _taskService.getTasks();
      final countInfo = await _taskService.getTaskCount();

      setState(() {
        _allTasks = tasks;
        _currentTaskCount = countInfo['current_count'] ?? 0;
        _taskLimit = countInfo['limit'];
        _remainingTasks = countInfo['remaining'];
        _isPro = countInfo['is_pro'] ?? false;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // Load tasks without showing loading indicator (for background refresh)
  Future<void> _loadTasksQuietly() async {
    try {
      final tasks = await _taskService.getTasks();
      final countInfo = await _taskService.getTaskCount();

      if (mounted) {
        setState(() {
          _allTasks = tasks;
          _currentTaskCount = countInfo['current_count'] ?? 0;
          _taskLimit = countInfo['limit'];
          _remainingTasks = countInfo['remaining'];
          _isPro = countInfo['is_pro'] ?? false;
        });
      }
    } catch (e) {
      // Silently fail for background refresh
      debugPrint('Background refresh failed: $e');
    }
  }

  List<Task> _getFilteredTasks() {
    switch (_tabController.index) {
      case 0: // All
        return _allTasks;
      case 1: // Pending
        return _allTasks
            .where((task) =>
                task.status.toLowerCase() == 'pending' ||
                task.status.toLowerCase() == 'in_progress')
            .toList();
      case 2: // Completed
        return _allTasks
            .where((task) => task.status.toLowerCase() == 'completed')
            .toList();
      default:
        return _allTasks;
    }
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedNavIndex = index;
    });

    switch (index) {
      case 0: // Dashboard
        // Already on dashboard
        break;
      case 1: // Tasks - could be a different view
        // Stay on same screen for now
        break;
      case 2: // Payment
        Navigator.of(context).pushNamed(AppRoutes.payment);
        break;
      case 3: // Profile
        Navigator.of(context).pushNamed(AppRoutes.profile);
        break;
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
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
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.logout();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      }
    }
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.workspace_premium, color: Colors.amber, size: 48),
        title: const Text('Upgrade to Pro'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You\'ve reached the task limit for Basic users ($_taskLimit tasks).',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Upgrade to Pro to unlock:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildUpgradeFeature('Unlimited tasks'),
            _buildUpgradeFeature('Task assignment & collaboration'),
            _buildUpgradeFeature('Unlimited media uploads'),
            _buildUpgradeFeature('Priority support'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(AppRoutes.payment);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.white,
            ),
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeFeature(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          // Admin button (only visible to admins)
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: 'Admin Panel',
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.adminUsers);
              },
            ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.notifications);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) {
            setState(() {}); // Rebuild to show filtered tasks
          },
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Task count banner for Basic users
          if (!_isPro && _taskLimit != null) _buildTaskLimitBanner(),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Check task limit for basic users
          final taskLimit = _taskLimit;
          if (!_isPro && taskLimit != null && _currentTaskCount >= taskLimit) {
            _showUpgradeDialog();
            return;
          }

          final result = await Navigator.of(context).pushNamed(AppRoutes.addTask);
          if (result == true) {
            _loadTasks(); // Reload tasks after adding
          }
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedNavIndex,
        onTap: _onNavItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task_alt),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payment),
            label: 'Payment',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return ErrorView(
        message: _error!,
        onRetry: _loadTasks,
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildTaskList(_getFilteredTasks()),
        _buildTaskList(_getFilteredTasks()),
        _buildTaskList(_getFilteredTasks()),
      ],
    );
  }

  Widget _buildTaskList(List<Task> tasks) {
    if (tasks.isEmpty) {
      return EmptyState(
        icon: Icons.task_outlined,
        title: 'No Tasks',
        message: 'You don\'t have any tasks yet.\nTap the + button to create one!',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTasks,
      child: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return TaskCard(
            task: task,
            onTap: () async {
              final result = await Navigator.of(context).pushNamed(
                AppRoutes.taskDetail,
                arguments: task,
              );
              if (result == true) {
                _loadTasks(); // Reload if task was updated or deleted
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildTaskLimitBanner() {
    final percentage = _taskLimit != null ? (_currentTaskCount / _taskLimit!) : 0.0;
    final isNearLimit = percentage >= 0.8;
    final isAtLimit = _currentTaskCount >= (_taskLimit ?? 0);

    Color bannerColor;
    IconData bannerIcon;
    String bannerText;

    if (isAtLimit) {
      bannerColor = Colors.red;
      bannerIcon = Icons.warning;
      bannerText = 'Task limit reached! Upgrade to Pro for unlimited tasks.';
    } else if (isNearLimit) {
      bannerColor = Colors.orange;
      bannerIcon = Icons.info;
      bannerText = '$_remainingTasks tasks remaining. Upgrade to Pro for unlimited tasks.';
    } else {
      bannerColor = Colors.blue;
      bannerIcon = Icons.info_outline;
      bannerText = '$_currentTaskCount / $_taskLimit tasks used.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bannerColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: bannerColor.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          Icon(bannerIcon, color: bannerColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bannerText,
                  style: TextStyle(
                    color: bannerColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage.clamp(0.0, 1.0),
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(bannerColor),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
          if (isNearLimit || isAtLimit) ...[
            const SizedBox(width: 12),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.payment);
              },
              style: TextButton.styleFrom(
                backgroundColor: bannerColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text('Upgrade', style: TextStyle(fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }
}
