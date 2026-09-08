import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:test1/core/errors/exceptions.dart';
import 'package:test1/data/model/task_model.dart';

class TaskListResult {
  final List<TaskModel> tasks;
  final int total;
  TaskListResult({required this.tasks, required this.total});
}

abstract class TaskRemoteDataSource {
  Future<TaskModel> addTask(String userId, TaskModel task);
  Future<TaskListResult> getTasks(
    String userId, {
    required int skip,
    required int limit,
  });
  Future<TaskModel> getTask(String userId, int taskId);
  Future<TaskModel> updateTask(
    String userId,
    int taskId,
    Map<String, dynamic> changes,
  );
  Future<void> deleteTask(String userId, int taskId);
}

class TaskRemoteDataSourceImpl implements TaskRemoteDataSource {
  final http.Client client;
  final String baseUrl = "https://taskmanager.uat-lplusltd.com";

  TaskRemoteDataSourceImpl(this.client);

  @override
  Future<TaskModel> addTask(String userId, TaskModel task) async {
    print("user id get from task remote data source $userId");
    final uri = Uri.parse("$baseUrl/tasks/?user_id=$userId");
    print("url to be send is :$uri");
    print("task to be send is :${task.toJson()}");
    try {
      final response = await client.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(task.toJson()),
      );
      print("repose from the server :${response.body}");
      return _unwrapSingle(response, "add task");
    } on SocketException {
      throw NetworkException(
        "No internet connection. Please check your network.",
      );
    } catch (e) {
      if (e is ServerException || e is NetworkException) rethrow;
      throw ServerException("Failed to add task: ${e.toString()}");
    }
  }

  @override
  Future<TaskListResult> getTasks(
    String userId, {
    required int skip,
    required int limit,
  }) async {
    final uri = Uri.parse(
      "$baseUrl/tasks/?user_id=$userId&skip=$skip&limit=$limit",
    );
    try {
      final response = await client.get(uri);
      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body['status'] == 'success') {
        final List data = body['data'] ?? [];
        return TaskListResult(
          tasks: data.map((e) => TaskModel.fromJson(e)).toList(),
          total: body['total'] ?? data.length,
        );
      }
      throw ServerException(
        body['message'] ?? "Failed to fetch tasks",
        response.statusCode,
      );
    } on SocketException {
      throw NetworkException(
        "No internet connection. Please check your network.",
      );
    } catch (e) {
      if (e is ServerException || e is NetworkException) rethrow;
      throw ServerException("Failed to fetch tasks: ${e.toString()}");
    }
  }

  @override
  Future<TaskModel> getTask(String userId, int taskId) async {
    final uri = Uri.parse("$baseUrl/tasks/$taskId?user_id=$userId");
    try {
      final response = await client.get(uri);
      return _unwrapSingle(response, "load task");
    } on SocketException {
      throw NetworkException(
        "No internet connection. Please check your network.",
      );
    } catch (e) {
      if (e is ServerException || e is NetworkException) rethrow;
      throw ServerException("Failed to load task: ${e.toString()}");
    }
  }

  @override
  Future<TaskModel> updateTask(
    String userId,
    int taskId,
    Map<String, dynamic> changes,
  ) async {
    final uri = Uri.parse("$baseUrl/tasks/$taskId?user_id=$userId");
    try {
      final response = await client.put(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(changes),
      );
      return _unwrapSingle(response, "update task");
    } on SocketException {
      throw NetworkException(
        "No internet connection. Please check your network.",
      );
    } catch (e) {
      if (e is ServerException || e is NetworkException) rethrow;
      throw ServerException("Failed to update task: ${e.toString()}");
    }
  }

  @override
  Future<void> deleteTask(String userId, int taskId) async {
    final uri = Uri.parse("$baseUrl/tasks/$taskId?user_id=$userId");
    try {
      final response = await client.delete(uri);
      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body['status'] == 'success') {
        return;
      }
      if (response.statusCode == 404) {
        throw ServerException("Task not found", 404);
      }
      throw ServerException(
        body['message'] ?? "Failed to delete task",
        response.statusCode,
      );
    } on SocketException {
      throw NetworkException(
        "No internet connection. Please check your network.",
      );
    } catch (e) {
      if (e is ServerException || e is NetworkException) rethrow;
      throw ServerException("Failed to delete task: ${e.toString()}");
    }
  }

  TaskModel _unwrapSingle(http.Response response, String action) {
    final body = jsonDecode(response.body);

    if ((response.statusCode == 200 || response.statusCode == 201) &&
        body['status'] == 'success') {
      return TaskModel.fromJson(body['data']);
    }
    if (response.statusCode == 422) {
      throw ServerException(body['message'] ?? "Validation error", 422);
    }
    if (response.statusCode == 404) {
      throw ServerException("Task not found", 404);
    }
    throw ServerException(
      body['message'] ?? "Failed to $action",
      response.statusCode,
    );
  }
}
