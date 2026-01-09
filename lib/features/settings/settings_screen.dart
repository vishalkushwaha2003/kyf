import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kyf/models/user_settings.dart';
import 'package:kyf/provider/themeProvider.dart';
import 'package:kyf/services/settings_service.dart';
import 'package:kyf/services/storage_service.dart';
import 'package:kyf/utils/toast.dart';

/// Settings Screen
/// Comprehensive settings page matching backend schema

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  UserSettings? _settings;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final storage = await StorageService.getInstance();
      final token = storage.getToken();

      if (token == null) {
        setState(() {
          _error = 'Not logged in';
          _isLoading = false;
        });
        return;
      }

      // Try to fetch settings, initialize if not found
      var response = await _settingsService.fetchSettings(token: token);

      if (!response.success && response.statusCode == 404) {
        // Initialize settings if not found
        response = await _settingsService.initializeSettings(token: token);
      }

      if (response.success) {
        final bodyData = response.data['body'];
        Map<String, dynamic> parsedBody;

        if (bodyData is String) {
          parsedBody = jsonDecode(bodyData) as Map<String, dynamic>;
        } else {
          parsedBody = bodyData as Map<String, dynamic>;
        }

        final data = parsedBody['data'] as Map<String, dynamic>;

        setState(() {
          _settings = UserSettings.fromJson(data);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.message ?? 'Failed to load settings';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
      setState(() {
        _error = 'Error loading settings';
        _isLoading = false;
      });
    }
  }

  void _openSettingsDetail(String category) {
    if (_settings == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _SettingsDetailPage(
          category: category,
          settings: _settings!,
          onSettingsUpdated: (updatedSettings) {
            setState(() {
              _settings = updatedSettings;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadSettings,
          ),
        ],
      ),
      body: _isLoading
          ? _buildSkeleton(theme)
          : _error != null
              ? _buildError(theme)
              : _buildSettings(theme),
    );
  }

  Widget _buildSkeleton(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: List.generate(
          6,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              width: double.infinity,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded,
              size: 64, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text(_error!, style: theme.textTheme.titleMedium),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _loadSettings,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettings(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Appearance Section
          _buildSectionHeader(theme, 'Appearance'),
          const SizedBox(height: 12),
          _SettingsCard(
            icon: Icons.palette_rounded,
            title: 'Theme',
            subtitle: _getThemeSubtitle(),
            onTap: () => _openSettingsDetail('theme'),
          ),
          const SizedBox(height: 24),

          // Communication Section
          _buildSectionHeader(theme, 'Communication'),
          const SizedBox(height: 12),
          _SettingsCard(
            icon: Icons.notifications_rounded,
            title: 'Notifications',
            subtitle: _getNotificationSubtitle(),
            onTap: () => _openSettingsDetail('notifications'),
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            icon: Icons.lock_rounded,
            title: 'Privacy',
            subtitle: _getPrivacySubtitle(),
            onTap: () => _openSettingsDetail('privacy'),
          ),
          const SizedBox(height: 24),

          // Preferences Section
          _buildSectionHeader(theme, 'Preferences'),
          const SizedBox(height: 12),
          _SettingsCard(
            icon: Icons.tune_rounded,
            title: 'General Preferences',
            subtitle: _getPreferencesSubtitle(),
            onTap: () => _openSettingsDetail('preferences'),
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            icon: Icons.view_quilt_rounded,
            title: 'Layout',
            subtitle: _getLayoutSubtitle(),
            onTap: () => _openSettingsDetail('layout'),
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            icon: Icons.accessibility_new_rounded,
            title: 'Accessibility',
            subtitle: _getAccessibilitySubtitle(),
            onTap: () => _openSettingsDetail('accessibility'),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  String _getThemeSubtitle() {
    if (_settings == null) return 'Configure appearance';
    final mode = _settings!.theme.mode;
    final fontSize = _settings!.theme.fontSize;
    return '${mode.substring(0, 1).toUpperCase()}${mode.substring(1)} mode • ${fontSize.substring(0, 1).toUpperCase()}${fontSize.substring(1)} text';
  }

  String _getNotificationSubtitle() {
    if (_settings == null) return 'Configure notifications';
    final enabled = <String>[];
    if (_settings!.notifications.push) enabled.add('Push');
    if (_settings!.notifications.email) enabled.add('Email');
    if (_settings!.notifications.sms) enabled.add('SMS');
    return enabled.isEmpty ? 'All disabled' : enabled.join(', ');
  }

  String _getPrivacySubtitle() {
    if (_settings == null) return 'Control your privacy';
    final visibility = _settings!.privacy.profileVisibility;
    return 'Profile: ${visibility.substring(0, 1).toUpperCase()}${visibility.substring(1)}';
  }

  String _getPreferencesSubtitle() {
    if (_settings == null) return 'Language, timezone & more';
    return '${_settings!.preferences.language.toUpperCase()} • ${_settings!.preferences.timezone}';
  }

  String _getLayoutSubtitle() {
    if (_settings == null) return 'Customize layout';
    return '${_settings!.layout.defaultView.substring(0, 1).toUpperCase()}${_settings!.layout.defaultView.substring(1)} view';
  }

  String _getAccessibilitySubtitle() {
    if (_settings == null) return 'Accessibility options';
    final features = <String>[];
    if (_settings!.accessibility.highContrast) features.add('High contrast');
    if (_settings!.accessibility.reducedMotion) features.add('Reduced motion');
    if (_settings!.accessibility.screenReader) features.add('Screen reader');
    return features.isEmpty ? 'Default settings' : features.join(', ');
  }
}

// ============ Settings Card Widget ============
class _SettingsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: theme.colorScheme.scrim, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============ Settings Detail Page ============
class _SettingsDetailPage extends ConsumerStatefulWidget {
  final String category;
  final UserSettings settings;
  final Function(UserSettings) onSettingsUpdated;

  const _SettingsDetailPage({
    required this.category,
    required this.settings,
    required this.onSettingsUpdated,
  });

  @override
  ConsumerState<_SettingsDetailPage> createState() => _SettingsDetailPageState();
}

class _SettingsDetailPageState extends ConsumerState<_SettingsDetailPage> {
  final SettingsService _settingsService = SettingsService();
  late UserSettings _settings;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
  }

  Future<void> _saveSettings(
      String type, Map<String, dynamic> data, UserSettings newSettings) async {
    setState(() => _isSaving = true);

    try {
      final storage = await StorageService.getInstance();
      final token = storage.getToken();

      if (token == null) {
        if (mounted) AppToast.error(context, 'Not logged in');
        return;
      }

      late final response;
      switch (type) {
        case 'theme':
          response =
              await _settingsService.updateTheme(token: token, themeData: data);
          break;
        case 'notifications':
          response = await _settingsService.updateNotifications(
              token: token, notificationData: data);
          break;
        case 'privacy':
          response = await _settingsService.updatePrivacy(
              token: token, privacyData: data);
          break;
        case 'preferences':
          response = await _settingsService.updatePreferences(
              token: token, preferencesData: data);
          break;
        case 'layout':
          response = await _settingsService.updateLayout(
              token: token, layoutData: data);
          break;
        case 'accessibility':
          response = await _settingsService.updateAccessibility(
              token: token, accessibilityData: data);
          break;
        default:
          return;
      }

      if (response.success) {
        setState(() => _settings = newSettings);
        widget.onSettingsUpdated(newSettings);
        if (mounted) AppToast.success(context, 'Settings updated');
      } else {
        if (mounted) {
          AppToast.error(context, response.message ?? 'Failed to save');
        }
      }
    } catch (e) {
      debugPrint('Error saving settings: $e');
      if (mounted) AppToast.error(context, 'Error saving settings');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String title;
    Widget content;

    switch (widget.category) {
      case 'theme':
        title = 'Theme Settings';
        content = _buildThemeSettings(theme);
        break;
      case 'notifications':
        title = 'Notification Settings';
        content = _buildNotificationSettings(theme);
        break;
      case 'privacy':
        title = 'Privacy Settings';
        content = _buildPrivacySettings(theme);
        break;
      case 'preferences':
        title = 'General Preferences';
        content = _buildPreferenceSettings(theme);
        break;
      case 'layout':
        title = 'Layout Settings';
        content = _buildLayoutSettings(theme);
        break;
      case 'accessibility':
        title = 'Accessibility Settings';
        content = _buildAccessibilitySettings(theme);
        break;
      default:
        title = 'Settings';
        content = const SizedBox();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: content,
      ),
    );
  }

  // ============ Theme Settings ============
  Widget _buildThemeSettings(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(theme, 'Appearance Mode'),
        const SizedBox(height: 12),
        _buildOptionSelector(
          theme,
          options: ['light', 'dark', 'system'],
          labels: ['Light', 'Dark', 'System'],
          icons: [Icons.light_mode, Icons.dark_mode, Icons.settings_suggest],
          selected: _settings.theme.mode,
          onChanged: (value) {
            // Apply theme change immediately to the app
            ref.read(themeModeProvider.notifier).setThemeMode(value);
            
            final newTheme = _settings.theme.copyWith(mode: value);
            _saveSettings('theme', newTheme.toJson(),
                _settings.copyWith(theme: newTheme));
          },
        ),
        const SizedBox(height: 24),
        _buildSectionTitle(theme, 'Font Size'),
        const SizedBox(height: 12),
        _buildOptionSelector(
          theme,
          options: ['small', 'medium', 'large'],
          labels: ['Small', 'Medium', 'Large'],
          icons: [
            Icons.text_fields,
            Icons.text_fields,
            Icons.text_fields,
          ],
          selected: _settings.theme.fontSize,
          onChanged: (value) {
            final newTheme = _settings.theme.copyWith(fontSize: value);
            _saveSettings('theme', newTheme.toJson(),
                _settings.copyWith(theme: newTheme));
          },
        ),
      ],
    );
  }

  // ============ Notification Settings ============
  Widget _buildNotificationSettings(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(theme, 'Notification Channels'),
        const SizedBox(height: 12),
        _buildSwitchTile(
          theme,
          icon: Icons.notifications_active,
          title: 'Push Notifications',
          subtitle: 'Receive push notifications on this device',
          value: _settings.notifications.push,
          onChanged: (value) {
            final newNotif = _settings.notifications.copyWith(push: value);
            _saveSettings('notifications', newNotif.toJson(),
                _settings.copyWith(notifications: newNotif));
          },
        ),
        _buildSwitchTile(
          theme,
          icon: Icons.email_outlined,
          title: 'Email Notifications',
          subtitle: 'Receive updates via email',
          value: _settings.notifications.email,
          onChanged: (value) {
            final newNotif = _settings.notifications.copyWith(email: value);
            _saveSettings('notifications', newNotif.toJson(),
                _settings.copyWith(notifications: newNotif));
          },
        ),
        _buildSwitchTile(
          theme,
          icon: Icons.sms_outlined,
          title: 'SMS Notifications',
          subtitle: 'Receive important updates via SMS',
          value: _settings.notifications.sms,
          onChanged: (value) {
            final newNotif = _settings.notifications.copyWith(sms: value);
            _saveSettings('notifications', newNotif.toJson(),
                _settings.copyWith(notifications: newNotif));
          },
        ),
        const SizedBox(height: 24),
        _buildSectionTitle(theme, 'Additional Options'),
        const SizedBox(height: 12),
        _buildSwitchTile(
          theme,
          icon: Icons.campaign_outlined,
          title: 'Marketing',
          subtitle: 'Receive promotional content and offers',
          value: _settings.notifications.marketing,
          onChanged: (value) {
            final newNotif = _settings.notifications.copyWith(marketing: value);
            _saveSettings('notifications', newNotif.toJson(),
                _settings.copyWith(notifications: newNotif));
          },
        ),
        _buildSwitchTile(
          theme,
          icon: Icons.volume_up_outlined,
          title: 'Sound',
          subtitle: 'Play sound for notifications',
          value: _settings.notifications.sound,
          onChanged: (value) {
            final newNotif = _settings.notifications.copyWith(sound: value);
            _saveSettings('notifications', newNotif.toJson(),
                _settings.copyWith(notifications: newNotif));
          },
        ),
        const SizedBox(height: 24),
        _buildSectionTitle(theme, 'Quiet Hours'),
        const SizedBox(height: 12),
        _buildSwitchTile(
          theme,
          icon: Icons.do_not_disturb_on_outlined,
          title: 'Enable Quiet Hours',
          subtitle: 'Mute notifications during specific hours',
          value: _settings.notifications.quietHours.enabled,
          onChanged: (value) {
            final newQuietHours =
                _settings.notifications.quietHours.copyWith(enabled: value);
            final newNotif =
                _settings.notifications.copyWith(quietHours: newQuietHours);
            _saveSettings('notifications', newNotif.toJson(),
                _settings.copyWith(notifications: newNotif));
          },
        ),
      ],
    );
  }

  // ============ Privacy Settings ============
  Widget _buildPrivacySettings(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(theme, 'Profile Visibility'),
        const SizedBox(height: 12),
        _buildOptionSelector(
          theme,
          options: ['public', 'private', 'friends'],
          labels: ['Public', 'Private', 'Friends Only'],
          icons: [Icons.public, Icons.lock, Icons.people],
          selected: _settings.privacy.profileVisibility,
          onChanged: (value) {
            final newPrivacy =
                _settings.privacy.copyWith(profileVisibility: value);
            _saveSettings('privacy', newPrivacy.toJson(),
                _settings.copyWith(privacy: newPrivacy));
          },
        ),
        const SizedBox(height: 24),
        _buildSectionTitle(theme, 'Activity Status'),
        const SizedBox(height: 12),
        _buildSwitchTile(
          theme,
          icon: Icons.circle,
          title: 'Show Online Status',
          subtitle: 'Let others see when you\'re online',
          value: _settings.privacy.showOnlineStatus,
          onChanged: (value) {
            final newPrivacy =
                _settings.privacy.copyWith(showOnlineStatus: value);
            _saveSettings('privacy', newPrivacy.toJson(),
                _settings.copyWith(privacy: newPrivacy));
          },
        ),
        _buildSwitchTile(
          theme,
          icon: Icons.access_time,
          title: 'Show Last Seen',
          subtitle: 'Let others see your last active time',
          value: _settings.privacy.showLastSeen,
          onChanged: (value) {
            final newPrivacy = _settings.privacy.copyWith(showLastSeen: value);
            _saveSettings('privacy', newPrivacy.toJson(),
                _settings.copyWith(privacy: newPrivacy));
          },
        ),
        _buildSwitchTile(
          theme,
          icon: Icons.label_outlined,
          title: 'Allow Tagging',
          subtitle: 'Let others tag you in posts and comments',
          value: _settings.privacy.allowTagging,
          onChanged: (value) {
            final newPrivacy = _settings.privacy.copyWith(allowTagging: value);
            _saveSettings('privacy', newPrivacy.toJson(),
                _settings.copyWith(privacy: newPrivacy));
          },
        ),
        const SizedBox(height: 24),
        _buildSectionTitle(theme, 'Messaging'),
        const SizedBox(height: 12),
        _buildOptionSelector(
          theme,
          options: ['everyone', 'friends', 'none'],
          labels: ['Everyone', 'Friends', 'No One'],
          icons: [Icons.public, Icons.people, Icons.block],
          selected: _settings.privacy.allowMessages,
          onChanged: (value) {
            final newPrivacy = _settings.privacy.copyWith(allowMessages: value);
            _saveSettings('privacy', newPrivacy.toJson(),
                _settings.copyWith(privacy: newPrivacy));
          },
        ),
      ],
    );
  }

  // ============ Preference Settings ============
  Widget _buildPreferenceSettings(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(theme, 'Time Format'),
        const SizedBox(height: 12),
        _buildOptionSelector(
          theme,
          options: ['12h', '24h'],
          labels: ['12 Hour', '24 Hour'],
          icons: [Icons.schedule, Icons.schedule],
          selected: _settings.preferences.timeFormat,
          onChanged: (value) {
            final newPrefs = _settings.preferences.copyWith(timeFormat: value);
            _saveSettings('preferences', newPrefs.toJson(),
                _settings.copyWith(preferences: newPrefs));
          },
        ),
        const SizedBox(height: 24),
        _buildSectionTitle(theme, 'Week Starts On'),
        const SizedBox(height: 12),
        _buildOptionSelector(
          theme,
          options: ['sunday', 'monday'],
          labels: ['Sunday', 'Monday'],
          icons: [Icons.calendar_today, Icons.calendar_today],
          selected: _settings.preferences.weekStartDay,
          onChanged: (value) {
            final newPrefs =
                _settings.preferences.copyWith(weekStartDay: value);
            _saveSettings('preferences', newPrefs.toJson(),
                _settings.copyWith(preferences: newPrefs));
          },
        ),
        const SizedBox(height: 24),
        _buildSectionTitle(theme, 'Measurements'),
        const SizedBox(height: 12),
        _buildOptionSelector(
          theme,
          options: ['metric', 'imperial'],
          labels: ['Metric (km, kg)', 'Imperial (mi, lb)'],
          icons: [Icons.straighten, Icons.straighten],
          selected: _settings.preferences.measurements,
          onChanged: (value) {
            final newPrefs =
                _settings.preferences.copyWith(measurements: value);
            _saveSettings('preferences', newPrefs.toJson(),
                _settings.copyWith(preferences: newPrefs));
          },
        ),
        const SizedBox(height: 24),
        _buildInfoTile(
            theme, 'Language', _settings.preferences.language.toUpperCase()),
        _buildInfoTile(theme, 'Timezone', _settings.preferences.timezone),
        _buildInfoTile(theme, 'Currency', _settings.preferences.currency),
        _buildInfoTile(theme, 'Date Format', _settings.preferences.dateFormat),
      ],
    );
  }

  // ============ Layout Settings ============
  Widget _buildLayoutSettings(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(theme, 'Default View'),
        const SizedBox(height: 12),
        _buildOptionSelector(
          theme,
          options: ['grid', 'list'],
          labels: ['Grid View', 'List View'],
          icons: [Icons.grid_view, Icons.view_list],
          selected: _settings.layout.defaultView,
          onChanged: (value) {
            final newLayout = _settings.layout.copyWith(defaultView: value);
            _saveSettings('layout', newLayout.toJson(),
                _settings.copyWith(layout: newLayout));
          },
        ),
        const SizedBox(height: 24),
        _buildSectionTitle(theme, 'Display Options'),
        const SizedBox(height: 12),
        _buildSwitchTile(
          theme,
          icon: Icons.view_compact,
          title: 'Compact View',
          subtitle: 'Show more content with smaller elements',
          value: _settings.layout.compactView,
          onChanged: (value) {
            final newLayout = _settings.layout.copyWith(compactView: value);
            _saveSettings('layout', newLayout.toJson(),
                _settings.copyWith(layout: newLayout));
          },
        ),
        _buildSwitchTile(
          theme,
          icon: Icons.menu_open,
          title: 'Collapse Sidebar',
          subtitle: 'Keep sidebar minimized by default',
          value: _settings.layout.sidebarCollapsed,
          onChanged: (value) {
            final newLayout =
                _settings.layout.copyWith(sidebarCollapsed: value);
            _saveSettings('layout', newLayout.toJson(),
                _settings.copyWith(layout: newLayout));
          },
        ),
        _buildSwitchTile(
          theme,
          icon: Icons.school_outlined,
          title: 'Show Tutorials',
          subtitle: 'Display helpful tips and tutorials',
          value: _settings.layout.showTutorials,
          onChanged: (value) {
            final newLayout = _settings.layout.copyWith(showTutorials: value);
            _saveSettings('layout', newLayout.toJson(),
                _settings.copyWith(layout: newLayout));
          },
        ),
      ],
    );
  }

  // ============ Accessibility Settings ============
  Widget _buildAccessibilitySettings(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(theme, 'Visual'),
        const SizedBox(height: 12),
        _buildSwitchTile(
          theme,
          icon: Icons.contrast,
          title: 'High Contrast',
          subtitle: 'Increase contrast for better visibility',
          value: _settings.accessibility.highContrast,
          onChanged: (value) {
            final newAccess =
                _settings.accessibility.copyWith(highContrast: value);
            _saveSettings('accessibility', newAccess.toJson(),
                _settings.copyWith(accessibility: newAccess));
          },
        ),
        _buildSwitchTile(
          theme,
          icon: Icons.animation,
          title: 'Reduced Motion',
          subtitle: 'Minimize animations and transitions',
          value: _settings.accessibility.reducedMotion,
          onChanged: (value) {
            final newAccess =
                _settings.accessibility.copyWith(reducedMotion: value);
            _saveSettings('accessibility', newAccess.toJson(),
                _settings.copyWith(accessibility: newAccess));
          },
        ),
        const SizedBox(height: 24),
        _buildSectionTitle(theme, 'Assistive Technology'),
        const SizedBox(height: 12),
        _buildSwitchTile(
          theme,
          icon: Icons.record_voice_over,
          title: 'Screen Reader Support',
          subtitle: 'Optimize for screen readers',
          value: _settings.accessibility.screenReader,
          onChanged: (value) {
            final newAccess =
                _settings.accessibility.copyWith(screenReader: value);
            _saveSettings('accessibility', newAccess.toJson(),
                _settings.copyWith(accessibility: newAccess));
          },
        ),
        const SizedBox(height: 24),
        _buildSectionTitle(theme, 'Cursor'),
        const SizedBox(height: 12),
        _buildOptionSelector(
          theme,
          options: ['default', 'large'],
          labels: ['Default', 'Large'],
          icons: [Icons.mouse, Icons.mouse],
          selected: _settings.accessibility.cursorSize,
          onChanged: (value) {
            final newAccess =
                _settings.accessibility.copyWith(cursorSize: value);
            _saveSettings('accessibility', newAccess.toJson(),
                _settings.copyWith(accessibility: newAccess));
          },
        ),
      ],
    );
  }

  // ============ Helper Widgets ============
  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildSwitchTile(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(title, style: theme.textTheme.bodyMedium),
        subtitle: Text(subtitle,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6))),
        trailing: Switch.adaptive(
          value: value,
          onChanged: _isSaving ? null : onChanged,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Widget _buildOptionSelector(
    ThemeData theme, {
    required List<String> options,
    required List<String> labels,
    required List<IconData> icons,
    required String selected,
    required ValueChanged<String> onChanged,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(options.length, (index) {
        final isSelected = options[index] == selected;
        // Use onPrimaryContainer for selected state to ensure contrast with primaryContainer background
        final selectedContentColor = theme.colorScheme.onPrimaryContainer;
        final unselectedContentColor = theme.colorScheme.onSurface.withOpacity(0.6);
        
        return GestureDetector(
          onTap: _isSaving ? null : () => onChanged(options[index]),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withOpacity(0.2),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icons[index],
                  size: 18,
                  color: isSelected
                      ? selectedContentColor
                      : unselectedContentColor,
                ),
                const SizedBox(width: 8),
                Text(
                  labels[index],
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isSelected
                        ? selectedContentColor
                        : theme.colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildInfoTile(ThemeData theme, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}
