import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For Firebase Authentication
import 'package:shared_preferences/shared_preferences.dart'; // For saving and loading user preferences
import 'pages/home_page.dart';
import 'pages/health_page.dart';
import 'pages/education_page.dart';
import 'pages/community_page.dart';
import 'pages/rewards_page.dart';
import 'pages/auth/profile_page.dart';
import 'pages/auth/login_page.dart';

// StatefulWidget is used because the state of this widget will change based on user interaction (e.g., bottom navigation change)
class NavigationExample extends StatefulWidget {
  const NavigationExample({super.key}); // Constructor to initialise the widget

  @override
  NavigationExampleState createState() => NavigationExampleState();
}

class NavigationExampleState extends State<NavigationExample> {
  int _selectedIndex = 0; // Index to track the selected bottom navigation item
  bool _isDarkMode = false; // Track dark mode preference
  bool _isHighContrast = false; // Track high contrast mode preference
  double _fontSize = 16.0; // Default font size
  bool _isButtonAnimationEnabled = true; // Track if button animation is enabled

  // List of pages corresponding to each bottom navigation item
  static const List<Widget> _pages = [
    HomePage(),
    HealthPage(),
    EducationPage(),
    CommunityPage(),
    RewardsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences(); // Load preferences when the state is initialised
  }

