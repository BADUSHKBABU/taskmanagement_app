class TaskEntity {
  final int? id;
  final String title;
  final String? description;
  final bool isCompleted;
  final String priority; // "Low" | "Medium" | "High"
  final String category; // "Work" | "Personal" | "Health" | "Finance" | "Education" | "Shopping" | "Travel" | "Others"
  final DateTime? dueDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TaskEntity({
    this.id,
    required this.title,
    this.description,
    this.isCompleted = false,
    required this.priority,
    required this.category,
    this.dueDate,
    this.createdAt,
    this.updatedAt,
  });

  TaskEntity copyWith({
    int? id,
    String? title,
    String? description,
    bool? isCompleted,
    String? priority,
    String? category,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          isCompleted == other.isCompleted &&
          priority == other.priority &&
          category == other.category &&
          dueDate == other.dueDate;

  @override
  int get hashCode => Object.hash(
        id,
        title,
        description,
        isCompleted,
        priority,
        category,
        dueDate,
      );
}