import 'package:flutter/material.dart';

// Educational content page displaying health, wellness and nutrition information
class EducationPage extends StatefulWidget {
  const EducationPage({super.key});

  @override
  State<EducationPage> createState() => EducationPageState();
}

class EducationPageState extends State<EducationPage> {
  String selectedCategory = "Healthy Habits";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCategoryTabs(),
                const SizedBox(height: 16),

                _getCategoryContent(),
                const SizedBox(height: 10),

                const Text(
                  "Quick Tips",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                _scrollableSmallTips(),
                const SizedBox(height: 10),

                const Text(
                  "Recommended Reads",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _getRecommendedReads(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Builds the horizontal category selection tabs at the top of the page
  Widget _buildCategoryTabs() {
    List<String> categories = ["Healthy Habits", "Mental Wellbeing", "Nutrition"];

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: categories.map((category) => _categoryButton(category)).toList(),
      ),
    );
  }

  // Creates a single category button with appropriate styling
  Widget _categoryButton(String category) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: selectedCategory == category ? Colors.black : Colors.grey[300],
          foregroundColor: selectedCategory == category ? Colors.white : Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        ),
        onPressed: () {
          setState(() {
            selectedCategory = category;
          });
        },
        child: Text(category),
      ),
    );
  }

  // Creates an information card with icon, title, description and bullet points
  Widget _infoCard(IconData icon, String title, String description, List<String> bulletPoints, Color color, Color titleColor, Color iconColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 32, color: iconColor),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: titleColor),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(description, style: const TextStyle(fontSize: 16, color: Colors.black87)),
          const SizedBox(height: 10),
          Column(
            children: bulletPoints.map((point) => _bulletPoint(point, titleColor)).toList(),
          ),
        ],
      ),
    );
  }

  // Creates a styled bullet point with checkmark icon
  Widget _bulletPoint(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 16, color: color))),
        ],
      ),
    );
  }

  // Returns the appropriate content card based on selected category
  Widget _getCategoryContent() {
    switch (selectedCategory) {
      case "Healthy Habits":
        return _infoCard(
          Icons.favorite,
          "Healthy Habits",
          "Adopting healthy habits is key to living a long, happy life.",
          ["Stay hydrated.", "Get 7-9 hours of sleep.", "Exercise regularly.", "Avoid too much screen time.", "Maintain a positive routine."],
          Colors.green.shade100,
          Colors.green.shade800,
          Colors.green.shade600,
        );
      case "Mental Wellbeing":
        return _infoCard(
          Icons.self_improvement,
          "Mental Wellbeing",
          "Mental health is just as important as physical health.",
          ["Practice mindfulness.", "Talk to someone you trust.", "Take regular breaks.", "Write in a journal.", "Avoid negative influences."],
          Colors.orange.shade200, // Lighter orange for background
          Colors.orange.shade800, // Dark orange for the title
          Colors.orange.shade600, // Dark orange for the icon
        );
      case "Nutrition":
        return _infoCard(
          Icons.restaurant,
          "Nutrition",
          "Good nutrition fuels your body and mind to achieve your goals.",
          ["Eat a balanced diet.", "Limit sugar intake.", "Drink plenty of water.", "Eat more vegetables.", "Practice portion control."],
          Colors.blue.shade100,
          Colors.blue.shade800,
          Colors.blue.shade600,
        );
      default:
        return Container();
    }
  }

  // Creates a horizontal scrollable list of small tip cards
  Widget _scrollableSmallTips() {
    // Data structure for tips organised by category
    Map<String, List<Map<String, dynamic>>> tipsData = {
      "Healthy Habits": [
        {'icon': Icons.local_drink, 'text': "Stay Hydrated", 'backgroundColor': Colors.green.shade100, 'iconColor': Colors.green.shade800, 'textColor': Colors.green.shade800},
        {'icon': Icons.fitness_center, 'text': "Exercise Daily", 'backgroundColor': Colors.green.shade100, 'iconColor': Colors.green.shade800, 'textColor': Colors.green.shade800},
        {'icon': Icons.bedtime, 'text': "Get Enough Sleep", 'backgroundColor': Colors.green.shade100, 'iconColor': Colors.green.shade800, 'textColor': Colors.green.shade800},
        {'icon': Icons.wb_sunny, 'text': "Go Outside More", 'backgroundColor': Colors.green.shade100, 'iconColor': Colors.green.shade800, 'textColor': Colors.green.shade800},
        {'icon': Icons.timer, 'text': "Keep a Routine", 'backgroundColor': Colors.green.shade100, 'iconColor': Colors.green.shade800, 'textColor': Colors.green.shade800},
      ],
      "Mental Wellbeing": [
        {'icon': Icons.self_improvement, 'text': "Practice Mindfulness", 'backgroundColor': Colors.orange.shade200, 'iconColor': Colors.orange.shade800, 'textColor': Colors.orange.shade800},
        {'icon': Icons.people, 'text': "Talk to Someone", 'backgroundColor': Colors.orange.shade200, 'iconColor': Colors.orange.shade800, 'textColor': Colors.orange.shade800},
        {'icon': Icons.book, 'text': "Read for Relaxation", 'backgroundColor': Colors.orange.shade200, 'iconColor': Colors.orange.shade800, 'textColor': Colors.orange.shade800},
        {'icon': Icons.headphones, 'text': "Listen to Music", 'backgroundColor': Colors.orange.shade200, 'iconColor': Colors.orange.shade800, 'textColor': Colors.orange.shade800},
        {'icon': Icons.favorite, 'text': "Do What You Love", 'backgroundColor': Colors.orange.shade200, 'iconColor': Colors.orange.shade800, 'textColor': Colors.orange.shade800},
      ],
      "Nutrition": [
        {'icon': Icons.apple, 'text': "Eat More Fruits", 'backgroundColor': Colors.blue.shade100, 'iconColor': Colors.blue.shade800, 'textColor': Colors.blue.shade800},
        {'icon': Icons.no_food, 'text': "Limit Fast Food", 'backgroundColor': Colors.blue.shade100, 'iconColor': Colors.blue.shade800, 'textColor': Colors.blue.shade800},
        {'icon': Icons.local_dining, 'text': "Balanced Meals", 'backgroundColor': Colors.blue.shade100, 'iconColor': Colors.blue.shade800, 'textColor': Colors.blue.shade800},
        {'icon': Icons.water_drop, 'text': "Drink More Water", 'backgroundColor': Colors.blue.shade100, 'iconColor': Colors.blue.shade800, 'textColor': Colors.blue.shade800},
        {'icon': Icons.restaurant, 'text': "Watch Portion Sizes", 'backgroundColor': Colors.blue.shade100, 'iconColor': Colors.blue.shade800, 'textColor': Colors.blue.shade800},
      ]
    };

    // Get the tips for the currently selected category
    List<Map<String, dynamic>> tips = tipsData[selectedCategory] ?? [];

    return SizedBox(
      height: 70,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tips.map((tip) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: tip['backgroundColor'],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(tip['icon'], size: 28, color: tip['iconColor']),
                      const SizedBox(height: 6),
                      Text(
                        tip['text'],
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 10, color: tip['textColor']),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // Gets a list of recommended reading items based on selected category
  List<Widget> _getRecommendedReads() {
    // Data structure for recommended reads organized by category
    // Each read has a title, quote, and image path
    Map<String, List<Map<String, String>>> readsData = {
      "Healthy Habits": [
        {"title": "Morning Routines", "quote": "Start your day right.", "image": "assets/images/morningroutine.webp"},
        {"title": "Fitness & You", "quote": "Stay active, stay healthy.", "image": "assets/images/fitnessandyou.jpg"},
        {"title": "Daily Wellness", "quote": "Small habits, big change.", "image": "assets/images/dailywellness.png"},
      ],
      "Mental Wellbeing": [
        {"title": "Mindfulness 101", "quote": "Stay present, be happy.", "image": "assets/images/mindfullness.png"},
        {"title": "Handling Stress", "quote": "Manage life's challenges.", "image": "assets/images/handlingstress.png"},
        {"title": "The Power of Rest", "quote": "Recharge your mind.", "image": "assets/images/powerofrest.jpg"},
      ],
      "Nutrition": [
        {"title": "Healthy Eating Tips", "quote": "Fuel your body the right way.", "image": "assets/images/healthyfoodtips.jpg"},
        {"title": "Best Superfoods", "quote": "Nutrient-rich foods for life.", "image": "assets/images/superfoods.jpg"},
        {"title": "Portion Control", "quote": "How much is too much?", "image": "assets/images/portioncontrol.webp"},
      ]
    };

    // Get the recommended reads for the selected category and map them to widgets
    return readsData[selectedCategory]!.map((read) => _recommendedItem(read["title"]!, read["quote"]!, read["image"]!)).toList();
  }

  // Creates a recommended reading item with image, title and quote
  Widget _recommendedItem(String title, String quote, String imagePath) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            // Creates rounded corners for the image
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
                imagePath,
                height: 140,
                width: 200,
                fit: BoxFit.cover
            ),
          ),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(quote, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey)),
        ],
      ),
    );
  }
}