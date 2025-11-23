import 'package:task_management_app/models/task.dart';
import 'package:task_management_app/services/api_client.dart';

class TaskService {
  final _client = ApiClient()..init();

  Future<List<Task>> getTasks() async {
    final res = await _client.dio.get('/tasks/');
    // Handle paginated response from Django REST Framework
    if (res.data is Map && res.data.containsKey('results')) {
      final list = res.data['results'] as List<dynamic>;
      return list.map((e) => Task.fromJson(e as Map<String, dynamic>)).toList();
    }
    // Handle non-paginated response (direct array)
    final list = res.data as List<dynamic>;
    return list.map((e) => Task.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Task> createTask(Map<String, dynamic> payload) async {
    final res = await _client.dio.post('/tasks/', data: payload);
    return Task.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Task> updateTask(int id, Map<String, dynamic> payload) async {
    final res = await _client.dio.put('/tasks/$id/', data: payload);
    return Task.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteTask(int id) async {
    await _client.dio.delete('/tasks/$id/');
  }

  Future<void> assignTask(int taskId, int userId) async {
    await _client.dio.post('/tasks/$taskId/assign/', data: {'user_id': userId});
  }

  Future<void> unassignTask(int taskId, int userId) async {
    await _client.dio.delete('/tasks/$taskId/unassign/', data: {'user_id': userId});
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    final res = await _client.dio.get('/tasks/users/');
    return (res.data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getTaskCount() async {
    final res = await _client.dio.get('/tasks/count/');
    return res.data as Map<String, dynamic>;
  }
}
