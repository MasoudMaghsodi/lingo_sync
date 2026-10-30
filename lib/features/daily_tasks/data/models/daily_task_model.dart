class DailyTaskModel {
  final int id;
  final int dayNumber;
  final String taskType;
  final String title;
  final String description;
  final String? videoUrl;
  final bool isCompleted;

  DailyTaskModel({
    required this.id,
    required this.dayNumber,
    required this.taskType,
    required this.title,
    required this.description,
    this.videoUrl,
    this.isCompleted = false,
  });

  factory DailyTaskModel.fromJson(Map<String, dynamic> json) {
    return DailyTaskModel(
      id: json['id'] as int,
      dayNumber: json['day_number'] as int,
      taskType: json['task_type'] as String,
      title: json['title'] as String,
      description: json['description'] ?? '',
      videoUrl: json['video_url'] as String?,
      isCompleted: json['is_completed'] ?? false,
    );
  }

  DailyTaskModel copyWith({bool? isCompleted, String? videoUrl}) {
    return DailyTaskModel(
      id: id,
      dayNumber: dayNumber,
      taskType: taskType,
      title: title,
      description: description,
      videoUrl: videoUrl ?? this.videoUrl,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
