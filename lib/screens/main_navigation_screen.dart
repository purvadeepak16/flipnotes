import 'package:flutter/material.dart';
import '../screens/pdf_home_screen.dart';
import '../screens/study_screen.dart';
import '../screens/visualize_concept_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/chat/chat_home_screen.dart';
import '../theme/app_theme.dart';

/// Main navigation screen with 4-item bottom navbar
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  
  late final List<Widget> _screens;
  
  @override
  void initState() {
    super.initState();
    _screens = [
      PdfHomeScreen(onTabChange: (index) => setState(() => _selectedIndex = index)),
      const StudyScreen(),
      const VisualizationScreen(),
      const ProfileScreen(),
      const ChatHomeScreen(),
    ];
  }

  Color _getTabColor(int index) {
    switch (index) {
      case 0: return AppColors.homeTeal;
      case 1: return AppColors.studyPurple;
      case 2: return AppColors.visualizeAmber;
      case 3: return AppColors.profileTeal;
      case 4: return AppColors.chatsPink;
      default: return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        height: 65 + MediaQuery.of(context).padding.bottom,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0x1A000000), width: 0.5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(5, (index) {
            final isSelected = _selectedIndex == index;
            final color = isSelected ? _getTabColor(index) : AppColors.mutedText;
            
            String label;
            IconData icon;
            switch (index) {
              case 0: label = 'Home'; icon = Icons.home_outlined; break;
              case 1: label = 'Study'; icon = Icons.grid_view_outlined; break;
              case 2: label = 'Visualize'; icon = Icons.wb_sunny_outlined; break;
              case 3: label = 'Profile'; icon = Icons.person_outline; break;
              case 4: label = 'Chats'; icon = Icons.chat_bubble_outline; break;
              default: label = ''; icon = Icons.home;
            }

            return GestureDetector(
              onTap: () => setState(() => _selectedIndex = index),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 20, color: color),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                      color: color,
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(height: 4),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ] else
                    const SizedBox(height: 8),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
