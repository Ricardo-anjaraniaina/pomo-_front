import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import '../auth/data/auth_repository.dart';
import '../tasks/data/task_repository.dart';
import '../timer/data/session_repository.dart';

class DependencyInjection {
  static List<SingleChildWidget> get repositories => [
        Provider<AuthRepository>(create: (_) => AuthRepository()),
        Provider<TaskRepository>(create: (_) => TaskRepository()),
        Provider<SessionRepository>(create: (_) => SessionRepository()),
      ];
}
