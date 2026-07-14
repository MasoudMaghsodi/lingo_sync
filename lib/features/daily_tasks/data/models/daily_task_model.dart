class DailyTaskModel {
  final int id;
  final int dayNumber;
  final String taskType;
  final String title;
  final String description;
  final bool isCompleted;

  DailyTaskModel({
    required this.id,
    required this.dayNumber,
    required this.taskType,
    required this.title,
    required this.description,
    this.isCompleted = false,
  });

  factory DailyTaskModel.fromJson(Map<String, dynamic> json) {
    return DailyTaskModel(
      id: json['id'] as int,
      dayNumber: json['day_number'] as int,
      taskType: json['task_type'] as String,
      title: json['title'] as String,
      description: json['description'] ?? '',
      isCompleted: json['is_completed'] ?? false,
    );
  }

  DailyTaskModel copyWith({bool? isCompleted}) {
    return DailyTaskModel(
      id: id,
      dayNumber: dayNumber,
      taskType: taskType,
      title: title,
      description: description,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
