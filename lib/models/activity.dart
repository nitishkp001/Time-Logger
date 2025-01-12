class Activity {
  final int? id;
  final String title;
  final DateTime startTime;
  final DateTime? endTime;
  final String category;
  final String? notes;

  Activity({
    this.id,
    required this.title,
    required this.startTime,
    this.endTime,
    required this.category,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'category': category,
      'notes': notes,
    };
  }

  factory Activity.fromMap(Map<String, dynamic> map) {
    return Activity(
      id: map['id'] as int?,
      title: map['title'] as String,
      startTime: DateTime.parse(map['startTime'] as String),
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime'] as String) : null,
      category: map['category'] as String,
      notes: map['notes'] as String?,
    );
  }

  Activity copyWith({
    int? id,
    String? title,
    DateTime? startTime,
    DateTime? endTime,
    String? category,
    String? notes,
  }) {
    return Activity(
      id: id ?? this.id,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      category: category ?? this.category,
      notes: notes ?? this.notes,
    );
  }
}
