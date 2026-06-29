import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../tasks/presentation/tasks_state.dart';
import '../domain/timer_state.dart';
import 'widgets/timer_circle.dart';

class TimerScreen extends StatelessWidget {
  const TimerScreen({super.key});

  String _formatDuration(Duration duration) {
    String minutes = duration.inMinutes.toString().padLeft(2, '0');
    String seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final timerProvider = context.watch<TimerProvider>();
    final tasksProvider = context.watch<TasksProvider>();
    final activeTask = tasksProvider.selectedTask;

    // Smooth transition for the accent color depending on state (Focus vs Break)
    final Color targetColor = timerProvider.modeColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pomo.',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Subtle developer tool to fast-forward for verification
          IconButton(
            tooltip: 'Fast Forward (Debug)',
            onPressed: () => timerProvider.debugFastForward(const Duration(minutes: 5)),
            icon: const Icon(Icons.fast_forward_rounded, color: AppColors.textSecondary, size: 20),
            splashRadius: 20,
          ),
        ],
      ),
      body: TweenAnimationBuilder<Color?>(
        duration: const Duration(milliseconds: 500),
        tween: ColorTween(begin: targetColor, end: targetColor),
        builder: (context, animatedColor, child) {
          final color = animatedColor ?? targetColor;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Mode Selector Segment Tabs
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildModeTab(
                        context,
                        label: 'Focus',
                        isSelected: timerProvider.mode == PomodoroMode.focus,
                        selectedColor: AppColors.focusAccent,
                        onTap: () => timerProvider.selectMode(PomodoroMode.focus),
                      ),
                      const SizedBox(width: 8),
                      _buildModeTab(
                        context,
                        label: 'Short Break',
                        isSelected: timerProvider.mode == PomodoroMode.shortBreak,
                        selectedColor: AppColors.breakAccent,
                        onTap: () => timerProvider.selectMode(PomodoroMode.shortBreak),
                      ),
                      const SizedBox(width: 8),
                      _buildModeTab(
                        context,
                        label: 'Long Break',
                        isSelected: timerProvider.mode == PomodoroMode.longBreak,
                        selectedColor: AppColors.breakAccent,
                        onTap: () => timerProvider.selectMode(PomodoroMode.longBreak),
                      ),
                    ],
                  ),

                  const SizedBox(height: 48),

                  // Timer Circle Widget
                  TimerCircle(
                    progress: timerProvider.progress,
                    isRunning: timerProvider.isRunning,
                    themeColor: color,
                    timeString: _formatDuration(timerProvider.durationRemaining),
                    statusLabel: timerProvider.modeName,
                  ),

                  const SizedBox(height: 48),

                  // Play / Pause / Reset Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Reset Button
                      _buildControlButton(
                        context,
                        icon: Icons.refresh_rounded,
                        onPressed: timerProvider.reset,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 24),
                      // Main Play/Pause Button
                      GestureDetector(
                        onTap: () {
                          if (timerProvider.isRunning) {
                            timerProvider.pause();
                          } else {
                            timerProvider.start();
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.3),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            timerProvider.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Skip Button
                      _buildControlButton(
                        context,
                        icon: Icons.skip_next_rounded,
                        onPressed: timerProvider.skip,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),

                  const SizedBox(height: 48),

                  // Selected Task Focus Panel
                  if (activeTask != null)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.play_circle_outline_rounded,
                              color: color,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'FOCUSING ON',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  activeTask.title,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 20),
                            onPressed: () => tasksProvider.selectTask(null),
                            splashRadius: 20,
                          ),
                        ],
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: () {
                        // Switch to Tasks Screen (usually screenIndex 1 in Navigation Shell)
                        // By calling provider navigation or standard tab switches.
                        // We will notify the parent navigator by triggering context.
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border, width: 1.0),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_task_rounded,
                              color: color,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Select a task to stay focused',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModeTab(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required Color selectedColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? selectedColor : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 22),
        onPressed: onPressed,
        splashRadius: 24,
      ),
    );
  }
}
