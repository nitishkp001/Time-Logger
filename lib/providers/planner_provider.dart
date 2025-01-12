import 'package:flutter/foundation.dart';
import '../models/planner_item.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class PlannerProvider with ChangeNotifier {
  List<PlannerItem> _items = [];
  
  List<PlannerItem> get items => _items;
  
  List<PlannerItem> getDailyItems(DateTime date) {
    return _items.where((item) {
      return item.type == 'daily' &&
          item.startDate.year == date.year &&
          item.startDate.month == date.month &&
          item.startDate.day == date.day;
    }).toList();
  }

  List<PlannerItem> getWeeklyItems(DateTime date) {
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    return _items.where((item) {
      return item.type == 'weekly' &&
          item.startDate.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
          item.startDate.isBefore(endOfWeek.add(const Duration(days: 1)));
    }).toList();
  }

  List<PlannerItem> getMonthlyItems(DateTime date) {
    return _items.where((item) {
      return item.type == 'monthly' &&
          item.startDate.year == date.year &&
          item.startDate.month == date.month;
    }).toList();
  }

  Future<void> loadItems() async {
    _items = await DatabaseService.instance.readAllPlannerItems();
    notifyListeners();
  }

  Future<void> addItem(PlannerItem item) async {
    final newItem = await DatabaseService.instance.createPlannerItem(item);
    _items.add(newItem);
    
    if (item.reminderEnabled) {
      await NotificationService.instance.scheduleDailyTaskReminder(
        newItem.id!,
        'Planner Reminder',
        '${newItem.title} (${newItem.type})',
      );
    }
    
    notifyListeners();
  }

  Future<void> updateItem(PlannerItem item) async {
    await DatabaseService.instance.updatePlannerItem(item);
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _items[index] = item;
      
      if (item.reminderEnabled) {
        await NotificationService.instance.scheduleDailyTaskReminder(
          item.id!,
          'Planner Reminder',
          '${item.title} (${item.type})',
        );
      } else {
        await NotificationService.instance.cancelNotification(item.id!);
      }
      
      notifyListeners();
    }
  }

  Future<void> deleteItem(int id) async {
    await DatabaseService.instance.deletePlannerItem(id);
    _items.removeWhere((item) => item.id == id);
    await NotificationService.instance.cancelNotification(id);
    notifyListeners();
  }

  Future<void> toggleItemCompletion(PlannerItem item) async {
    final updatedItem = item.copyWith(isCompleted: !item.isCompleted);
    await updateItem(updatedItem);
  }
}
