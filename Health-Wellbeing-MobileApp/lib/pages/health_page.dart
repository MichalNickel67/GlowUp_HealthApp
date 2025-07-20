import 'package:flutter/material.dart';
import 'health_progress/exercise_data.dart';
import 'health_progress/meditation_data.dart';
import 'health_progress/nutrition_data.dart';
import 'health_progress/productivity_data.dart';
import 'health_progress/sleep_data.dart';

// HealthPage widget that displays health tracking categories and recommendations
class HealthPage extends StatefulWidget {
  const HealthPage({super.key});

  @override
  State<HealthPage> createState() => HealthPageState();
}

class HealthPageState extends State<HealthPage> {
  bool isLoading = false;
  bool hasErrors = false;
  String errorMessage = "";

  // Data containers for each category
  List<Map<String, dynamic>> nutritionData = [];
  List<Map<String, dynamic>> productivityData = [];
  List<Map<String, dynamic>> sleepData = [];
  List<Map<String, dynamic>> meditationData = [];
  List<Map<String, dynamic>> exerciseData = [];

  // Current selected category for recommendations
  String selectedCategory = "Sleep";

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "View Your Health Progress",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                image: const DecorationImage(
                  image: AssetImage("assets/images/happy.jpg"),
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Your Trackers",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 130,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _trackerItem(
                    "Sleep",
                    "assets/images/sleeptracker.png",
                    Colors.indigo,
                        () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SleepDataPage()),
                    ),
                  ),
                  _trackerItem(
                    "Exercise",
                    "assets/images/exercise.png",
                    Colors.green,
                        () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ExerciseDataPage()),
                    ),
                  ),
                  _trackerItem(
                    "Meditation",
                    "assets/images/meditation.png",
                    Colors.purple,
                        () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MeditationDataPage()),
                    ),
                  ),
                  _trackerItem(
                    "Productivity",
                    "assets/images/productivity.png",
                    Colors.orange,
                        () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProductivityDataPage()),
                    ),
                  ),
                  _trackerItem(
                    "Nutrition",
                    "assets/images/nutrition.png",
                    Colors.red,
                        () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NutritionDataPage()),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Recommended for You",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            _buildCategoryTabs(),
            const SizedBox(height: 12),
            Expanded(
              child: _buildRecommendationsList(),
            ),
          ],
        ),
      ),
    );
  }

  // Creates a clickable tracker item with an icon and label
  Widget _trackerItem(String title, String image, Color color, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 110,
        margin: const EdgeInsets.only(right: 2),
        child: Column(
          children: [
            Image.asset(image, width: 90, height: 90),
            const SizedBox(height: 8),
            Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
            ),
          ],
        ),
      ),
    );
  }

  // Builds the horizontal scrollable category tabs for filtering recommendations
  Widget _buildCategoryTabs() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _categoryTab("Sleep", Colors.indigo),
          _categoryTab("Exercise", Colors.green),
          _categoryTab("Meditation", Colors.purple),
          _categoryTab("Productivity", Colors.orange),
          _categoryTab("Nutrition", Colors.red),
        ],
      ),
    );
  }

  // Creates a selectable category tab with appropriate styling
  Widget _categoryTab(String category, Color color) {
    final isSelected = selectedCategory == category;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = category;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))]
              : null,
        ),
        child: Text(
          category,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Builds a list of recommendations based on the selected category
  Widget _buildRecommendationsList() {
    // Get recommendations based on the selected category
    List<Map<String, dynamic>> recommendations = _getRecommendationsForCategory(selectedCategory);

    return ListView.builder(
      itemCount: recommendations.length,
      itemBuilder: (context, index) {
        final recommendation = recommendations[index];
        return _recommendationCard(
          recommendation['title'],
          recommendation['description'],
          recommendation['icon'],
          _getCategoryColor(selectedCategory),
        );
      },
    );
  }

  // Returns the colour associated with a specific health category
  Color _getCategoryColor(String category) {
    switch (category) {
      case "Sleep": return Colors.indigo;
      case "Exercise": return Colors.green;
      case "Meditation": return Colors.purple;
      case "Productivity": return Colors.orange;
      case "Nutrition": return Colors.red;
      default: return Colors.blue;
    }
  }

  // Provides recommendation data for each health category
  List<Map<String, dynamic>> _getRecommendationsForCategory(String category) {
    switch (category) {
      case "Sleep":
        return [
          {
            'title': 'Consistent Sleep Schedule',
            'description': 'Go to bed and wake up at the same time every day, even on weekends.',
            'icon': Icons.bedtime,
          },
          {
            'title': 'Optimise Your Environment',
            'description': 'Keep your bedroom dark, quiet, and cool (around 18°C).',
            'icon': Icons.nightlight,
          },
          {
            'title': 'Limit Screen Time',
            'description': 'Avoid screens at least 1 hour before bedtime to reduce blue light exposure.',
            'icon': Icons.phone_android,
          },
          {
            'title': 'Relaxation Techniques',
            'description': 'Try deep breathing or progressive muscle relaxation before sleep.',
            'icon': Icons.spa,
          },
        ];

      case "Exercise":
        return [
          {
            'title': '150 Minutes Per Week',
            'description': 'Aim for at least 150 minutes of moderate activity or 75 minutes of vigorous activity weekly.',
            'icon': Icons.timer,
          },
          {
            'title': 'Mix Cardio and Strength',
            'description': 'Incorporate both cardiovascular exercise and strength training for optimal health.',
            'icon': Icons.fitness_center,
          },
          {
            'title': 'Active Recovery',
            'description': 'Include walking, swimming, or gentle yoga on rest days to improve recovery.',
            'icon': Icons.directions_walk,
          },
          {
            'title': 'Start Small',
            'description': 'Begin with 10-minute sessions if you\'re new to exercise and gradually increase duration.',
            'icon': Icons.trending_up,
          },
        ];

      case "Meditation":
        return [
          {
            'title': 'Daily 5-Minute Practice',
            'description': 'Even just 5 minutes of daily meditation can have significant benefits for mental health.',
            'icon': Icons.access_time,
          },
          {
            'title': 'Body Scan Technique',
            'description': 'Practice progressive relaxation by mentally scanning from head to toe.',
            'icon': Icons.person_outline,
          },
          {
            'title': 'Mindful Breathing',
            'description': 'Focus on your breath, counting to four on inhale and six on exhale.',
            'icon': Icons.air,
          },
          {
            'title': 'Guided Meditations',
            'description': 'Use guided sessions to help maintain focus and learn new techniques.',
            'icon': Icons.headset,
          },
        ];

      case "Productivity":
        return [
          {
            'title': 'Pomodoro Technique',
            'description': 'Work in focused 25-minute sessions with 5-minute breaks between.',
            'icon': Icons.timer,
          },
          {
            'title': 'Time Blocking',
            'description': 'Schedule specific time blocks for different types of tasks and activities.',
            'icon': Icons.calendar_today,
          },
          {
            'title': 'Two-Minute Rule',
            'description': 'If a task takes less than two minutes, do it immediately instead of postponing.',
            'icon': Icons.flash_on,
          },
          {
            'title': 'Digital Detox',
            'description': 'Schedule regular periods of time away from screens and notifications.',
            'icon': Icons.do_not_disturb,
          },
        ];

      case "Nutrition":
        return [
          {
            'title': 'Colourful Plate Rule',
            'description': 'Aim to include at least 3 different coloured vegetables or fruits in each meal.',
            'icon': Icons.color_lens,
          },
          {
            'title': 'Protein with Every Meal',
            'description': 'Include a source of lean protein with each meal to maintain energy levels.',
            'icon': Icons.egg,
          },
          {
            'title': 'Hydration Reminder',
            'description': 'Drink water throughout the day, aiming for 8 glasses or 2 liters daily.',
            'icon': Icons.water_drop,
          },
          {
            'title': 'Meal Prep Sundays',
            'description': 'Prepare healthy meals and snacks for the week ahead to avoid unhealthy choices.',
            'icon': Icons.food_bank,
          },
        ];
      default:
        return [];
    }
  }

  // Creates a card displaying a health recommendation
  Widget _recommendationCard(String title, String description, IconData iconData, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.4), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(iconData, color: color, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: color.withBlue(color.blue ~/ 2),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}