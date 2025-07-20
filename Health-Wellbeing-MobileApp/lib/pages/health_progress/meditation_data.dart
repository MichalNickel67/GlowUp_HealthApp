import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class MeditationDataPage extends StatefulWidget {
  const MeditationDataPage({super.key});

  @override
  _MeditationDataPageState createState() => _MeditationDataPageState();
}

class _MeditationDataPageState extends State<MeditationDataPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool _isLoading = true;
  Map<String, dynamic> _meditationSummary = {};
  List<Map<String, dynamic>> _dailyFocusData = [];

  @override
  void initState() {
    super.initState();
    _loadMeditationData();
  }

  // Format number
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

  // Load meditation data for the current week
  Future<void> _loadMeditationData() async {
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
          .collection('MeditationTracker')
          .doc(user!.uid)
          .collection('meditation_tracker')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(currentWeekMonday))
          .orderBy('date', descending: true)
          .get();

      double totalDuration = 0.0;
      double totalMoodImprovement = 0.0;
      double totalFocus = 0.0;
      int sessionCount = 0;

      // Maps to store daily data with session counts for averaging
      Map<int, double> dailyFocusSum = {};
      Map<int, int> dailyFocusCount = {};
      Map<int, double> dailyMoodSum = {};
      Map<int, int> dailyMoodCount = {};
      Map<String, int> meditationTypeCounts = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;

        Timestamp? timestamp = data['date'] as Timestamp?;
        if (timestamp == null) continue;

        DateTime entryDate = timestamp.toDate();

        // Only process entries from the current week
        if (entryDate.isAfter(currentWeekMonday.subtract(const Duration(days: 1)))) {
          double duration = (data['duration'] as num?)?.toDouble() ?? 0.0;
          double focus = (data['focus'] as num?)?.toDouble() ?? 0.0;
          double moodImprovement = (data['moodImprovement'] as num?)?.toDouble() ?? 0.0;
          String meditationType = data['meditationType'] ?? 'Unknown';

          // Track session data
          totalDuration += duration;
          totalMoodImprovement += moodImprovement;
          totalFocus += focus;
          sessionCount++;

          // Count meditation types
          if (!meditationTypeCounts.containsKey(meditationType)) {
            meditationTypeCounts[meditationType] = 0;
          }
          meditationTypeCounts[meditationType] = (meditationTypeCounts[meditationType] ?? 0) + 1;

          // Calculate which day of the week this data point belongs to (0 = Monday, 6 = Sunday)
          int daysSinceMonday = (entryDate.difference(currentWeekMonday).inDays) % 7;

          // Add to daily sums and increment count for averaging
          dailyFocusSum[daysSinceMonday] = (dailyFocusSum[daysSinceMonday] ?? 0.0) + focus;
          dailyFocusCount[daysSinceMonday] = (dailyFocusCount[daysSinceMonday] ?? 0) + 1;

          dailyMoodSum[daysSinceMonday] = (dailyMoodSum[daysSinceMonday] ?? 0.0) + moodImprovement;
          dailyMoodCount[daysSinceMonday] = (dailyMoodCount[daysSinceMonday] ?? 0) + 1;
        }
      }

      // Find the top meditation type
      String topMeditationType = 'No sessions';
      if (meditationTypeCounts.isNotEmpty) {
        topMeditationType = meditationTypeCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      }

      // Calculate averages
      double avgDuration = sessionCount > 0 ? totalDuration / sessionCount : 0.0;
      double avgMoodImprovement = sessionCount > 0 ? totalMoodImprovement / sessionCount : 0.0;
      double avgFocus = sessionCount > 0 ? totalFocus / sessionCount : 0.0;

      // Prepare focus data for the chart using averages
      List<Map<String, dynamic>> dailyFocusData = [];
      const List<String> weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

      for (int i = 0; i < 7; i++) {
        // Calculate daily averages instead of sums
        double avgDailyFocus = dailyFocusCount[i] != null && dailyFocusCount[i]! > 0
            ? dailyFocusSum[i]! / dailyFocusCount[i]!
            : 0.0;

        double avgDailyMood = dailyMoodCount[i] != null && dailyMoodCount[i]! > 0
            ? dailyMoodSum[i]! / dailyMoodCount[i]!
            : 0.0;

        dailyFocusData.add({
          'day': i, // 0 = Monday, 6 = Sunday
          'dayName': weekdays[i],
          'focus': avgDailyFocus,
          'mood': avgDailyMood,
        });
      }

      setState(() {
        _meditationSummary = {
          'topMeditationType': topMeditationType,
          'avgDuration': avgDuration,
          'avgMoodImprovement': _formatRating(avgMoodImprovement),
          'avgFocus': _formatRating(avgFocus),
        };
        _dailyFocusData = dailyFocusData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading meditation data: $e')));
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meditation Tracker'),
        backgroundColor: Colors.purple,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.purple))
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

            // Info Boxes for Meditation Data with Horizontal Scrolling
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildInfoBox('Top Meditation Type', _meditationSummary['topMeditationType'] ?? 'N/A'),
                  _buildInfoBox(
                      'Avg Session Duration',
                      _formatMinutes(_meditationSummary['avgDuration'] ?? 0.0)
                  ),
                  _buildInfoBox('Avg Mood Improvement', _meditationSummary['avgMoodImprovement'] ?? '0/5'),
                  _buildInfoBox('Avg Focus Rating', _meditationSummary['avgFocus'] ?? '0/5'),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Chart Title
            const Text(
              'Focus & Mood Improvement',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Bar Chart for Focus and Mood Per Day
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
                          if (index >= 0 && index < _dailyFocusData.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(_dailyFocusData[index]['dayName']),
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
                  barGroups: List.generate(_dailyFocusData.length, (index) {
                    final data = _dailyFocusData[index];
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: data['focus'],
                          color: Colors.purple.shade300,
                          width: 12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        BarChartRodData(
                          toY: data['mood'],
                          color: Colors.purple.shade700,
                          width: 12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ],
                    );
                  }),
                  maxY: 5.0,
                  minY: 0,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: Colors.purple.shade50,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final data = _dailyFocusData[group.x.toInt()];
                        String type = rodIndex == 0 ? 'Focus' : 'Mood';
                        String value = rod.toY.toStringAsFixed(1);
                        return BarTooltipItem(
                          '$type: $value',
                          TextStyle(color: Colors.purple.shade800, fontWeight: FontWeight.bold),
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
                _buildLegendItem('Focus Rating', Colors.purple.shade300),
                const SizedBox(width: 20),
                _buildLegendItem('Mood Improvement', Colors.purple.shade700),
              ],
            ),

            // Meditation Tips Section
            const SizedBox(height: 24),
            const Text(
              'Meditation Tips',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 2.0,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: [
                _buildCompactTipCard(
                  Icons.wb_sunny,
                  'Morning Meditation',
                  'Start your day with a short session to set a positive tone',
                ),
                _buildCompactTipCard(
                  Icons.air,
                  'Mindful Breathing',
                  'Focus on your breath to anchor yourself in the present moment',
                ),
                _buildCompactTipCard(
                  Icons.landscape,
                  'Nature Connection',
                  'Meditate outdoors to enhance calming effects',
                ),
                _buildCompactTipCard(
                  Icons.repeat,
                  'Consistency Is Key',
                  'Short daily sessions are more effective than occasional long ones',
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
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.purple),
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
      color: Colors.purple.shade50,
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
                  color: Colors.purple,
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