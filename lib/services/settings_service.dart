import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

class SettingsService {
  static final SettingsService _i = SettingsService._();
  factory SettingsService() => _i;
  SettingsService._();

  final AudioPlayer _bgPlayer = AudioPlayer();
  bool _bgPlaying = false;

  // ===== NOTIFICATIONS PLUGIN =====
  final FlutterLocalNotificationsPlugin _notifPlugin =
  FlutterLocalNotificationsPlugin();
  bool _notifInitialized = false;

  Future<void> _initNotifications() async {
    if (_notifInitialized) return;

    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifPlugin.initialize(initSettings);
    _notifInitialized = true;
    debugPrint('✅ Notifications initialized');
  }

  // ===== PRIVACY & SECURITY =====
  Future<bool> getBiometricLock() async =>
      (await SharedPreferences.getInstance()).getBool('biometric_lock') ?? false;

  Future<void> setBiometricLock(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_lock', v);
    debugPrint('🔒 Biometric Lock: ${v ? "ENABLED" : "DISABLED"}');
  }

  Future<bool> getHideContent() async =>
      (await SharedPreferences.getInstance()).getBool('hide_content') ?? false;

  Future<void> setHideContent(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hide_content', v);
    debugPrint('👁️ Hide Content: ${v ? "ENABLED" : "DISABLED"}');
  }

  Future<bool> getAnalytics() async =>
      (await SharedPreferences.getInstance()).getBool('analytics') ?? true;

  Future<void> setAnalytics(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('analytics', v);
    debugPrint('📊 Analytics: ${v ? "ENABLED" : "DISABLED"}');
  }

  Future<bool> getCrashReporting() async =>
      (await SharedPreferences.getInstance()).getBool('crash_reporting') ?? true;

  Future<void> setCrashReporting(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('crash_reporting', v);
    debugPrint('🐛 Crash Reporting: ${v ? "ENABLED" : "DISABLED"}');
  }

  // ===== NOTIFICATIONS =====
  Future<bool> getNotifications() async =>
      (await SharedPreferences.getInstance()).getBool('notifications') ?? true;

  Future<bool> setNotifications(bool v) async {
    final prefs = await SharedPreferences.getInstance();

    if (v) {
      final PermissionStatus status = await Permission.notification.request();

      if (!status.isGranted) {
        await prefs.setBool('notifications', false);
        debugPrint('⚠️ Notification permission denied by user');
        return false;
      }

      await _initNotifications();
      await prefs.setBool('notifications', true);
      debugPrint('🔔 Notifications ENABLED');
      return true;
    } else {
      await _notifPlugin.cancelAll();
      await prefs.setBool('notifications', false);
      debugPrint('🔕 Notifications DISABLED');
      return false;
    }
  }

  Future<void> showTestNotification() async {
    await _initNotifications();
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'main_channel',
      'Main Channel',
      channelDescription: 'Mystery Box notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const NotificationDetails details =
    NotificationDetails(android: androidDetails);
    await _notifPlugin.show(
      0,
      'Mystery Box 🎁',
      'Notifications are now enabled!',
      details,
    );
  }

  // ===== MUSIC =====
  Future<bool> getMusic() async =>
      (await SharedPreferences.getInstance()).getBool('music') ?? false;

  Future<void> setMusic(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('music', v);
    if (v) {
      await playBgMusic();
    } else {
      await stopBgMusic();
    }
  }

  // ===== HAPTIC =====
  Future<bool> getHaptic() async =>
      (await SharedPreferences.getInstance()).getBool('haptic') ?? true;

  Future<void> setHaptic(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('haptic', v);
  }

  // ===== DATA MANAGEMENT =====
  Future<void> exportUserData() async {
    debugPrint('📤 Exporting user data...');
  }

  Future<void> deleteAccount() async {
    debugPrint('🗑️ Account deletion requested...');
  }

  // ===== AUDIO =====
  Future<void> playBgMusic() async {
    if (_bgPlaying) return;
    try {
      await _bgPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgPlayer.play(AssetSource('audio/bg_music.mp3'));
      _bgPlaying = true;
    } catch (e) {
      debugPrint('BG Music Error: $e');
    }
  }

  Future<void> stopBgMusic() async {
    try {
      await _bgPlayer.stop();
    } catch (e) {
      debugPrint('Stop Music Error: $e');
    }
    _bgPlaying = false;
  }

  Future<void> hapticTap() async {
    if (await getHaptic()) {
      try {
        final hasVibrator = await Vibration.hasVibrator();
        if (hasVibrator == true) {
          Vibration.vibrate(duration: 30);
        }
      } catch (e) {
        debugPrint('Haptic Error: $e');
      }
    }
  }

  void dispose() {
    _bgPlayer.dispose();
  }
}