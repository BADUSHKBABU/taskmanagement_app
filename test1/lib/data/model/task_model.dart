import 'package:test1/domain/entity/taskentity.dart';

class TaskModel extends TaskEntity {
  const TaskModel({
    super.id,
    required super.title,
    super.description,
    required super.priority,
    required super.category,
    super.dueDate,
    super.isCompleted = false,
    super.createdAt,
    super.updatedAt,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = {
      "title": title,
      "description": description ?? "",
      "priority": priority,
      "category": category,
      "is_completed": isCompleted,
    };
    if (id != null) map["id"] = id;
    if (dueDate != null) map["due_date"] = dueDate!.toIso8601String();
    return map;
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    int? parsedId;
    if (json['id'] != null) {
      parsedId = json['id'] is int ? json['id'] as int : int.tryParse(json['id'].toString());
    }

    DateTime? parsedDueDate;
    if (json['due_date'] != null && json['due_date'].toString().isNotEmpty) {
      parsedDueDate = DateTime.tryParse(json['due_date'].toString());
    }

    DateTime? parsedCreatedAt;
    if (json['created_at'] != null && json['created_at'].toString().isNotEmpty) {
      parsedCreatedAt = DateTime.tryParse(json['created_at'].toString());
    }

    DateTime? parsedUpdatedAt;
    if (json['updated_at'] != null && json['updated_at'].toString().isNotEmpty) {
      parsedUpdatedAt = DateTime.tryParse(json['updated_at'].toString());
    }

    return TaskModel(
      id: parsedId,
      title: json['title'] ?? 'Untitled Task',
      description: json['description'] ?? '',
      priority: json['priority'] ?? 'Medium',
      category: json['category'] ?? 'Work',
      dueDate: parsedDueDate,
      isCompleted: json['is_completed'] ?? false,
      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,
    );
  }

  factory TaskModel.fromEntity(TaskEntity entity) {
    return TaskModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      priority: entity.priority,
      category: entity.category,
      dueDate: entity.dueDate,
      isCompleted: entity.isCompleted,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
