import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth/data/auth_repository.dart';
import 'auth/presentation/auth_state.dart';
import 'core/constants.dart';
import 'core/di.dart';
import 'core/router.dart';
import 'tasks/data/task_repository.dart';
import 'tasks/presentation/tasks_state.dart';
import 'timer/data/session_repository.dart';
import 'timer/domain/timer_state.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 1. Core repositories (DI)
        ...DependencyInjection.repositories,

        // 2. Auth State
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(
            context.read<AuthRepository>(),
            context.read<SessionRepository>(),
          ),
        ),

        // 3. Tasks State
        ChangeNotifierProvider<TasksProvider>(
          create: (context) => TasksProvider(
            context.read<TaskRepository>(),
          ),
        ),

        // 4. Timer State (depends on SessionRepository and TasksProvider)
        ChangeNotifierProxyProvider<TasksProvider, TimerProvider>(
          create: (context) => TimerProvider(
            sessionRepository: context.read<SessionRepository>(),
            tasksProvider: context.read<TasksProvider>(),
          ),
          update: (context, tasksProvider, timerProvider) {
            timerProvider!.updateTasksProvider(tasksProvider);
            return timerProvider;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Pomo.',
        theme: AppTheme.darkTheme,
        initialRoute: AppRoutes.home,
        routes: AppRoutes.routes,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
