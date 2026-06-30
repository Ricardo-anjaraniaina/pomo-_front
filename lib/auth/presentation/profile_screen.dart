import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/settings_service.dart';
import '../../core/notification_service.dart';
import '../../shared/widgets/primary_button.dart';
import '../../timer/domain/timer_state.dart';
import 'auth_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _avatarController;
  late Animation<double> _avatarScale;
  int? _unsyncedCount;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _avatarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _avatarScale = CurvedAnimation(
      parent: _avatarController,
      curve: Curves.elasticOut,
    );
    _avatarController.forward();
    _loadUnsyncedCount();
  }

  Future<void> _loadUnsyncedCount() async {
    if (!mounted) return;
    final count = await context.read<SessionRepository>().getUnsyncedCount();
    if (mounted) {
      setState(() {
        _unsyncedCount = count;
      });
    }
  }

  @override
  void dispose() {
    _avatarController.dispose();
    super.dispose();
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final settings = context.watch<SettingsService>();
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: authProvider.isAuthenticated
          ? _buildAuthenticatedView(context, user?.name ?? 'User',
              user?.email ?? '', settings)
          : _buildGuestView(context),
    );
  }

  // ─── Authenticated View ────────────────────────────────────────────────────

  Widget _buildAuthenticatedView(
    BuildContext context,
    String name,
    String email,
    SettingsService settings,
  ) {
    final timerProvider = context.watch<TimerProvider>();
    final initials = _getInitials(name);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // ── Avatar Card ──
        _buildAvatarCard(initials, name, email,
            timerProvider.completedFocusCycles),

        const SizedBox(height: 16),

        // ── Pomodoro Settings ──
        _buildSectionHeader('⏱ Paramètres Pomodoro'),
        const SizedBox(height: 8),
        _buildPomodoroSettings(context, settings),

        const SizedBox(height: 16),

        // ── Notification Settings ──
        _buildSectionHeader('🔔 Notifications'),
        const SizedBox(height: 8),
        _buildNotificationSettings(context, settings),

        const SizedBox(height: 16),

        // ── Synchronization ──
        _buildSectionHeader('🔄 Synchronisation'),
        const SizedBox(height: 8),
        _buildSyncCard(context),

        const SizedBox(height: 24),

        // ── Logout ──
        _buildLogoutButton(context),
        const SizedBox(height: 32),
      ],
    );
  }

  // ── Avatar Card ─────────────────────────────────────────────────────────

  Widget _buildAvatarCard(
      String initials, String name, String email, int sessions) {
    return ScaleTransition(
      scale: _avatarScale,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: AppColors.focusAccent.withValues(alpha: 0.08),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            // Gradient Avatar
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFEF4444), Color(0xFFEC4899)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              email,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            // Quick stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatChip(
                  icon: Icons.local_fire_department_rounded,
                  label: 'Sessions',
                  value: '$sessions',
                  color: AppColors.focusAccent,
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: AppColors.border,
                ),
                _buildStatChip(
                  icon: Icons.emoji_events_rounded,
                  label: 'Cycles',
                  value: '${sessions ~/ 4}',
                  color: const Color(0xFFF59E0B),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  // ── Pomodoro Settings ────────────────────────────────────────────────────

  Widget _buildPomodoroSettings(
      BuildContext context, SettingsService settings) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Column(
        children: [
          _buildDurationSlider(
            label: '🍅 Focus',
            value: settings.focusDuration.toDouble(),
            min: 5,
            max: 60,
            color: AppColors.focusAccent,
            onChanged: (v) => settings.setFocusDuration(v.round()),
          ),
          const Divider(color: AppColors.border, height: 24),
          _buildDurationSlider(
            label: '☕ Pause courte',
            value: settings.shortBreakDuration.toDouble(),
            min: 1,
            max: 30,
            color: AppColors.breakAccent,
            onChanged: (v) => settings.setShortBreakDuration(v.round()),
          ),
          const Divider(color: AppColors.border, height: 24),
          _buildDurationSlider(
            label: '🌿 Longue pause',
            value: settings.longBreakDuration.toDouble(),
            min: 5,
            max: 60,
            color: AppColors.breakAccent,
            onChanged: (v) => settings.setLongBreakDuration(v.round()),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () async {
                await settings.resetToDefaults();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Paramètres réinitialisés.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.restore_rounded,
                  size: 16, color: AppColors.textSecondary),
              label: const Text(
                'Réinitialiser',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${value.round()} min',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            inactiveTrackColor: color.withValues(alpha: 0.2),
            thumbColor: color,
            overlayColor: color.withValues(alpha: 0.15),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            trackHeight: 4,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: (max - min).round(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  // ── Notification Settings ────────────────────────────────────────────────

  Widget _buildNotificationSettings(
      BuildContext context, SettingsService settings) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            icon: Icons.notifications_rounded,
            title: 'Notifications de fin de session',
            subtitle: 'Recevoir une notif quand le timer se termine',
            value: settings.notificationsEnabled,
            color: AppColors.focusAccent,
            onChanged: (v) async {
              if (v) {
                // Request permissions when enabling
                final notifService =
                    context.read<NotificationService>();
                final granted = await notifService.requestPermissions();
                if (!granted && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Permission de notification refusée. Activez-la dans les paramètres.'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                  return;
                }
              }
              await settings.setNotificationsEnabled(v);
            },
          ),
          // Preview button — uniquement sur mobile (pas supporté sur web)
          if (settings.notificationsEnabled && !kIsWeb) ...[
            const Divider(color: AppColors.border, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: InkWell(
                onTap: () async {
                  final notifService = context.read<NotificationService>();
                  await notifService.showTimerCompleteNotification(
                    modeName: 'Focus',
                    nextMode: 'Short Break',
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🔔 Notification de test envoyée !'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.breakAccent
                              .withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: AppColors.breakAccent,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tester la notification',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Envoie une notif de démonstration',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Color color,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: color,
            activeTrackColor: color.withValues(alpha: 0.3),
            inactiveTrackColor: AppColors.border,
          ),
        ],
      ),
    );
  }

  Widget _buildSyncCard(BuildContext context) {
    final sessionRepo = context.read<SessionRepository>();
    final hasUnsynced = _unsyncedCount != null && _unsyncedCount! > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (hasUnsynced ? AppColors.focusAccent : AppColors.breakAccent)
                      .withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasUnsynced ? Icons.sync_problem_rounded : Icons.sync_rounded,
                  color: hasUnsynced ? AppColors.focusAccent : AppColors.breakAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasUnsynced
                          ? 'Sessions non synchronisées'
                          : 'Données à jour',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _unsyncedCount == null
                          ? 'Calcul du statut...'
                          : hasUnsynced
                              ? '$_unsyncedCount session(s) en attente de synchronisation.'
                              : 'Toutes vos sessions sont bien enregistrées sur le serveur.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isSyncing
                  ? null
                  : () async {
                      setState(() {
                        _isSyncing = true;
                      });

                      final success = await sessionRepo.syncOfflineSessions();

                      if (mounted) {
                        setState(() {
                          _isSyncing = false;
                        });
                        await _loadUnsyncedCount();

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success
                                ? '🔄 Synchronisation réussie !'
                                : '❌ Échec de la synchronisation. Vérifiez votre connexion.'),
                            duration: const Duration(seconds: 3),
                            backgroundColor: success
                                ? const Color(0xFF10B981)
                                : AppColors.focusAccent,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: hasUnsynced
                    ? AppColors.focusAccent
                    : AppColors.surfaceHover,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: hasUnsynced ? Colors.transparent : AppColors.border,
                    width: 1,
                  ),
                ),
              ),
              icon: _isSyncing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.sync_rounded, size: 18),
              label: Text(
                _isSyncing
                    ? 'Synchronisation...'
                    : hasUnsynced
                        ? 'Synchroniser maintenant'
                        : 'Forcer la synchronisation',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Logout ───────────────────────────────────────────────────────────────

  Widget _buildLogoutButton(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    return PrimaryButton(
      label: 'Se déconnecter',
      color: AppColors.focusAccent,
      onPressed: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppColors.border),
            ),
            title: const Text(
              'Déconnexion',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            content: const Text(
              'Voulez-vous vraiment vous déconnecter ?',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.focusAccent),
                child: const Text('Déconnecter'),
              ),
            ],
          ),
        );

        if (confirmed == true && context.mounted) {
          final messenger = ScaffoldMessenger.of(context);
          await authProvider.logout();
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Déconnecté avec succès.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
    );
  }

  // ─── Guest View ────────────────────────────────────────────────────────────

  Widget _buildGuestView(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // Hero section
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF0F1B2D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border, width: 1.0),
          ),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.focusAccent.withValues(alpha: 0.15),
                  border: Border.all(
                    color: AppColors.focusAccent.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.focusAccent,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Créez votre compte',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Synchronisez vos sessions et suivez vos progrès sur tous vos appareils.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              // Benefits
              _buildBenefit(
                  Icons.sync_rounded, 'Sync multi-appareils', AppColors.breakAccent),
              const SizedBox(height: 12),
              _buildBenefit(
                  Icons.bar_chart_rounded, 'Historique et statistiques', const Color(0xFFF59E0B)),
              const SizedBox(height: 12),
              _buildBenefit(
                  Icons.notifications_active_rounded, 'Notifications personnalisées',
                  AppColors.focusAccent),
            ],
          ),
        ),
        const SizedBox(height: 20),
        PrimaryButton(
          label: 'Se connecter',
          color: AppColors.focusAccent,
          onPressed: () => Navigator.pushNamed(context, '/login'),
        ),
        const SizedBox(height: 12),
        PrimaryButton(
          label: 'Créer un compte',
          color: AppColors.breakAccent,
          onPressed: () => Navigator.pushNamed(context, '/register'),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
            child: const Text(
              'Continuer sans connexion',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildBenefit(IconData icon, String text, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'U';
  }
}
