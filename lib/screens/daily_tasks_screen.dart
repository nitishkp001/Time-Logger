import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/daily_task.dart';
import '../providers/daily_task_provider.dart';

class DailyTasksScreen extends StatefulWidget {
  const DailyTasksScreen({super.key});

  @override
  State<DailyTasksScreen> createState() => _DailyTasksScreenState();
}

class _DailyTasksScreenState extends State<DailyTasksScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'Work';
  bool _reminderEnabled = true;

  final List<String> _categories = ['Work', 'Exercise', 'Study', 'Personal', 'Other'];

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<DailyTaskProvider>(context, listen: false).loadTasks());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Daily Task'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Task Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a task title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description (Optional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('8 AM Reminder'),
                value: _reminderEnabled,
                onChanged: (value) {
                  setState(() {
                    _reminderEnabled = value;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetForm();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _addTask,
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    _titleController.clear();
    _descriptionController.clear();
    _selectedCategory = 'Work';
    _reminderEnabled = true;
  }

  void _addTask() {
    if (_formKey.currentState!.validate()) {
      final task = DailyTask(
        title: _titleController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        category: _selectedCategory,
        reminderEnabled: _reminderEnabled,
      );

      Provider.of<DailyTaskProvider>(context, listen: false).addTask(task);
      
      Navigator.pop(context);
      _resetForm();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<DailyTaskProvider>(context, listen: false)
                  .resetDailyTasks();
            },
            tooltip: 'Reset all tasks',
          ),
        ],
      ),
      body: Consumer<DailyTaskProvider>(
        builder: (context, taskProvider, child) {
          final incompleteTasks = taskProvider.incompleteTasks;
          final completedTasks = taskProvider.completedTasks;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (incompleteTasks.isNotEmpty) ...[
                const Text(
                  'Pending Tasks',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...incompleteTasks.map((task) => _buildTaskTile(task)),
                const SizedBox(height: 16),
              ],
              if (completedTasks.isNotEmpty) ...[
                const Text(
                  'Completed Tasks',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...completedTasks.map((task) => _buildTaskTile(task)),
              ],
              if (incompleteTasks.isEmpty && completedTasks.isEmpty)
                const Center(
                  child: Text('No daily tasks added yet'),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTaskTile(DailyTask task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: (value) {
            Provider.of<DailyTaskProvider>(context, listen: false)
                .toggleTaskCompletion(task);
          },
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.category),
            if (task.description != null) Text(task.description!),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                task.reminderEnabled ? Icons.alarm_on : Icons.alarm_off,
                color: task.reminderEnabled ? Colors.blue : Colors.grey,
              ),
              onPressed: () {
                Provider.of<DailyTaskProvider>(context, listen: false)
                    .updateTask(task.copyWith(
                  reminderEnabled: !task.reminderEnabled,
                ));
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                Provider.of<DailyTaskProvider>(context, listen: false)
                    .deleteTask(task.id!);
              },
            ),
          ],
        ),
        isThreeLine: task.description != null,
      ),
    );
  }
}
