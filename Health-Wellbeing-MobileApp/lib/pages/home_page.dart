import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';

// Import the tracker pages
import 'sleep_tracker_page.dart';
import 'exercise_tracker_page.dart';
import 'meditation_tracker_page.dart';
import 'productivity_tracker_page.dart';
import 'nutrition_tracker_page.dart';
import 'notification_service.dart';

// HomePage widget that serves as the main dashboard for the health and wellbeing app
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final PageController _pageController = PageController(viewportFraction: 0.98);
  int _currentPage = 0;
  late Timer _timer;

  // List of mood quotes to display in the carousel
  final List<Map<String, dynamic>> _moodQuotes = [
    {
      "quote": "Every day is a fresh start.",
      "image": "assets/images/quotebg1.jpg",
      "icon": Icons.wb_sunny,
    },
    {
      "quote": "Happiness is a choice.",
      "image": "assets/images/quotebg2.jpg",
      "icon": Icons.sentiment_satisfied_alt,
    },
    {
      "quote": "Embrace the moment.",
      "image": "assets/images/quotebg3.jpg",
      "icon": Icons.self_improvement,
    },
    {
      "quote": "Your feelings are valid.",
      "image": "assets/images/quotebg4.jpg",
      "icon": Icons.favorite,
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
    _setupNotifications();
  }

  // WIP - Sets up notification service for reminders, only runs if a user is currently logged in
  void _setupNotifications() async {
    // Check if the user is logged in
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Schedule reminder notifications
      await NotificationService().scheduleReminderNotifications();
    }
  }

  // Starts auto-scrolling for the mood quotes carousel that cycles through quotes every 4 seconds
  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_currentPage < _moodQuotes.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeMessage(),
              const SizedBox(height: 20),

              // Mood Tracker Carousel
              SizedBox(
                height: 160,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _moodQuotes.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: _moodQuoteCard(
                        _moodQuotes[index]["quote"]!,
                        _moodQuotes[index]["image"]!,
                        _moodQuotes[index]["icon"]!,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),

              // Trackers Section
              const Text(
                "Your Trackers",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _trackerItem(
                      "Sleep",
                      "assets/images/sleeptracker.png",
                          () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SleepTrackerPage()),
                      ),
                    ),
                    _trackerItem(
                      "Exercise",
                      "assets/images/exercise.png",
                          () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ExerciseTrackerPage()),
                      ),
                    ),
                    _trackerItem(
                      "Meditation",
                      "assets/images/meditation.png",
                          () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MeditationTrackerPage()),
                      ),
                    ),
                    _trackerItem(
                      "Productivity",
                      "assets/images/productivity.png",
                          () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProductivityTrackerPage()),
                      ),
                    ),
                    _trackerItem(
                      "Nutrition",
                      "assets/images/nutrition.png",
                          () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NutritionTrackerPage()),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Recommended Section
              const Text(
                "Recommended",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              SizedBox(
                height: 210,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _recommendedItem("Nutrition", "5 Healthy Recipes", "assets/images/healthymeals.jpg", "Eat well, live well."),
                    _recommendedItem("Social", "Virtual Events", "assets/images/virtualevents.png", "Connect, learn, grow."),
                    _recommendedItem("Community", "Challenges", "assets/images/runningchallenge.jpg", "Inspire and be inspired."),
                    _recommendedItem("Stories", "How Emma Overcame Anxiety", "assets/images/emma.webp", "Real stories, real strength."),
                    _recommendedItem("Support", "Mental Support", "assets/images/mind.webp", "You're not alone."),
                    _recommendedItem("Motivation", "Daily Tips", "assets/images/motivation.jpg", "Every day is a new start."),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Builds a personalised welcome message and fetches the user's name from Firestore if they're logged in
  Widget _buildWelcomeMessage() {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      return FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('UserDetails').doc(user.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Text("Welcome Back!", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold));
          }

          if (snapshot.hasError) {
            return const Text("Welcome Back!", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold));
          }

          if (snapshot.hasData && snapshot.data!.exists) {
            Map<String, dynamic>? userData;
            try {
              userData = snapshot.data!.data() as Map<String, dynamic>?;
            } catch (e) {
              return const Text("Welcome Back!", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold));
            }

            if (userData != null && userData.containsKey('name')) {
              String name = userData['name'] ?? 'User';
              return Text("Welcome Back, $name!", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold));
            }
          }
          return const Text("Welcome Back!", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold));
        },
      );
    } else {
      return const Text("Welcome! Please Log In", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold));
    }
  }

  // Creates a card for displaying mood quotes with background image and icon
  Widget _moodQuoteCard(String quote, String imagePath, IconData icon) {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.5), Colors.transparent],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 50, color: Colors.white),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                child: Text(
                  '"$quote"',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 6,
                        color: Colors.black54,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Creates a clickable tracker item that navigates to the appropriate tracking page
  Widget _trackerItem(String title, String imagePath, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Column(
          children: [
            Image.asset(imagePath, height: 90, width: 90),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // Creates a recommended content item card
  Widget _recommendedItem(String category, String title, String imagePath, String quote) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(imagePath, height: 140, width: 200, fit: BoxFit.cover),
          ),
          const SizedBox(height: 6),
          Text(category, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(fontSize: 14)),
          Text(quote, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey)),
        ],
      ),
    );
  }
}