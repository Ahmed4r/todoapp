// Task entity
class Task {
  final String id;
  final String title;
  final String description;
  final bool isCompleted;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final TaskPriority priority;
  final TaskCategory category;

  const Task({
    required this.id,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    this.priority = TaskPriority.medium,
    this.category = TaskCategory.personal,
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    TaskPriority? priority,
    TaskCategory? category,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      priority: priority ?? this.priority,
      category: category ?? this.category,
    );
  }
}

enum TaskPriority { low, medium, high, urgent }

enum TaskCategory {
  work,
  personal,
  study,
  health,
  creative,
  travel,
  shopping,
  family,
}
