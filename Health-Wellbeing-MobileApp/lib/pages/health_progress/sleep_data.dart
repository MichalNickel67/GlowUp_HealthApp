import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class SleepDataPage extends StatefulWidget {
  const SleepDataPage({super.key});

  @override
  _SleepDataPageState createState() => _SleepDataPageState();
}

class _SleepDataPageState extends State<SleepDataPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool _isLoading = true;
  Map<String, dynamic> _sleepSummary = {};
  List<Map<String, dynamic>> _dailySleepData = [];

  @override
  void initState() {
    super.initState();
    _loadSleepData();
  }

  // Helper method to parse time string (HH:mm) into Duration
  Duration parseTime(String time) {
    try {
      final parts = time.split(':');
      final hours = int.tryParse(parts[0].trim()) ?? 0;
      final minutes = int.tryParse(parts[1].trim()) ?? 0;
      return Duration(hours: hours, minutes: minutes);
    } catch (e) {
      return Duration.zero;
    }
  }

  // Helper method to format Duration back into HH:mm format
  String formatDuration(Duration duration) {
    int hours = duration.inHours;
    int minutes = duration.inMinutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  // Format number to remove trailing zeros and add "out of 5"
  String _formatRating(double number) {
    if (number == number.roundToDouble()) {
      return "${number.toInt()}/5"; // Return as integer if it's a whole number
    } else {
      return "${number.toStringAsFixed(1)}/5"; // Keep one decimal place
    }
  }

  // Format minutes to hours and minutes
  String _formatHours(double hours) {
    if (hours >= 1) {
      int wholeHours = hours.floor();
      int minutes = ((hours - wholeHours) * 60).round();
      if (minutes > 0) {
        return '$wholeHours hr $minutes min';
      } else {
        return '$wholeHours hr';
      }
    } else {
      return '${(hours * 60).round()} min';
    }
  }

  // Load sleep data
  Future<void> _loadSleepData() async {
    if (user == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final DateTime now = DateTime.now();
      final DateTime today = DateTime(now.year, now.month, now.day);

      // Calculate the date of the current week's Monday
      final int daysFromMonday = (today.weekday - 1) % 7;
      final DateTime currentWeekMonday = today.subtract(Duration(days: daysFromMonday));

      // Get the start and end timestamps for the current week
      final Timestamp startOfWeek = Timestamp.fromDate(currentWeekMonday);
      final Timestamp endOfWeek = Timestamp.fromDate(currentWeekMonday.add(const Duration(days: 7, seconds: -1)));

      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('SleepTracker')
          .doc(user!.uid)
          .collection('sleep_tracker')
          .where('date', isGreaterThanOrEqualTo: startOfWeek)
          .where('date', isLessThanOrEqualTo: endOfWeek)
          .orderBy('date', descending: false)
          .get();

      double totalBedTimeMinutes = 0.0;
      double totalWakeTimeMinutes = 0.0;
      double totalDuration = 0.0;
      double totalQuality = 0.0;
      int count = 0;
      Map<int, Map<String, dynamic>> dailySleepMap = {};

      const List<String> weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;

        Timestamp? timestamp = data['date'] as Timestamp?;
        if (timestamp == null) continue;

        DateTime entryDate = timestamp.toDate();

        // Calculate which day of the week this data point belongs to (0 = Monday, 6 = Sunday)
        int daysSinceMonday = entryDate.difference(currentWeekMonday).inDays;

        if (daysSinceMonday >= 0 && daysSinceMonday < 7) {
          var bedTime = parseTime(data['bedTime'].toString());
          var wakeTime = parseTime(data['wakeTime'].toString());
          var durationMinutes = int.tryParse(data['durationMinutes'].toString()) ?? 0;
          double sleepQuality = (data['sleepQuality'] as num?)?.toDouble() ?? 0.0;

          totalBedTimeMinutes += bedTime.inMinutes.toDouble();
          totalWakeTimeMinutes += wakeTime.inMinutes.toDouble();
          totalDuration += durationMinutes / 60.0; // Convert minutes to hours
          totalQuality += sleepQuality;
          count++;

          dailySleepMap[daysSinceMonday] = {
            'day': daysSinceMonday,
            'dayName': weekdays[daysSinceMonday],
            'duration': durationMinutes / 60.0,
            'quality': sleepQuality,
          };
        }
      }

      // Calculate averages
      double avgBedTimeMinutes = count > 0 ? totalBedTimeMinutes / count : 0.0;
      double avgWakeTimeMinutes = count > 0 ? totalWakeTimeMinutes / count : 0.0;
      double avgDuration = count > 0 ? totalDuration / count : 0.0;
      double avgQuality = count > 0 ? totalQuality / count : 0.0;

      // Prepare daily sleep data for the chart
      List<Map<String, dynamic>> dailySleepData = [];

      for (int i = 0; i < 7; i++) {
        dailySleepData.add(
          dailySleepMap[i] ?? {
            'day': i,
            'dayName': weekdays[i],
            'duration': 0.0,
            'quality': 0.0,
          },
        );
      }

      setState(() {
        _sleepSummary = {
          'avgBedTime': count > 0 ? formatDuration(Duration(minutes: avgBedTimeMinutes.round())) : 'N/A',
          'avgWakeTime': count > 0 ? formatDuration(Duration(minutes: avgWakeTimeMinutes.round())) : 'N/A',
          'avgDuration': avgDuration,
          'avgQuality': count > 0 ? _formatRating(avgQuality) : '0/5',
        };
        _dailySleepData = dailySleepData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading sleep data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sleep Tracker'),
        backgroundColor: Colors.indigo,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
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

            // Info Boxes for Sleep Data with Horizontal Scrolling
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildInfoBox('Avg Bed Time', _sleepSummary['avgBedTime'] ?? 'N/A'),
                  _buildInfoBox('Avg Wake Time', _sleepSummary['avgWakeTime'] ?? 'N/A'),
                  _buildInfoBox('Avg Sleep Duration', _formatHours(_sleepSummary['avgDuration'] ?? 0.0)),
                  _buildInfoBox('Avg Sleep Quality', _sleepSummary['avgQuality'] ?? '0/5'),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Chart Title
            const Text(
              'Sleep Duration & Quality',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Bar Chart for Sleep Duration and Quality Per Day
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
                          if (index >= 0 && index < _dailySleepData.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(_dailySleepData[index]['dayName']),
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
                  barGroups: List.generate(_dailySleepData.length, (index) {
                    final data = _dailySleepData[index];
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: data['duration'],
                          color: Colors.indigo.shade300,
                          width: 12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        BarChartRodData(
                          toY: data['quality'],
                          color: Colors.indigo.shade700,
                          width: 12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ],
                    );
                  }),
                  maxY: (_dailySleepData.isNotEmpty && _dailySleepData.any((e) => (e['duration'] as double) > 0))
                      ? (_dailySleepData.map((e) => (e['duration'] as double)).reduce((a, b) => a > b ? a : b) * 1.2).clamp(5.0, 10.0)
                      : 8.0,
                  minY: 0,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: Colors.indigo.shade50,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final data = _dailySleepData[group.x.toInt()];
                        String type = rodIndex == 0 ? 'Hours' : 'Rating';
                        String value = rod.toY.toStringAsFixed(1);
                        return BarTooltipItem(
                          '$type: $value',
                          TextStyle(color: Colors.indigo.shade800, fontWeight: FontWeight.bold),
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
                _buildLegendItem('Sleep Duration (hours)', Colors.indigo.shade300),
                const SizedBox(width: 20),
                _buildLegendItem('Sleep Quality (rating)', Colors.indigo.shade700),
              ],
            ),

            // Sleep Tips Section
            const SizedBox(height: 16),
            const Text(
              'Sleep Tips',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              padding: EdgeInsets.zero,
              children: [
                _buildCompactTipCard(
                  Icons.bedtime,
                  'Consistent Schedule',
                  'Same bed/wake times daily',
                ),
                _buildCompactTipCard(
                  Icons.smartphone,
                  'Device-Free Time',
                  'No screens before bed',
                ),
                _buildCompactTipCard(
                  Icons.coffee,
                  'Watch Caffeine',
                  'Avoid 6h before sleep',
                ),
                _buildCompactTipCard(
                  Icons.dark_mode,
                  'Optimise Room',
                  'Dark, quiet, cool space',
                ),
              ],
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
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.indigo),
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
          color: color,),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }

  Widget _buildCompactTipCard(IconData icon, String title, String tip) {
    return Card(
      elevation: 2,
      color: Colors.indigo.shade50,
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
                  color: Colors.indigo,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
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