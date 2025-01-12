import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/planner_item.dart';
import '../providers/planner_provider.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedType = 'daily';
  String _selectedCategory = 'Work';
  int _selectedPriority = 1;
  bool _reminderEnabled = true;
  DateTime? _endDate;

  final List<String> _categories = ['Work', 'Personal', 'Study', 'Health', 'Other'];
  final Map<int, String> _priorities = {
    1: 'Low',
    2: 'Medium',
    3: 'High',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    Future.microtask(() =>
        Provider.of<PlannerProvider>(context, listen: false).loadItems());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Planner Item'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
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
                  value: _selectedType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: ['daily', 'weekly', 'monthly'].map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type[0].toUpperCase() + type.substring(1)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value!;
                    });
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
                DropdownButtonFormField<int>(
                  value: _selectedPriority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: _priorities.entries.map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPriority = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('End Date (Optional)'),
                  subtitle: Text(_endDate == null
                      ? 'Not set'
                      : DateFormat('MMM dd, yyyy').format(_endDate!)),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          _endDate = date;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Enable Reminder'),
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
            onPressed: _addItem,
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    _titleController.clear();
    _descriptionController.clear();
    _selectedType = 'daily';
    _selectedCategory = 'Work';
    _selectedPriority = 1;
    _reminderEnabled = true;
    _endDate = null;
  }

  void _addItem() {
    if (_formKey.currentState!.validate()) {
      final item = PlannerItem(
        title: _titleController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        startDate: DateTime.now(),
        endDate: _endDate,
        type: _selectedType,
        category: _selectedCategory,
        priority: _selectedPriority,
        reminderEnabled: _reminderEnabled,
      );

      Provider.of<PlannerProvider>(context, listen: false).addItem(item);
      
      Navigator.pop(context);
      _resetForm();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planner'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Daily'),
            Tab(text: 'Weekly'),
            Tab(text: 'Monthly'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      switch (_tabController.index) {
                        case 0:
                          _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                          break;
                        case 1:
                          _selectedDate = _selectedDate.subtract(const Duration(days: 7));
                          break;
                        case 2:
                          _selectedDate = DateTime(_selectedDate.year,
                              _selectedDate.month - 1, _selectedDate.day);
                          break;
                      }
                    });
                  },
                ),
                Text(
                  _getDisplayDate(),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      switch (_tabController.index) {
                        case 0:
                          _selectedDate = _selectedDate.add(const Duration(days: 1));
                          break;
                        case 1:
                          _selectedDate = _selectedDate.add(const Duration(days: 7));
                          break;
                        case 2:
                          _selectedDate = DateTime(_selectedDate.year,
                              _selectedDate.month + 1, _selectedDate.day);
                          break;
                      }
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPlannerList('daily'),
                _buildPlannerList('weekly'),
                _buildPlannerList('monthly'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  String _getDisplayDate() {
    switch (_tabController.index) {
      case 0:
        return DateFormat('MMM dd, yyyy').format(_selectedDate);
      case 1:
        final startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return '${DateFormat('MMM dd').format(startOfWeek)} - ${DateFormat('MMM dd').format(endOfWeek)}';
      case 2:
        return DateFormat('MMMM yyyy').format(_selectedDate);
      default:
        return '';
    }
  }

  Widget _buildPlannerList(String type) {
    return Consumer<PlannerProvider>(
      builder: (context, plannerProvider, child) {
        List<PlannerItem> items;
        switch (type) {
          case 'daily':
            items = plannerProvider.getDailyItems(_selectedDate);
            break;
          case 'weekly':
            items = plannerProvider.getWeeklyItems(_selectedDate);
            break;
          case 'monthly':
            items = plannerProvider.getMonthlyItems(_selectedDate);
            break;
          default:
            items = [];
        }

        if (items.isEmpty) {
          return const Center(
            child: Text('No items for this period'),
          );
        }

        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: Checkbox(
                  value: item.isCompleted,
                  onChanged: (value) {
                    Provider.of<PlannerProvider>(context, listen: false)
                        .toggleItemCompletion(item);
                  },
                ),
                title: Text(
                  item.title,
                  style: TextStyle(
                    decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                    fontWeight: item.priority == 3
                        ? FontWeight.bold
                        : item.priority == 2
                            ? FontWeight.w500
                            : FontWeight.normal,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.category),
                    if (item.description != null) Text(item.description!),
                    if (item.endDate != null)
                      Text('Due: ${DateFormat('MMM dd, yyyy').format(item.endDate!)}'),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.flag,
                      color: item.priority == 3
                          ? Colors.red
                          : item.priority == 2
                              ? Colors.orange
                              : Colors.green,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        Provider.of<PlannerProvider>(context, listen: false)
                            .deleteItem(item.id!);
                      },
                    ),
                  ],
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }
}
