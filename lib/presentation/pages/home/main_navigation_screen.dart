import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import 'map_home_screen.dart';
import 'my_rides_screen.dart';
import 'driver_dashboard_screen.dart';
import 'profile_screen.dart';

/// Main navigation screen with bottom tabs for different sections
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 1; // Start with map tab
  bool _isDriverMode = false;
  
  late List<Widget> _pages;
  late List<BottomNavigationBarItem> _items;

  @override
  void initState() {
    super.initState();
    _updatePages();
  }

  void _updatePages() {
    if (_isDriverMode) {
      _pages = [
        const DriverDashboardScreen(),
        MapHomeScreen(isDriverMode: true),
        const MyRidesScreen(showDriverRides: true),
      ];
      
      _items = const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.map_outlined),  
          activeIcon: Icon(Icons.map),
          label: 'Map',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.directions_car_outlined),
          activeIcon: Icon(Icons.directions_car),
          label: 'My Rides',
        ),
      ];
    } else {
      _pages = [
        const MyRidesScreen(showDriverRides: false),
        MapHomeScreen(isDriverMode: false),
        const ProfileScreen(),
      ];
      
      _items = const [
        BottomNavigationBarItem(
          icon: Icon(Icons.history_outlined),
          activeIcon: Icon(Icons.history),
          label: 'My Rides',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.map_outlined),
          activeIcon: Icon(Icons.map),
          label: 'Find Rides',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    }
  }

  void _toggleDriverMode() {
    setState(() {
      _isDriverMode = !_isDriverMode;
      _currentIndex = 1; // Reset to map
      _updatePages();
    });
    
    print('🔄 Mode toggled to: ${_isDriverMode ? 'Driver' : 'Passenger'}');
    print('📱 MapHomeScreen isDriverMode: $_isDriverMode');
  }

  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isDriverMode ? 'Hopin Driver' : 'Hopin'),
        backgroundColor: HopinColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Driver/Rider mode toggle
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilledButton.tonalIcon(
              onPressed: _toggleDriverMode,
              icon: Icon(_isDriverMode ? Icons.directions_car : Icons.person),
              label: Text(_isDriverMode ? 'Driver' : 'Rider'),
              style: FilledButton.styleFrom(
                backgroundColor: _isDriverMode 
                    ? HopinColors.secondary.withOpacity(0.2)
                    : HopinColors.primary.withOpacity(0.2),
                foregroundColor: _isDriverMode 
                    ? HopinColors.secondary
                    : HopinColors.primary,
              ),
            ),
          ),
          
          // Profile button
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: HopinColors.primaryContainer,
              child: IconButton(
                icon: const Icon(
                  Icons.person,
                  size: 18,
                  color: HopinColors.primary,
                ),
                onPressed: () {
                  // Show profile menu
                  _showProfileMenu();
                },
              ),
            ),
          ),
        ],
      ),
      
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: HopinColors.surface,
        selectedItemColor: HopinColors.primary,
        unselectedItemColor: HopinColors.onSurfaceVariant,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: _items,
      ),
    );
  }

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: HopinColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: HopinColors.onSurfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // User info
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: HopinColors.primaryContainer,
                  child: Text(
                    FirebaseAuth.instance.currentUser?.email?.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: HopinColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        FirebaseAuth.instance.currentUser?.displayName ?? 'Student User',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: HopinColors.onSurface,
                        ),
                      ),
                      Text(
                        FirebaseAuth.instance.currentUser?.email ?? 'user@university.ac.za',
                        style: const TextStyle(
                          fontSize: 14,
                          color: HopinColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Menu items
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to settings
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Help & Support'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to help
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await FirebaseAuth.instance.signOut();
                // Navigation will be handled by the auth listener
              },
            ),
            
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
} 