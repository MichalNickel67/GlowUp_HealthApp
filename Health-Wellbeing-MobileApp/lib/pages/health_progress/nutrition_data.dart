import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class NutritionDataPage extends StatefulWidget {
  const NutritionDataPage({super.key});

  @override
  _NutritionDataPageState createState() => _NutritionDataPageState();
}

class _NutritionDataPageState extends State<NutritionDataPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool _isLoading = true;
  Map<String, dynamic> _nutritionSummary = {};
  List<Map<String, dynamic>> _dailyNutritionData = [];
  late Stream<QuerySnapshot> _nutritionStream;

  @override
  void initState() {
    super.initState();
    _setupStream();
  }

  // Format liquid consumption to show in litres if appropriate
  String _formatLiquidConsumption(double milliliters) {
    if (milliliters >= 1000) {
      // Convert to litres and format with 2 decimal places
      return '${(milliliters / 1000).toStringAsFixed(2)} L';
    } else {
      // Keep as millilitres
      return '${milliliters.round()} ml';
    }
  }

  // Get weekday name for a given DateTime
  String _getWeekdayName(DateTime date) {
    final List<String> weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    // Adjust to make Monday index 0
    int index = (date.weekday - 1) % 7;
    return weekdays[index];
  }

  // Setup stream for automatic updates
  void _setupStream() {
    if (user == null) return;

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    // Get today's data for summary
    final Stream<QuerySnapshot> todayStream = FirebaseFirestore.instance
        .collection('NutritionTracker')
        .doc(user!.uid)
        .collection('entries')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
        .where('date', isLessThan: Timestamp.fromDate(today.add(const Duration(days: 1))))
        .snapshots();
    _nutritionStream = todayStream;
    _nutritionStream.listen(_processNutritionData);

    // Also load the weekly data for the chart
    _loadWeeklyChartData();
  }

  // Process nutrition data from stream
  void _processNutritionData(QuerySnapshot snapshot) {
    if (mounted) {
      double totalCalories = 0.0;
      double totalProtein = 0.0;
      double totalCarbohydrates = 0.0;
      double totalFats = 0.0;
      double totalLiquidConsumption = 0.0;

      // Process today's entries
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;

        double calories = (data['calories'] as num?)?.toDouble() ?? 0.0;
        double protein = (data['protein'] as num?)?.toDouble() ?? 0.0;
        double carbohydrates = (data['carbohydrates'] as num?)?.toDouble() ?? 0.0;
        double fats = (data['fats'] as num?)?.toDouble() ?? 0.0;

        // Convert liquid consumption from liters to millilitres if needed
        double liquidConsumption = (data['liquidConsumption'] as num?)?.toDouble() ?? 0.0;
        // Check if the value is likely in litres (less than 100)
        if (liquidConsumption < 100) {
          liquidConsumption *= 1000; // Convert to millilitres for consistent storage
        }

        totalCalories += calories;
        totalProtein += protein;
        totalCarbohydrates += carbohydrates;
        totalFats += fats;
        totalLiquidConsumption += liquidConsumption;
      }

      setState(() {
        _nutritionSummary = {
          'dailyCalories': totalCalories.round().toString(),
          'dailyProtein': totalProtein.round().toString(),
          'dailyCarbohydrates': totalCarbohydrates.round().toString(),
          'dailyFats': totalFats.round().toString(),
          'dailyLiquidIntake': _formatLiquidConsumption(totalLiquidConsumption),
        };
        _isLoading = false;
      });
    }
  }

  // Load weekly data for the chart
  Future<void> _loadWeeklyChartData() async {
    if (user == null) return;

    try {
      final DateTime now = DateTime.now();
      final DateTime today = DateTime(now.year, now.month, now.day);

      // Find Monday of the current week
      final DateTime startOfWeek = today.subtract(Duration(days: today.weekday - 1));

      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('NutritionTracker')
          .doc(user!.uid)
          .collection('entries')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
          .orderBy('date', descending: false)
          .get();

      // Initialise data structures
      Map<String, int> entryCounts = {};
      Map<String, double> nutritionalSums = {};
      Map<String, double> hydrationSums = {};

      // Process entries and calculate sums by day
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;

        Timestamp? timestamp = data['date'] as Timestamp?;
        if (timestamp == null) continue;

        DateTime entryDate = timestamp.toDate();
        DateTime dateKey = DateTime(entryDate.year, entryDate.month, entryDate.day);
        String dayName = _getWeekdayName(dateKey);

        // Check if this entry is within the current week
        if (dateKey.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
            dateKey.isBefore(startOfWeek.add(const Duration(days: 7)))) {

          double hydrationValue = (data['hydrationValue'] as num?)?.toDouble() ?? 0.0;
          double nutritionalValue = (data['nutritionalValue'] as num?)?.toDouble() ?? 0.0;

          // Update entry counts and sums for this day
          entryCounts[dayName] = (entryCounts[dayName] ?? 0) + 1;
          nutritionalSums[dayName] = (nutritionalSums[dayName] ?? 0.0) + nutritionalValue;
          hydrationSums[dayName] = (hydrationSums[dayName] ?? 0.0) + hydrationValue;
        }
      }

      // Calculate averages and prepare chart data
      List<Map<String, dynamic>> dailyData = [];
      final List<String> weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

      for (int i = 0; i < weekdays.length; i++) {
        String day = weekdays[i];
        int entries = entryCounts[day] ?? 0;

        // Calculate average values, defaulting to 0 if no entries
        double nutritionalAvg = entries > 0
            ? (nutritionalSums[day] ?? 0.0) / entries
            : 0.0;
        double hydrationAvg = entries > 0
            ? (hydrationSums[day] ?? 0.0) / entries
            : 0.0;

        // Ensure values don't exceed our scale
        nutritionalAvg = nutritionalAvg.clamp(0.0, 5.0);
        hydrationAvg = hydrationAvg.clamp(0.0, 5.0);

        // Add to chart data
        dailyData.add({
          'day': i,
          'dayName': day,
          'nutritionalValue': nutritionalAvg,
          'hydrationValue': hydrationAvg,
          'entries': entries,
        });
      }

      if (mounted) {
        setState(() {
          _dailyNutritionData = dailyData;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading weekly data: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition Tracker'),
        backgroundColor: Colors.red,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
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
            // Info Boxes for Nutrition Data with Horizontal Scrolling
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildInfoBox('Total Calories', '${_nutritionSummary['dailyCalories']} kcal'),
                  _buildInfoBox('Total Protein', '${_nutritionSummary['dailyProtein']} g'),
                  _buildInfoBox('Total Carbs', '${_nutritionSummary['dailyCarbohydrates']} g'),
                  _buildInfoBox('Total Fats', '${_nutritionSummary['dailyFats']} g'),
                  _buildInfoBox('Total Liquid', _nutritionSummary['dailyLiquidIntake']),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Chart Title
            const Text(
              'Average Nutritional & Hydration Values',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // Bar Chart for Nutrition and Hydration Values Per Day
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
                          if (index >= 0 && index < _dailyNutritionData.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(_dailyNutritionData[index]['dayName']),
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
                  barGroups: List.generate(_dailyNutritionData.length, (index) {
                    final data = _dailyNutritionData[index];
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: data['nutritionalValue'],
                          color: Colors.red.shade300,
                          width: 12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        BarChartRodData(
                          toY: data['hydrationValue'],
                          color: Colors.red.shade700,
                          width: 12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ],
                    );
                  }),
                  maxY: 5,
                  minY: 0,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: Colors.red.shade50,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final data = _dailyNutritionData[group.x.toInt()];
                        String type = rodIndex == 0 ? 'Nutritional' : 'Hydration';
                        String value = rod.toY.toStringAsFixed(1);
                        int entries = data['entries'];
                        return BarTooltipItem(
                          '$type: $value\nEntries: $entries',
                          const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
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
                _buildLegendItem('Nutritional Value', Colors.red.shade300),
                const SizedBox(width: 20),
                _buildLegendItem('Hydration Value', Colors.red.shade700),
              ],
            ),

            // Nutrition Tips Section
            const SizedBox(height: 24),
            const Text(
              'Nutrition Tips',
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
                  Icons.water_drop,
                  'Hydration',
                  'Drink 8 glasses of water daily',
                ),
                _buildCompactTipCard(
                  Icons.restaurant,
                  'Balanced Diet',
                  'Include protein, carbs & healthy fats in meals',
                ),
                _buildCompactTipCard(
                  Icons.access_time,
                  'Meal Timing',
                  'Eat smaller meals every 3-4 hours',
                ),
                _buildCompactTipCard(
                  Icons.local_florist,
                  'Plant Power',
                  'Fill half your plate with vegetables',
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
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.red),
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
      color: Colors.red.shade50,
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
                  color: Colors.red,
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