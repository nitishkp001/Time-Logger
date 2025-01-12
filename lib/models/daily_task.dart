class DailyTask {
  final int? id;
  final String title;
  final String? description;
  final bool isCompleted;
  final String category;
  final bool reminderEnabled;

  DailyTask({
    this.id,
    required this.title,
    this.description,
    this.isCompleted = false,
    required this.category,
    this.reminderEnabled = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted ? 1 : 0,
      'category': category,
      'reminderEnabled': reminderEnabled ? 1 : 0,
    };
  }

  factory DailyTask.fromMap(Map<String, dynamic> map) {
    return DailyTask(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      isCompleted: map['isCompleted'] == 1,
      category: map['category'] as String,
      reminderEnabled: map['reminderEnabled'] == 1,
    );
  }

  DailyTask copyWith({
    int? id,
    String? title,
    String? description,
    bool? isCompleted,
    String? category,
    bool? reminderEnabled,
  }) {
    return DailyTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      category: category ?? this.category,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    );
  }
}
