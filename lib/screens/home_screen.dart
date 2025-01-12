import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/activity_provider.dart';
import '../models/activity.dart';
import 'analytics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedCategory = 'Work';

  final List<String> _categories = ['Work', 'Exercise', 'Study', 'Leisure', 'Other'];

  @override
  void initState() {
    super.initState();
    // Load activities when the screen initializes
    Future.microtask(() =>
        Provider.of<ActivityProvider>(context, listen: false).loadActivities());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _startNewActivity() {
    if (_formKey.currentState!.validate()) {
      final activity = Activity(
        title: _titleController.text,
        startTime: DateTime.now(),
        category: _selectedCategory,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      Provider.of<ActivityProvider>(context, listen: false).addActivity(activity);
      
      _titleController.clear();
      _notesController.clear();
      Navigator.pop(context);
    }
  }

  void _showAddActivityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start New Activity'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Activity Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an activity title';
                  }
                  return null;
                },
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
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes (Optional)'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _startNewActivity,
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Time Logger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.insights),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AnalyticsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<ActivityProvider>(
        builder: (context, activityProvider, child) {
          final activities = activityProvider.activities;
          final currentActivity = activityProvider.currentActivity;
          
          if (activities.isEmpty) {
            return const Center(
              child: Text('No activities recorded yet'),
            );
          }

          return ListView.builder(
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index];
              final isOngoing = currentActivity?.id == activity.id && activity.endTime == null;
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(
                    activity.title,
                    style: TextStyle(
                      fontWeight: isOngoing ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(activity.category),
                      Text('Started: ${_formatDateTime(activity.startTime)}'),
                      if (activity.endTime != null)
                        Text('Ended: ${_formatDateTime(activity.endTime!)}'),
                      if (activity.notes?.isNotEmpty == true)
                        Text('Notes: ${activity.notes}'),
                    ],
                  ),
                  trailing: isOngoing
                      ? ElevatedButton(
                          onPressed: () {
                            Provider.of<ActivityProvider>(context, listen: false)
                                .stopCurrentActivity();
                          },
                          child: const Text('Stop'),
                        )
                      : null,
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Consumer<ActivityProvider>(
        builder: (context, activityProvider, child) {
          return FloatingActionButton(
            onPressed: activityProvider.currentActivity == null
                ? _showAddActivityDialog
                : null,
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
