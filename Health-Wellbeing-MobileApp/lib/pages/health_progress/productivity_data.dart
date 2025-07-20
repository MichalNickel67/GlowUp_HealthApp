import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class ProductivityDataPage extends StatefulWidget {
  const ProductivityDataPage({super.key});

  @override
  _ProductivityDataPageState createState() => _ProductivityDataPageState();
}

class _ProductivityDataPageState extends State<ProductivityDataPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool _isLoading = true;
  Map<String, dynamic> _productivitySummary = {};
  List<Map<String, dynamic>> _dailyTaskData = [];

  @override
  void initState() {
    super.initState();
    _loadProductivityData();
  }

  // Format number to remove trailing zeros and add "out of 5"
  String _formatRating(double number) {
    if (number == number.roundToDouble()) {
      return "${number.toInt()}/5"; // Return as integer if it's a whole number
    } else {
      return "${number.toStringAsFixed(1)}/5"; // Keep one decimal place
    }
  }

  // Format minutes to hours and minutes if above 60
  String _formatMinutes(double minutes) {
    if (minutes >= 60) {
      int hours = (minutes / 60).floor();
      int remainingMinutes = (minutes % 60).round();
      if (remainingMinutes > 0) {
        return '$hours hr $remainingMinutes min';
      } else {
        return '$hours hr';
      }
    } else {
      return '${minutes.round()} min';
    }
  }

  // Load productivity data for the current week
  Future<void> _loadProductivityData() async {
    if (user == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final DateTime now = DateTime.now();
      final DateTime today = DateTime(now.year, now.month, now.day);

      // Calculate the start of the current week (Monday)
      final int daysFromMonday = (today.weekday - 1) % 7;
      final DateTime currentWeekMonday = today.subtract(Duration(days: daysFromMonday));

      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('ProductivityTracker')
          .doc(user!.uid)
          .collection('productivity_logs')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(currentWeekMonday))
          .orderBy('date', descending: true)
          .get();

      double totalFocusedMinutes = 0.0;
      double totalDistractionLevel = 0.0;
      double totalProductivityRating = 0.0;
      int sessionCount = 0;
      Map<int, int> dailyTasksCompleted = {};
      Map<int, double> dailyProductivityRating = {};
      Map<String, int> activityCounts = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;

        Timestamp? timestamp = data['date'] as Timestamp?;
        if (timestamp == null) continue;

        DateTime entryDate = timestamp.toDate();
        // Only consider data from the current week
        if (entryDate.isAfter(currentWeekMonday.subtract(const Duration(seconds: 1)))) {
          double focusedMinutes = (data['focusedMinutes'] as num?)?.toDouble() ?? 0.0;
          double distractionLevel = (data['distractionLevel'] as num?)?.toDouble() ?? 0.0;
          double productivityRating = (data['productivityRating'] as num?)?.toDouble() ?? 0.0;
          int tasksCompleted = (data['tasksCompleted'] as num?)?.toInt() ?? 0;
          String mainActivity = data['mainActivity'] ?? 'Unknown';

          // Track session data
          totalFocusedMinutes += focusedMinutes;
          totalDistractionLevel += distractionLevel;
          totalProductivityRating += productivityRating;
          sessionCount++;

          // Count main activities
          if (!activityCounts.containsKey(mainActivity)) {
            activityCounts[mainActivity] = 0;
          }
          activityCounts[mainActivity] = (activityCounts[mainActivity] ?? 0) + 1;

          // Track daily tasks completed
          // Calculate which day of the week this data point belongs to (0 = Monday, 6 = Sunday)
          int daysSinceMonday = entryDate.difference(currentWeekMonday).inDays;
          if (daysSinceMonday >= 0 && daysSinceMonday < 7) {
            dailyTasksCompleted[daysSinceMonday] = (dailyTasksCompleted[daysSinceMonday] ?? 0) + tasksCompleted;
            // Store productivity rating by day too
            dailyProductivityRating[daysSinceMonday] = productivityRating;
          }
        }
      }

      // Find the top activity type
      String topActivity = 'No activity';
      if (activityCounts.isNotEmpty) {
        topActivity = activityCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      }

      // Calculate averages
      double avgFocusedMinutes = sessionCount > 0 ? totalFocusedMinutes / sessionCount : 0.0;
      double avgDistractionLevel = sessionCount > 0 ? totalDistractionLevel / sessionCount : 0.0;
      double avgProductivityRating = sessionCount > 0 ? totalProductivityRating / sessionCount : 0.0;

      // Prepare task data for the chart
      List<Map<String, dynamic>> dailyTaskData = [];
      const List<String> weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

      for (int i = 0; i < 7; i++) {
        dailyTaskData.add({
          'day': i, // 0 = Monday, 6 = Sunday
          'dayName': weekdays[i],
          'tasksCompleted': dailyTasksCompleted[i] ?? 0,
          'productivityRating': dailyProductivityRating[i] ?? 0.0,
        });
      }

      setState(() {
        _productivitySummary = {
          'topActivity': topActivity,
          'avgFocusedMinutes': avgFocusedMinutes,
          'avgDistractionLevel': _formatRating(avgDistractionLevel),
          'avgProductivityRating': _formatRating(avgProductivityRating),
        };
        _dailyTaskData = dailyTaskData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading productivity data: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Productivity Tracker'),
        backgroundColor: Colors.orange,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title showing today's date
            Center(
              child: Text(
                'Today: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),

            // Info Boxes for Productivity Data with Horizontal Scrolling
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildInfoBox('Top Activity', _productivitySummary['topActivity'] ?? 'N/A'),
                  _buildInfoBox(
                      'Avg Focused Time',
                      _formatMinutes(_productivitySummary['avgFocusedMinutes'] ?? 0.0)
                  ),
                  _buildInfoBox('Avg Distraction Level', _productivitySummary['avgDistractionLevel'] ?? '0/5'),
                  _buildInfoBox('Avg Productivity Rating', _productivitySummary['avgProductivityRating'] ?? '0/5'),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Chart Title
            const Text(
              'Tasks Completed & Productivity Rating',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Bar Chart for Tasks Completed Per Day
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(
                    show: true,
                    horizontalInterval: 1,
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          return Text(value.toInt().toString());
                        },
                        reservedSize: 30,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          if (index >= 0 && index < _dailyTaskData.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(_dailyTaskData[index]['dayName']),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 30,
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  barGroups: List.generate(_dailyTaskData.length, (index) {
                    final data = _dailyTaskData[index];
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: data['tasksCompleted'].toDouble(),
                          color: Colors.orange.shade300,
                          width: 12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        BarChartRodData(
                          toY: data['productivityRating'],
                          color: Colors.orange.shade700,
                          width: 12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ],
                    );
                  }),
                  maxY: (_dailyTaskData.isNotEmpty)
                      ? (_dailyTaskData.map((e) => (e['tasksCompleted'] as int).toDouble()).reduce((a, b) => a > b ? a : b) * 1.2).clamp(5.0, 10.0)
                      : 5.0,
                  minY: 0,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: Colors.orange.shade50,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final data = _dailyTaskData[group.x.toInt()];
                        String type = rodIndex == 0 ? 'Tasks' : 'Rating';
                        String value = rod.toY.toStringAsFixed(1);
                        return BarTooltipItem(
                          '$type: $value',
                          TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Tasks Completed', Colors.orange.shade300),
                const SizedBox(width: 20),
                _buildLegendItem('Productivity Rating', Colors.orange.shade700),
              ],
            ),

            // Productivity Tips Section
            const SizedBox(height: 24),
            const Text(
              'Productivity Tips',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildCompactTipCard(
                    Icons.timer,
                    'Pomodoro Technique',
                    'Work for 25 min, break for 5 min',
                  );
                } else if (index == 1) {
                  return _buildCompactTipCard(
                    Icons.calendar_today,
                    'Time Blocking',
                    'Schedule focused work blocks',
                  );
                } else if (index == 2) {
                  return _buildCompactTipCard(
                    Icons.notifications_off,
                    'Minimise Distractions',
                    'Turn off notifications when focusing',
                  );
                } else {
                  return _buildCompactTipCard(
                    Icons.task_alt,
                    'Task Prioritisation',
                    'Important tasks before urgent ones',
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox(String title, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.orange),
      ),
      child: Column(children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), Text(value)]),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }

  Widget _buildCompactTipCard(IconData icon, String title, String tip) {
    return Card(
      elevation: 2,
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: Colors.orange,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              tip,
              style: const TextStyle(fontSize: 11),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}