  // Function to load saved user preferences (like theme, font size, etc.)
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance(); // Retrieve SharedPreferences
    setState(() {
      _isDarkMode = prefs.getBool('dark_mode') ?? false; // Load dark mode preference
      _isHighContrast = prefs.getBool('high_contrast') ?? false; // Load high contrast mode
      _fontSize = prefs.getDouble('font_size') ?? 16.0; // Load font size preference
      _isButtonAnimationEnabled = prefs.getBool('button_animation') ?? true; // Load button animation preference
    });
  }

  // Function to update preferences and save them using SharedPreferences
  void _togglePreference(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance(); // Retrieve SharedPreferences
    if (value is bool) {
      await prefs.setBool(key, value); // Save boolean preference
    } else if (value is double) {
      await prefs.setDouble(key, value); // Save double preference (like font size)
    }
    setState(() {
      // Update state based on which preference is being updated
      if (key == 'dark_mode') _isDarkMode = value;
      if (key == 'high_contrast') _isHighContrast = value;
      if (key == 'font_size') _fontSize = value;
      if (key == 'button_animation') _isButtonAnimationEnabled = value;
    });
  }

  // Function to show the settings dialog to adjust user preferences
  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Settings"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dark Mode switch (to toggle between light and dark modes)
              SwitchListTile(
                title: const Text("Dark Mode"),
                value: _isDarkMode,
                onChanged: (bool value) {
                  _togglePreference('dark_mode', value); // Toggle dark mode preference
                  Navigator.pop(context); // Close dialog after update
                },
              ),
              // High Contrast Mode switch (to toggle between standard and high contrast modes)
              SwitchListTile(
                title: const Text("High Contrast Mode"),
                value: _isHighContrast,
                onChanged: (bool value) {
                  _togglePreference('high_contrast', value); // Toggle high contrast preference
                  Navigator.pop(context); // Close dialog after update
                },
              ),
              // Font Size dropdown (to allow user to choose between Small, Medium, or Large font sizes)
              ListTile(
                title: const Text("Font Size"),
                trailing: DropdownButton<double>(
                  value: _fontSize, // Current font size
                  items: const [
                    DropdownMenuItem(value: 14.0, child: Text("Small")),
                    DropdownMenuItem(value: 16.0, child: Text("Medium")),
                    DropdownMenuItem(value: 18.0, child: Text("Large")),
                  ],
                  onChanged: (double? value) {
                    if (value != null) {
                      _togglePreference('font_size', value); // Update font size preference
                      Navigator.pop(context); // Close dialog after update
                    }
                  },
                ),
              ),
              // Button Animation switch (to toggle button animations on or off)
              SwitchListTile(
                title: const Text("Enable Button Animations"),
                value: _isButtonAnimationEnabled,
                onChanged: (bool value) {
                  _togglePreference('button_animation', value); // Toggle button animation preference
                  Navigator.pop(context); // Close dialog after update
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Bottom navigation item click handler (change selected page)
  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index); // Update selected index based on user tap
  }

  // Function to show either the profile page or login page depending if user is logged in
  void showLoginOptions(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser; // Get current Firebase user
    if (user != null) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage())); // Navigate to profile page if logged in
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage())); // Navigate to login page if not logged in
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: _isDarkMode ? Brightness.dark : Brightness.light,
        textTheme: TextTheme(
          bodyMedium: TextStyle(
            fontSize: _fontSize, // Set font size based on user preference
            fontWeight: _isHighContrast ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        splashFactory: _isButtonAnimationEnabled ? InkSplash.splashFactory : NoSplash.splashFactory,
      ),
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: _isDarkMode ? Colors.black : Colors.grey[200],
          elevation: 0,
          centerTitle: true,
          title: Semantics(
            label: "App Logo",
            child: Image.asset(
              'assets/images/AppLogoText.png', // App logo image
              height: 35,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.settings, color: _isDarkMode ? Colors.white : Colors.black), // Settings icon
            tooltip: "Settings",
            onPressed: () => _showSettingsDialog(context), // Open settings
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.person, color: _isDarkMode ? Colors.white : Colors.black),
              tooltip: "User Profile",
              onPressed: () => showLoginOptions(context), // Open profile or login page when clicked
            ),
          ],
        ),

        // Main body displaying the selected page based on bottom navigation
        body: _pages[_selectedIndex],

        // Bottom navigation bar
        bottomNavigationBar: Container(
          height: 72,
          decoration: BoxDecoration(
            color: _isDarkMode ? Colors.black : Colors.grey[200],
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 5,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            items: [
              _buildNavItem('assets/images/home.png', 'Home', 0), // Home navigation item
              _buildNavItem('assets/images/cardiogram.png', 'Health', 1), // Health navigation item
              _buildNavItem('assets/images/education.png', 'Education', 2), // Education navigation item
              _buildNavItem('assets/images/group-users.png', 'Community', 3), // Community navigation item
              _buildNavItem('assets/images/gift.png', 'Rewards', 4), // Rewards navigation item
            ],
            currentIndex: _selectedIndex, // Set current selected index
            onTap: _onItemTapped,
            backgroundColor: Colors.transparent,
            selectedItemColor: _isDarkMode ? Colors.white : Colors.black,
            unselectedItemColor: _isDarkMode ? Colors.white70 : Colors.black.withOpacity(0.6),
            elevation: 0,
            type: BottomNavigationBarType.fixed, // Fixed bottom navigation
            showSelectedLabels: true,
            showUnselectedLabels: true,
            selectedLabelStyle: TextStyle(
              fontWeight: _isHighContrast ? FontWeight.bold : FontWeight.w600,
            ),
            unselectedLabelStyle: TextStyle(
              fontWeight: _isHighContrast ? FontWeight.bold : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  // Function to build each bottom navigation item
  BottomNavigationBarItem _buildNavItem(String assetPath, String label, int index) {
    return BottomNavigationBarItem(
      icon: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 28,
            child: Semantics(
              label: "$label icon",
              child: Image.asset(
                _selectedIndex == index ? assetPath : _getInactiveImagePath(index), // Change icon based on selected index
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
      label: label,
    );
  }

  // Function to get the inactive image path for each navigation item
  String _getInactiveImagePath(int index) {
    switch (index) {
      case 0:
        return 'assets/images/home_faded.png'; // Home inactive image
      case 1:
        return 'assets/images/cardiogram_faded.png'; // Health inactive image
      case 2:
        return 'assets/images/education_faded.png'; // Education inactive image
      case 3:
        return 'assets/images/group-users_faded.png'; // Community inactive image
      case 4:
        return 'assets/images/gift_faded.png'; // Rewards inactive image
      default:
        return 'assets/images/home_faded.png'; // Default fallback
    }
  }
}
