import 'package:flutter/material.dart';
import '../auth/presentation/login_screen.dart';
import '../auth/presentation/register_screen.dart';
import '../shared/widgets/home_navigation_shell.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';

  static Map<String, WidgetBuilder> get routes => {
        login: (context) => const LoginScreen(),
        register: (context) => const RegisterScreen(),
        home: (context) => const HomeNavigationShell(),
      };
}
