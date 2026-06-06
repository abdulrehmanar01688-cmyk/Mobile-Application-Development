import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/settings_service.dart';
import '../services/audio_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settings = SettingsService();
  final AudioService _audio = AudioService();

  bool _notifications = true;
  bool _music = false;
  bool _haptic = true;
  bool _biometricLock = false;
  bool _hideContent = false;
  bool _analytics = true;
  bool _crashReporting = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _notifications = await _settings.getNotifications();
    _music = await _settings.getMusic();
    _haptic = await _settings.getHaptic();
    _biometricLock = await _settings.getBiometricLock();
    _hideContent = await _settings.getHideContent();
    _analytics = await _settings.getAnalytics();
    _crashReporting = await _settings.getCrashReporting();
    setState(() {});
  }

  Future<void> _hapticFeedback() async => await _settings.hapticTap();

  Future<void> _handleNotificationToggle(bool newValue) async {
    await _hapticFeedback();
    final bool result = await _settings.setNotifications(newValue);
    if (newValue == true && result == false) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('⚠️ Notification permission denied'),
          backgroundColor: Colors.red[700],
          action: SnackBarAction(
            label: 'Open Settings',
            textColor: Colors.white,
            onPressed: () => openAppSettings(),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
    if (!mounted) return;
    setState(() => _notifications = result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0d0d1a),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        children: [
          _buildSectionHeader('General'),

          SwitchListTile(
            title: const Text('Notifications', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Receive surprise alerts', style: TextStyle(color: Colors.white70)),
            value: _notifications,
            onChanged: _handleNotificationToggle,
            secondary: const Icon(Icons.notifications_active, color: Colors.amber),
            activeColor: Colors.purple,
          ),

          SwitchListTile(
            title: const Text('Background Music', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Play ambient music', style: TextStyle(color: Colors.white70)),
            value: _music,
            onChanged: (v) async {
              await _hapticFeedback();
              setState(() => _music = v);
              await _settings.setMusic(v);
            },
            secondary: const Icon(Icons.music_note, color: Colors.pink),
            activeColor: Colors.purple,
          ),

          SwitchListTile(
            title: const Text('Haptic Feedback', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Vibration on interactions', style: TextStyle(color: Colors.white70)),
            value: _haptic,
            onChanged: (v) async {
              await _hapticFeedback();
              setState(() => _haptic = v);
              await _settings.setHaptic(v);
            },
            secondary: const Icon(Icons.vibration, color: Colors.teal),
            activeColor: Colors.purple,
          ),

          const Divider(color: Colors.white24),
          _buildSectionHeader('Privacy & Security'),

          SwitchListTile(
            title: const Text('Biometric Lock', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Fingerprint/Face ID to open app', style: TextStyle(color: Colors.white70)),
            value: _biometricLock,
            onChanged: (v) async {
              await _hapticFeedback();
              await _audio.playMagicWand();
              setState(() => _biometricLock = v);
              await _settings.setBiometricLock(v);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(v ? '🔒 Biometric lock enabled' : '🔓 Biometric lock disabled'),
                  backgroundColor: v ? Colors.green : Colors.red,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            secondary: const Icon(Icons.fingerprint, color: Colors.cyan),
            activeColor: Colors.purple,
          ),

          SwitchListTile(
            title: const Text('Hide Content in App Switcher', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Blank screen in recent apps', style: TextStyle(color: Colors.white70)),
            value: _hideContent,
            onChanged: (v) async {
              await _hapticFeedback();
              await _audio.playMagicWand();
              setState(() => _hideContent = v);
              await _settings.setHideContent(v);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(v ? '👁️ Content hidden' : '👁️ Content visible'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            secondary: const Icon(Icons.visibility_off, color: Colors.orange),
            activeColor: Colors.purple,
          ),

          SwitchListTile(
            title: const Text('Analytics', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Help us improve the app', style: TextStyle(color: Colors.white70)),
            value: _analytics,
            onChanged: (v) async {
              await _hapticFeedback();
              setState(() => _analytics = v);
              await _settings.setAnalytics(v);
            },
            secondary: const Icon(Icons.analytics, color: Colors.green),
            activeColor: Colors.purple,
          ),

          SwitchListTile(
            title: const Text('Crash Reporting', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Send anonymous crash reports', style: TextStyle(color: Colors.white70)),
            value: _crashReporting,
            onChanged: (v) async {
              await _hapticFeedback();
              setState(() => _crashReporting = v);
              await _settings.setCrashReporting(v);
            },
            secondary: const Icon(Icons.bug_report, color: Colors.red),
            activeColor: Colors.purple,
          ),

          const Divider(color: Colors.white24),
          _buildSectionHeader('Data Management'),

          ListTile(
            title: const Text('Export My Data', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Download a copy of your data', style: TextStyle(color: Colors.white70)),
            leading: const Icon(Icons.download, color: Colors.amber),
            onTap: () async {
              await _hapticFeedback();
              await _audio.playSuccess();
              await _settings.exportUserData();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('📤 Preparing your data export...')),
              );
            },
          ),

          ListTile(
            title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
            subtitle: const Text('Permanently remove your account', style: TextStyle(color: Colors.redAccent)),
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            onTap: () => _showDeleteAccountDialog(context),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.purple[300],
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text('Delete Account?', style: TextStyle(color: Colors.red)),
        content: const Text(
          'This action cannot be undone. All your data will be permanently deleted.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _settings.deleteAccount();
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🗑️ Account deletion requested'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}