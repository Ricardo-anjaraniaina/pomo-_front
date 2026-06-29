import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../shared/widgets/primary_button.dart';
import 'tasks_state.dart';
import 'widgets/task_card.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  void _showAddTaskSheet(BuildContext context) {
    final tasksProvider = context.read<TasksProvider>();
    final titleController = TextEditingController();
    final descController = TextEditingController();
    int estimatedPomodoros = 2;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (builderContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(builderContext).viewInsets.bottom,
                top: 24,
                left: 24,
                right: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Create Focus Task',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title input
                  TextField(
                    controller: titleController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Task Title',
                      hintText: 'What are you working on?',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description input
                  TextField(
                    controller: descController,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Description (Optional)',
                      hintText: 'Add details or subtasks...',
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Pomodoro Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Estimated Blocks:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '🍅 × $estimatedPomodoros',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.focusAccent,
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(builderContext).copyWith(
                      activeTrackColor: AppColors.focusAccent,
                      inactiveTrackColor: AppColors.border,
                      thumbColor: AppColors.focusAccent,
                      overlayColor: AppColors.focusAccent.withValues(alpha: 0.2),
                      valueIndicatorColor: AppColors.surface,
                    ),
                    child: Slider(
                      value: estimatedPomodoros.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: estimatedPomodoros.toString(),
                      onChanged: (val) {
                        setSheetState(() {
                          estimatedPomodoros = val.round();
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit
                  PrimaryButton(
                    label: 'Create Task',
                    onPressed: () {
                      if (titleController.text.trim().isNotEmpty) {
                        tasksProvider.addTask(
                          titleController.text.trim(),
                          descController.text.trim(),
                          estimatedPomodoros,
                        );
                        Navigator.pop(sheetContext);
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasksProvider = context.watch<TasksProvider>();
    final activeTask = tasksProvider.selectedTask;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tasks',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showAddTaskSheet(context),
            icon: const Icon(Icons.add_rounded, color: AppColors.focusAccent),
            splashRadius: 20,
          ),
        ],
      ),
      body: tasksProvider.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.focusAccent),
              ),
            )
          : tasksProvider.tasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.assignment_turned_in_outlined,
                        size: 64,
                        color: AppColors.textSecondary.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No tasks created yet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create a task and select it to start tracking time.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      TextButton.icon(
                        onPressed: () => _showAddTaskSheet(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Add First Task'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.focusAccent,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: tasksProvider.tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasksProvider.tasks[index];
                    final isSelected = activeTask?.id == task.id;
                    return TaskCard(
                      task: task,
                      isSelected: isSelected,
                      onTap: () {
                        // Toggle select
                        if (isSelected) {
                          tasksProvider.selectTask(null);
                        } else {
                          tasksProvider.selectTask(task);
                        }
                      },
                      onToggleComplete: () {
                        tasksProvider.toggleTaskCompletion(task.id);
                      },
                      onDelete: () {
                        tasksProvider.deleteTask(task.id);
                      },
                    );
                  },
                ),
    );
  }
}
