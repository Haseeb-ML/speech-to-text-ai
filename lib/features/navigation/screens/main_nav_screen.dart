import 'package:flutter/material.dart';
import '../../audio_transcription/screens/record_audio_screen.dart';
import '../../audio_transcription/screens/saved_audio_screen.dart';
import '../../settings/screens/settings_screen.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _currentIndex = 0;

  List<Widget> get _screens => [
    const RecordAudioScreen(),
    const SavedAudioScreen(),
    const Center(child: Text("History Screen (Coming Soon)")),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        elevation: 10,
        items: [
          _buildNavItem(Icons.mic, 0),
          _buildNavItem(Icons.folder_outlined, 1),
          _buildNavItem(Icons.history, 2),
          _buildNavItem(Icons.settings_outlined, 3),
        ],
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, int index) {
    final isSelected = _currentIndex == index;
    return BottomNavigationBarItem(
      icon: isSelected
          ? Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Colors.blue, // Image ke mutabiq blue circle
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            )
          : Icon(icon, color: Theme.of(context).unselectedWidgetColor, size: 24),
      label: '',
    );
  }
}
