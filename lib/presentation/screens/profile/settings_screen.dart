import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/bloc_extensions.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Settings values
  bool _pushNotifications = true;
  bool _orderAlerts = true;
  bool _earningsNotifications = true;
  bool _locationSharing = true;
  bool _offlineMode = false;
  bool _soundEffects = true;
  bool _vibration = true;
  bool _darkMode = false;
  String _language = 'English';
  String _mapType = 'Standard';
  String _distanceUnit = 'Kilometers';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _pushNotifications = prefs.getBool('push_notifications') ?? true;
        _orderAlerts = prefs.getBool('order_alerts') ?? true;
        _earningsNotifications = prefs.getBool('earnings_notifications') ?? true;
        _locationSharing = prefs.getBool('location_sharing') ?? true;
        _offlineMode = prefs.getBool('offline_mode') ?? false;
        _soundEffects = prefs.getBool('sound_effects') ?? true;
        _vibration = prefs.getBool('vibration') ?? true;
        _darkMode = prefs.getBool('dark_mode') ?? false;
        _language = prefs.getString('language') ?? 'English';
        _mapType = prefs.getString('map_type') ?? 'Standard';
        _distanceUnit = prefs.getString('distance_unit') ?? 'Kilometers';
      });
    } catch (e) {
      context.showErrorSnackBar('Failed to load settings');
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      }
    } catch (e) {
      context.showErrorSnackBar('Failed to save setting');
    }
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            'English',
            'Spanish',
            'French',
            'German',
            'Italian',
            'Portuguese',
          ].map((language) => RadioListTile<String>(
            title: Text(language),
            value: language,
            groupValue: _language,
            onChanged: (value) {
              setState(() {
                _language = value!;
              });
              _saveSetting('language', value!);
              Navigator.pop(context);
              context.showSuccessSnackBar('Language updated to $value');
            },
            activeColor: AppColors.primary,
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showMapTypeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Map Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            'Standard',
            'Satellite',
            'Hybrid',
            'Terrain',
          ].map((mapType) => RadioListTile<String>(
            title: Text(mapType),
            value: mapType,
            groupValue: _mapType,
            onChanged: (value) {
              setState(() {
                _mapType = value!;
              });
              _saveSetting('map_type', value!);
              Navigator.pop(context);
              context.showSuccessSnackBar('Map type updated to $value');
            },
            activeColor: AppColors.primary,
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showDistanceUnitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Distance Unit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            'Kilometers',
            'Miles',
          ].map((unit) => RadioListTile<String>(
            title: Text(unit),
            value: unit,
            groupValue: _distanceUnit,
            onChanged: (value) {
              setState(() {
                _distanceUnit = value!;
              });
              _saveSetting('distance_unit', value!);
              Navigator.pop(context);
              context.showSuccessSnackBar('Distance unit updated to $value');
            },
            activeColor: AppColors.primary,
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text('Are you sure you want to reset all settings to default values?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              await _loadSettings();
              Navigator.pop(context);
              context.showSuccessSnackBar('Settings reset to defaults');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.surface,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetToDefaults,
            tooltip: 'Reset to defaults',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.spaceM),
        children: [
          _buildNotificationSettings(),
          const SizedBox(height: AppDimensions.spaceL),
          _buildLocationSettings(),
          const SizedBox(height: AppDimensions.spaceL),
          _buildAppSettings(),
          const SizedBox(height: AppDimensions.spaceL),
          _buildDisplaySettings(),
          const SizedBox(height: AppDimensions.spaceL),
          _buildMapSettings(),
          const SizedBox(height: AppDimensions.spaceXL),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return _buildSettingsCard(
      title: 'Notifications',
      icon: Icons.notifications_outlined,
      children: [
        _buildSwitchTile(
          title: 'Push Notifications',
          subtitle: 'Receive push notifications',
          value: _pushNotifications,
          onChanged: (value) {
            setState(() {
              _pushNotifications = value;
            });
            _saveSetting('push_notifications', value);
          },
        ),
        _buildSwitchTile(
          title: 'Order Alerts',
          subtitle: 'Get notified of new delivery orders',
          value: _orderAlerts,
          onChanged: (value) {
            setState(() {
              _orderAlerts = value;
            });
            _saveSetting('order_alerts', value);
          },
        ),
        _buildSwitchTile(
          title: 'Earnings Notifications',
          subtitle: 'Daily and weekly earnings summaries',
          value: _earningsNotifications,
          onChanged: (value) {
            setState(() {
              _earningsNotifications = value;
            });
            _saveSetting('earnings_notifications', value);
          },
        ),
      ],
    );
  }

  Widget _buildLocationSettings() {
    return _buildSettingsCard(
      title: 'Location & Privacy',
      icon: Icons.location_on_outlined,
      children: [
        _buildSwitchTile(
          title: 'Location Sharing',
          subtitle: 'Share location with customers during delivery',
          value: _locationSharing,
          onChanged: (value) {
            setState(() {
              _locationSharing = value;
            });
            _saveSetting('location_sharing', value);
          },
        ),
        _buildSwitchTile(
          title: 'Offline Mode',
          subtitle: 'Work without internet when possible',
          value: _offlineMode,
          onChanged: (value) {
            setState(() {
              _offlineMode = value;
            });
            _saveSetting('offline_mode', value);
          },
        ),
      ],
    );
  }

  Widget _buildAppSettings() {
    return _buildSettingsCard(
      title: 'App Settings',
      icon: Icons.settings_outlined,
      children: [
        _buildSwitchTile(
          title: 'Sound Effects',
          subtitle: 'Play sounds for app interactions',
          value: _soundEffects,
          onChanged: (value) {
            setState(() {
              _soundEffects = value;
            });
            _saveSetting('sound_effects', value);
          },
        ),
        _buildSwitchTile(
          title: 'Vibration',
          subtitle: 'Haptic feedback for notifications',
          value: _vibration,
          onChanged: (value) {
            setState(() {
              _vibration = value;
            });
            _saveSetting('vibration', value);
          },
        ),
        _buildListTile(
          title: 'Language',
          subtitle: _language,
          onTap: _showLanguageDialog,
          trailing: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  Widget _buildDisplaySettings() {
    return _buildSettingsCard(
      title: 'Display',
      icon: Icons.display_settings_outlined,
      children: [
        _buildSwitchTile(
          title: 'Dark Mode',
          subtitle: 'Use dark theme (Coming Soon)',
          value: _darkMode,
          onChanged: (value) {
            // setState(() {
            //   _darkMode = value;
            // });
            // _saveSetting('dark_mode', value);
            context.showInfoSnackBar('Dark mode coming in next update!');
          },
        ),
      ],
    );
  }

  Widget _buildMapSettings() {
    return _buildSettingsCard(
      title: 'Map & Navigation',
      icon: Icons.map_outlined,
      children: [
        _buildListTile(
          title: 'Map Type',
          subtitle: _mapType,
          onTap: _showMapTypeDialog,
          trailing: const Icon(Icons.chevron_right),
        ),
        _buildListTile(
          title: 'Distance Unit',
          subtitle: _distanceUnit,
          onTap: _showDistanceUnitDialog,
          trailing: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  Widget _buildSettingsCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: AppColors.textHint.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spaceM),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spaceS),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppDimensions.spaceM),
                Text(
                  title,
                  style: AppTextStyles.headlineSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceM),
      child: SwitchListTile(
        title: Text(
          title,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceM),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }
}