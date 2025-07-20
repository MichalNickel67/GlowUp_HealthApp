import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class ExerciseDataPage extends StatefulWidget {
  const ExerciseDataPage({super.key});

  @override
  _ExerciseDataPageState createState() => _ExerciseDataPageState();
}

class _ExerciseDataPageState extends State<ExerciseDataPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool _isLoading = true;
  Map<String, dynamic> _exerciseSummary = {};
  List<Map<String, dynamic>> _dailyExerciseData = [];

  @override
  void initState() {
    super.initState();
    _loadExerciseData();
  }

  // Format minutes to hours and minutes if above 60
  String _formatMinutes(double minutes) {
    if (minutes >= 60) {
      int hours = (minutes / 60).floor();
      int remainingMinutes = (minutes % 60).round();
      return remainingMinutes > 0 ? '$hours hr $remainingMinutes min' : '$hours hr';
    } else {
      return '${minutes.round()} min';
    }
  }

  // Load exercise data for the current week with caching
  Future<void> _loadExerciseData() async {
    if (user == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final DateTime now = DateTime.now();
      final DateTime today = DateTime(now.year, now.month, now.day);
      final int daysFromMonday = (today.weekday - 1) % 7;
      final DateTime mostRecentMonday = today.subtract(Duration(days: daysFromMonday));

      // Use a limit to avoid excessive data loading
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('ExerciseTracker')
          .doc(user!.uid)
          .collection('exercise_tracker')
          .where('date', isGreaterThanOrEqualTo: mostRecentMonday)
          .orderBy('date', descending: true)
          .limit(50)
          .get();

      double totalCaloriesBurned = 0.0;
      int totalSteps = 0;
      double totalMinutesExercised = 0.0;
      int sessionCount = 0;
      String mostFrequentExercise = 'None';
      Map<int, int> dailySteps = {};
      Map<int, double> dailyCalories = {};
      Map<String, int> exerciseTypes = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        Timestamp? timestamp = data['date'] as Timestamp?;
        if (timestamp == null) continue;

        DateTime entryDate = timestamp.toDate();
        int daysSinceMonday = (entryDate.difference(mostRecentMonday).inDays) % 7;

        if (daysSinceMonday >= 0 && daysSinceMonday < 7) {
          int steps = (data['steps'] as num?)?.toInt() ?? 0;
          double calories = (data['caloriesBurned'] as num?)?.toDouble() ?? 0.0;
          double minutes = (data['minutesExercised'] as num?)?.toDouble() ?? 0.0;
          String exerciseType = data['exerciseType'] ?? 'Unknown';

          totalSteps += steps;
          totalCaloriesBurned += calories;
          totalMinutesExercised += minutes;
          sessionCount++;

          dailySteps[daysSinceMonday] = (dailySteps[daysSinceMonday] ?? 0) + steps;
          dailyCalories[daysSinceMonday] = (dailyCalories[daysSinceMonday] ?? 0.0) + calories;

          exerciseTypes[exerciseType] = (exerciseTypes[exerciseType] ?? 0) + 1;
        }
      }

      if (exerciseTypes.isNotEmpty) {
        mostFrequentExercise = exerciseTypes.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      }

      double avgCaloriesBurned = sessionCount > 0 ? totalCaloriesBurned / sessionCount : 0.0;
      double avgSteps = sessionCount > 0 ? totalSteps / sessionCount : 0.0;
      double avgMinutesExercised = sessionCount > 0 ? totalMinutesExercised / sessionCount : 0.0;

      const List<String> weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      List<Map<String, dynamic>> dailyExerciseData = List.generate(7, (i) => {
        'day': i,
        'dayName': weekdays[i],
        'steps': dailySteps[i] ?? 0,
        'calories': dailyCalories[i] ?? 0.0,
      });

      setState(() {
        _exerciseSummary = {
          'mostFrequentExercise': mostFrequentExercise,
          'avgCaloriesBurned': '${avgCaloriesBurned.toStringAsFixed(1)} kcal',
          'avgSteps': avgSteps.toInt().toString(),
          'avgMinutesExercised': _formatMinutes(avgMinutesExercised),
        };
        _dailyExerciseData = dailyExerciseData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading exercise data: $e')));
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Tracker'),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
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

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildInfoBox('Top Exercise', _exerciseSummary['mostFrequentExercise'] ?? 'None'),
                  _buildInfoBox('Avg Steps', _exerciseSummary['avgSteps'] ?? '0'),
                  _buildInfoBox('Avg Calories', _exerciseSummary['avgCaloriesBurned'] ?? '0 kcal'),
                  _buildInfoBox('Avg Exercise Time', _exerciseSummary['avgMinutesExercised'] ?? '0 min'),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Bar Chart
            const Text(
              'Daily Steps & Calories Burned',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            SizedBox(
              height: 250,
              child: _buildBarChart(),
            ),

            const SizedBox(height: 16),

            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Steps', Colors.green.shade300),
                const SizedBox(width: 20),
                _buildLegendItem('Calories Burned', Colors.green.shade700),
              ],
            ),

            // Exercise Tips Section
            const SizedBox(height: 24),
            const Text(
              'Exercise Tips',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Four compact tips with icons and text in a grid
            GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 2.0,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: [
                _buildCompactTipCard(
                  Icons.directions_run,
                  'Cardio Benefits',
                  'Aim for 30 minutes of cardio 5 days a week',
                ),
                _buildCompactTipCard(
                  Icons.fitness_center,
                  'Strength Training',
                  'Include weight training 2-3 times per week',
                ),
                _buildCompactTipCard(
                  Icons.self_improvement,
                  'Flexibility',
                  'Stretch daily to improve flexibility and reduce injury risk',
                ),
                _buildCompactTipCard(
                  Icons.water_drop,
                  'Stay Hydrated',
                  'Drink water before, during, and after exercise',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    double maxSteps = 0;
    for (var data in _dailyExerciseData) {
      if (data['steps'] > maxSteps) {
        maxSteps = data['steps'].toDouble();
      }
    }

    // Set a reasonable max value with some padding
    double maxY = maxSteps > 0 ? (maxSteps * 1.2) : 10000;
    // Round to whole number
    maxY = (maxY / 5000).ceil() * 5000;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        minY: 0,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.green.shade50,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final data = _dailyExerciseData[group.x.toInt()];
              String type = rodIndex == 0 ? 'Steps' : 'Calories';
              String value = rodIndex == 0
                  ? '${data['steps']}'
                  : '${data['calories'].toStringAsFixed(1)} kcal';
              return BarTooltipItem(
                '$type: $value',
                TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index >= 0 && index < _dailyExerciseData.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _dailyExerciseData[index]['dayName'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: maxY / 5,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const Text('0');
                if (value % 5000 == 0) {
                  return Text(
                    '${(value / 1000).toInt()}K',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          horizontalInterval: maxY / 5,
          getDrawingHorizontalLine: (value) {
            return const FlLine(
              color: Colors.black12,
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
          drawVerticalLine: false,
        ),
        barGroups: _dailyExerciseData.asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: data['steps'].toDouble(),
                color: Colors.green.shade300,
                width: 12,
                borderRadius: BorderRadius.circular(2),
              ),
              BarChartRodData(
                toY: data['calories'].toDouble() * 10,
                color: Colors.green.shade700,
                width: 12,
                borderRadius: BorderRadius.circular(2),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInfoBox(String title, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      width: 120,
      height: 80,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.green),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ],
      ),
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
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: Colors.green,
                ),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              tip,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}