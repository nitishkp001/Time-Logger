import 'package:flutter/foundation.dart';
import '../models/activity.dart';
import '../services/database_service.dart';

class ActivityProvider with ChangeNotifier {
  List<Activity> _activities = [];
  Activity? _currentActivity;

  List<Activity> get activities => _activities;
  Activity? get currentActivity => _currentActivity;

  Future<void> loadActivities() async {
    try {
      _activities = await DatabaseService.instance.readAllActivities();
      notifyListeners();
    } catch (e) {
      print('Error loading activities: $e');
      _activities = [];
      notifyListeners();
    }
  }

  Future<void> addActivity(Activity activity) async {
    final newActivity = await DatabaseService.instance.create(activity);
    _activities.insert(0, newActivity);
    _currentActivity = newActivity; // Set as current activity when adding
    notifyListeners();
  }

  Future<void> updateActivity(Activity activity) async {
    await DatabaseService.instance.update(activity);
    final index = _activities.indexWhere((a) => a.id == activity.id);
    if (index != -1) {
      _activities[index] = activity;
      if (_currentActivity?.id == activity.id) {
        _currentActivity = activity;
      }
      notifyListeners();
    }
  }

  Future<void> deleteActivity(int id) async {
    await DatabaseService.instance.delete(id);
    _activities.removeWhere((activity) => activity.id == id);
    if (_currentActivity?.id == id) {
      _currentActivity = null;
    }
    notifyListeners();
  }

  void startActivity(Activity activity) {
    _currentActivity = activity;
    notifyListeners();
  }

  Future<void> stopCurrentActivity() async {
    if (_currentActivity != null && _currentActivity!.endTime == null) {
      final stoppedActivity = _currentActivity!.copyWith(
        endTime: DateTime.now(),
      );
      await updateActivity(stoppedActivity);
      _currentActivity = null;
      notifyListeners();
    }
  }

  List<Activity> getActivitiesForDay(DateTime date) {
    return activities.where((activity) {
      return activity.startTime.year == date.year &&
          activity.startTime.month == date.month &&
          activity.startTime.day == date.day;
    }).toList();
  }

  Map<String, Duration> getCategoryDuration(List<Activity> activities) {
    final Map<String, Duration> categoryDurations = {};

    for (final activity in activities) {
      final category = activity.category;
      final duration = activity.endTime != null
          ? activity.endTime!.difference(activity.startTime)
          : Duration.zero;

      categoryDurations.update(
        category,
        (value) => value + duration,
        ifAbsent: () => duration,
      );
    }

    return categoryDurations;
  }
}
