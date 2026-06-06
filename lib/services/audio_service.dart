import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _bgPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final List<AudioPlayer> _popPlayers = List.generate(5, (_) => AudioPlayer());
  int _popIndex = 0;

  bool _soundEnabled = true;
  bool _isBgPlaying = false;
  bool _initialized = false;

  final Map<String, String> _soundMap = {
    'pop':          'sounds/pop.mp3',
    'box_open':     'sounds/box_open.mp3',
    'celebration':  'sounds/celebration.mp3',
    'magic':        'sounds/magic.mp3',
    'magic_wand':   'sounds/magic_wand.mp3',
    'alarm':        'sounds/alarm.mp3',
    'boing':        'sounds/boing.mp3',
    'joker_faaaa':  'sounds/joker_faaaa.mp3',
    'laugh':        'sounds/laugh.mp3',
    'notification': 'sounds/notification.mp3',
    'success':      'sounds/success.mp3',
    'ta_da':        'sounds/ta_da.mp3',
    'tap':          'sounds/notification.mp3',
    'bg_music':     'audio/bg_music.mp3',
    'party':        'audio/party.mp3',
  };

  // ✅ Startup pe check karo ke files exist karti hain
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    for (final entry in _soundMap.entries) {
      try {
        await rootBundle.load('assets/${entry.value}');
        debugPrint('✅ File exists: assets/${entry.value}');
      } catch (e) {
        debugPrint('❌ FILE MISSING: assets/${entry.value}');
      }
    }
  }

  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    if (!enabled) await stopAllSounds();
  }

  bool get isSoundEnabled => _soundEnabled;

  Future<void> playPop() async {
    if (!_soundEnabled) return;
    try {
      final player = _popPlayers[_popIndex % _popPlayers.length];
      _popIndex++;
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setVolume(1.0);
      await player.play(AssetSource('sounds/pop.mp3'));
      debugPrint('✅ Pop played');
    } catch (e) {
      debugPrint('❌ Pop error: $e');
    }
  }

  Future<void> playSound(String soundName) async {
    if (!_soundEnabled) return;
    final path = _soundMap[soundName];
    if (path == null) {
      debugPrint('❌ Sound not found: $soundName');
      return;
    }
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.setVolume(1.0);
      await _sfxPlayer.play(AssetSource(path));
      debugPrint('✅ Sound: $soundName');
    } catch (e) {
      debugPrint('❌ Error $soundName: $e');
    }
  }

  Future<void> playSoundEffect(String assetPath) async {
    if (!_soundEnabled) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource(assetPath));
    } catch (e) {
      debugPrint('❌ Effect error: $e');
    }
  }

  Future<void> playBackgroundMusic(String soundName) async {
    if (!_soundEnabled) return;
    String path = _soundMap.containsKey(soundName)
        ? _soundMap[soundName]!
        : soundName;
    try {
      await _bgPlayer.stop();
      await _bgPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgPlayer.setVolume(0.4);
      await _bgPlayer.play(AssetSource(path));
      _isBgPlaying = true;
    } catch (e) {
      debugPrint('❌ BG error: $e');
    }
  }

  Future<void> stopBackgroundMusic() async {
    try { await _bgPlayer.stop(); _isBgPlaying = false; } catch (_) {}
  }

  Future<void> pauseBackgroundMusic() async {
    try { await _bgPlayer.pause(); } catch (_) {}
  }

  Future<void> resumeBackgroundMusic() async {
    try { await _bgPlayer.resume(); } catch (_) {}
  }

  Future<void> playBoxOpen() async      => playSound('box_open');
  Future<void> playCelebration() async  => playSound('celebration');
  Future<void> playMagic() async        => playSound('magic');
  Future<void> playMagicWand() async    => playSound('magic_wand');
  Future<void> playNotification() async => playSound('notification');
  Future<void> playSuccess() async      => playSound('success');
  Future<void> playJokerFaaaa() async   => playSound('joker_faaaa');
  Future<void> playAlarm() async        => playSound('alarm');
  Future<void> playLaugh() async        => playSound('laugh');
  Future<void> playBoing() async        => playSound('boing');
  Future<void> playTaDa() async         => playSound('ta_da');

  Future<void> stopAllSounds() async {
    try {
      await _sfxPlayer.stop();
      await _bgPlayer.stop();
      _isBgPlaying = false;
    } catch (_) {}
  }

  void dispose() {
    for (final p in _popPlayers) { p.dispose(); }
    _sfxPlayer.dispose();
    _bgPlayer.dispose();
  }
}