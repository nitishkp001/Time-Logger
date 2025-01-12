class PlannerItem {
  final int? id;
  final String title;
  final String? description;
  final DateTime startDate;
  final DateTime? endDate;
  final String type; // 'daily', 'weekly', 'monthly'
  final String category;
  final bool isCompleted;
  final int priority; // 1: Low, 2: Medium, 3: High
  final bool reminderEnabled;

  PlannerItem({
    this.id,
    required this.title,
    this.description,
    required this.startDate,
    this.endDate,
    required this.type,
    required this.category,
    this.isCompleted = false,
    this.priority = 1,
    this.reminderEnabled = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'type': type,
      'category': category,
      'isCompleted': isCompleted ? 1 : 0,
      'priority': priority,
      'reminderEnabled': reminderEnabled ? 1 : 0,
    };
  }

  factory PlannerItem.fromMap(Map<String, dynamic> map) {
    return PlannerItem(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate'] as String) : null,
      type: map['type'] as String,
      category: map['category'] as String,
      isCompleted: map['isCompleted'] == 1,
      priority: map['priority'] as int,
      reminderEnabled: map['reminderEnabled'] == 1,
    );
  }

  PlannerItem copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? type,
    String? category,
    bool? isCompleted,
    int? priority,
    bool? reminderEnabled,
  }) {
    return PlannerItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      type: type ?? this.type,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    );
  }
}
