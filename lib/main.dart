import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth/data/auth_repository.dart';
import 'auth/presentation/auth_state.dart';
import 'core/constants.dart';
import 'core/di.dart';
import 'core/notification_service.dart';
import 'core/router.dart';
import 'core/settings_service.dart';
import 'tasks/data/task_repository.dart';
import 'tasks/presentation/tasks_state.dart';
import 'timer/data/session_repository.dart';
import 'timer/domain/timer_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize core services before running the app
  final notificationService = NotificationService();
  if (!kIsWeb) {
    await notificationService.initialize();
    await notificationService.requestPermissions();
  }

  final settingsService = SettingsService();
  await settingsService.load();

  runApp(MyApp(
    notificationService: notificationService,
    settingsService: settingsService,
  ));
}

class MyApp extends StatelessWidget {
  final NotificationService notificationService;
  final SettingsService settingsService;

  const MyApp({
    super.key,
    required this.notificationService,
    required this.settingsService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 0. Core services
        Provider<NotificationService>.value(value: notificationService),
        ChangeNotifierProvider<SettingsService>.value(value: settingsService),

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

        // 4. Timer State (depends on SessionRepository, TasksProvider, Notification & Settings)
        ChangeNotifierProxyProvider2<TasksProvider, SettingsService,
            TimerProvider>(
          create: (context) => TimerProvider(
            sessionRepository: context.read<SessionRepository>(),
            notificationService: context.read<NotificationService>(),
            settingsService: context.read<SettingsService>(),
            tasksProvider: context.read<TasksProvider>(),
          ),
          update: (context, tasksProvider, settingsService, timerProvider) {
            timerProvider!.updateTasksProvider(tasksProvider);
            timerProvider.onSettingsChanged();
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
