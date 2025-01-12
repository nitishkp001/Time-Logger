import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/activity_provider.dart';
import '../models/activity.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedView = 'daily';
  late DateTime _selectedDate;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    setState(() {
      _isLoading = true;
    });
    
    await Provider.of<ActivityProvider>(context, listen: false).loadActivities();
    
    setState(() {
      _isLoading = false;
    });
  }

  List<Activity> _getActivitiesForPeriod(ActivityProvider provider) {
    switch (_selectedView) {
      case 'daily':
        return provider.activities.where((activity) {
          return activity.startTime.year == _selectedDate.year &&
              activity.startTime.month == _selectedDate.month &&
              activity.startTime.day == _selectedDate.day &&
              activity.endTime != null;
        }).toList();
      case 'weekly':
        final startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return provider.activities.where((activity) {
          return activity.startTime.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
              activity.startTime.isBefore(endOfWeek.add(const Duration(days: 1))) &&
              activity.endTime != null;
        }).toList();
      case 'monthly':
        return provider.activities.where((activity) {
          return activity.startTime.year == _selectedDate.year &&
              activity.startTime.month == _selectedDate.month &&
              activity.endTime != null;
        }).toList();
      default:
        return [];
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '$hours h ${minutes.toString().padLeft(2, '0')} m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () {
                          setState(() {
                            switch (_selectedView) {
                              case 'daily':
                                _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                                break;
                              case 'weekly':
                                _selectedDate = _selectedDate.subtract(const Duration(days: 7));
                                break;
                              case 'monthly':
                                _selectedDate = DateTime(
                                    _selectedDate.year, _selectedDate.month - 1, _selectedDate.day);
                                break;
                            }
                          });
                        },
                      ),
                      Column(
                        children: [
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'daily', label: Text('Daily')),
                              ButtonSegment(value: 'weekly', label: Text('Weekly')),
                              ButtonSegment(value: 'monthly', label: Text('Monthly')),
                            ],
                            selected: {_selectedView},
                            onSelectionChanged: (Set<String> newSelection) {
                              setState(() {
                                _selectedView = newSelection.first;
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getDisplayDate(),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () {
                          setState(() {
                            switch (_selectedView) {
                              case 'daily':
                                _selectedDate = _selectedDate.add(const Duration(days: 1));
                                break;
                              case 'weekly':
                                _selectedDate = _selectedDate.add(const Duration(days: 7));
                                break;
                              case 'monthly':
                                _selectedDate = DateTime(
                                    _selectedDate.year, _selectedDate.month + 1, _selectedDate.day);
                                break;
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Consumer<ActivityProvider>(
                    builder: (context, activityProvider, child) {
                      final activities = _getActivitiesForPeriod(activityProvider);
                      if (activities.isEmpty) {
                        return const Center(
                          child: Text('No activities for this period'),
                        );
                      }

                      final categoryDurations = activityProvider.getCategoryDuration(activities);
                      final totalDuration = categoryDurations.values.fold<Duration>(
                          Duration.zero, (prev, curr) => prev + curr);

                      if (totalDuration.inMinutes == 0) {
                        return const Center(
                          child: Text('No completed activities for this period'),
                        );
                      }

                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 300,
                              child: PieChart(
                                PieChartData(
                                  sections: categoryDurations.entries.map((entry) {
                                    final category = entry.key;
                                    final duration = entry.value;
                                    if (duration.inMinutes == 0) {
                                      return PieChartSectionData(
                                        color: Colors.transparent,
                                        value: 0,
                                        title: '',
                                        radius: 150,
                                        showTitle: false,
                                      );
                                    }
                                    final percentage =
                                        (duration.inMinutes / totalDuration.inMinutes) * 100;
                                    return PieChartSectionData(
                                      color: _getCategoryColor(category),
                                      value: percentage,
                                      title: percentage >= 5 ? '${percentage.toStringAsFixed(1)}%' : '',
                                      radius: 150,
                                      titleStyle: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    );
                                  }).toList(),
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 40,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Total Time: ${_formatDuration(totalDuration)}',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: categoryDurations.length,
                              itemBuilder: (context, index) {
                                final category = categoryDurations.keys.elementAt(index);
                                final duration = categoryDurations[category]!;
                                final percentage =
                                    (duration.inMinutes / totalDuration.inMinutes) * 100;
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: _getCategoryColor(category),
                                    child: Text(
                                      category[0],
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  title: Text(category),
                                  subtitle: Text(_formatDuration(duration)),
                                  trailing: Text(
                                    '${percentage.toStringAsFixed(1)}%',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  String _getDisplayDate() {
    switch (_selectedView) {
      case 'daily':
        return DateFormat('MMM dd, yyyy').format(_selectedDate);
      case 'weekly':
        final startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return '${DateFormat('MMM dd').format(startOfWeek)} - ${DateFormat('MMM dd').format(endOfWeek)}';
      case 'monthly':
        return DateFormat('MMMM yyyy').format(_selectedDate);
      default:
        return '';
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'work':
        return Colors.blue;
      case 'exercise':
        return Colors.green;
      case 'study':
        return Colors.orange;
      case 'leisure':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
