import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/presentation/profile_screen.dart';
import '../../core/constants.dart';
import '../../stats/presentation/stats_screen.dart';
import '../../tasks/presentation/tasks_screen.dart';
import '../../timer/domain/timer_state.dart';
import '../../timer/presentation/timer_screen.dart';

class HomeNavigationShell extends StatefulWidget {
  const HomeNavigationShell({super.key});

  @override
  State<HomeNavigationShell> createState() => _HomeNavigationShellState();
}

class _HomeNavigationShellState extends State<HomeNavigationShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final timerProvider = context.watch<TimerProvider>();
    final activeColor = timerProvider.modeColor;

    final screens = [
      const TimerScreen(),
      const TasksScreen(),
      StatsScreen(isActive: _currentIndex == 2),
      ProfileScreen(isActive: _currentIndex == 3),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 1.0)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          backgroundColor: AppColors.background,
          selectedItemColor: activeColor,
          unselectedItemColor: AppColors.textSecondary,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.timer_outlined),
              activeIcon: Icon(Icons.timer),
              label: 'Timer',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment),
              label: 'Tasks',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart_rounded),
              label: 'Stats',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
