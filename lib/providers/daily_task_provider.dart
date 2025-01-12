import 'package:flutter/foundation.dart';
import '../models/daily_task.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class DailyTaskProvider with ChangeNotifier {
  List<DailyTask> _tasks = [];
  
  List<DailyTask> get tasks => _tasks;
  List<DailyTask> get incompleteTasks => _tasks.where((task) => !task.isCompleted).toList();
  List<DailyTask> get completedTasks => _tasks.where((task) => task.isCompleted).toList();

  Future<void> loadTasks() async {
    _tasks = await DatabaseService.instance.readAllDailyTasks();
    notifyListeners();
  }

  Future<void> addTask(DailyTask task) async {
    final newTask = await DatabaseService.instance.createDailyTask(task);
    _tasks.add(newTask);
    
    if (task.reminderEnabled) {
      await NotificationService.instance.scheduleDailyTaskReminder(
        newTask.id!,
        'Daily Task Reminder',
        'Remember to ${newTask.title}',
      );
    }
    
    notifyListeners();
  }

  Future<void> updateTask(DailyTask task) async {
    await DatabaseService.instance.updateDailyTask(task);
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
      
      if (task.reminderEnabled) {
        await NotificationService.instance.scheduleDailyTaskReminder(
          task.id!,
          'Daily Task Reminder',
          'Remember to ${task.title}',
        );
      } else {
        await NotificationService.instance.cancelNotification(task.id!);
      }
      
      notifyListeners();
    }
  }

  Future<void> deleteTask(int id) async {
    await DatabaseService.instance.deleteDailyTask(id);
    _tasks.removeWhere((task) => task.id == id);
    await NotificationService.instance.cancelNotification(id);
    notifyListeners();
  }

  Future<void> toggleTaskCompletion(DailyTask task) async {
    final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
    await updateTask(updatedTask);
  }

  Future<void> resetDailyTasks() async {
    await DatabaseService.instance.resetDailyTasks();
    await loadTasks();
  }
}
