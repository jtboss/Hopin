import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../map/snapchat_map_screen.dart';
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
        const SnapchatMapScreen(isDriverMode: true),
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
        const SnapchatMapScreen(isDriverMode: false),
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
    final isMapScreen = _currentIndex == 1; // Map is always at index 1
    
    return Scaffold(
      // Remove app bar for full-screen map experience
      appBar: isMapScreen ? null : AppBar(
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
      
      // Hide bottom nav for full-screen map experience
      bottomNavigationBar: isMapScreen ? null : BottomNavigationBar(
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
      
      // Floating navigation for map screen
      floatingActionButton: isMapScreen ? _buildMapNavigation() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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

  /// Build floating navigation for map screen
  Widget _buildMapNavigation() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: HopinColors.background.withOpacity(0.95),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: HopinColors.onBackground.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // My Rides
          _buildNavItem(
            icon: _isDriverMode ? Icons.directions_car_outlined : Icons.history_outlined,
            activeIcon: _isDriverMode ? Icons.directions_car : Icons.history,
            label: 'Rides',
            index: 0,
          ),
          
          const SizedBox(width: 20),
          
          // Map (current)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: HopinColors.snapchatYellow,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.map,
                  size: 20,
                  color: HopinColors.midnightBlue,
                ),
                const SizedBox(width: 6),
                Text(
                  _isDriverMode ? 'DRIVING' : 'EXPLORE',
                  style: HopinTextStyles.snapchatButton.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 20),
          
          // Profile or Dashboard
          _buildNavItem(
            icon: _isDriverMode ? Icons.dashboard_outlined : Icons.person_outline,
            activeIcon: _isDriverMode ? Icons.dashboard : Icons.person,
            label: _isDriverMode ? 'Dashboard' : 'Profile',
            index: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isActive = _currentIndex == index;
    
    return GestureDetector(
      onTap: () => _navigateToTab(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 20,
              color: isActive 
                  ? HopinColors.snapchatYellow
                  : HopinColors.onSurfaceVariant,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isActive 
                    ? HopinColors.snapchatYellow
                    : HopinColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 