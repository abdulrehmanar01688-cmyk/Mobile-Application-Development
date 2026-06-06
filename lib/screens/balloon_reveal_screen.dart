import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:confetti/confetti.dart';
import '../models/box_model.dart';
import '../providers/box_provider.dart';
import '../services/audio_service.dart';
import 'completion_screen.dart';
import 'package:provider/provider.dart';

class BalloonItem {
  final String id;
  final Color color;
  final Surprise? surprise;
  final double left;
  final double top;
  bool isBurst;
  final BalloonSpecialType special;

  BalloonItem({
    required this.id,
    required this.color,
    this.surprise,
    required this.left,
    required this.top,
    this.isBurst = false,
    this.special = BalloonSpecialType.normal,
  });
}

enum BalloonSpecialType { normal, nested, teddy, joker }

class BalloonRevealScreen extends StatefulWidget {
  const BalloonRevealScreen({super.key});

  @override
  State<BalloonRevealScreen> createState() => _BalloonRevealScreenState();
}

class _BalloonRevealScreenState extends State<BalloonRevealScreen>
    with TickerProviderStateMixin {

  final List<BalloonItem> _balloons = [];
  final Random _random = Random();
  final AudioPlayer _voicePlayer = AudioPlayer();
  final AudioPlayer _directPopPlayer = AudioPlayer();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  late ConfettiController _confettiController;

  int _currentBalloonIndex = 0;
  bool _revealInProgress = false;
  bool _allDone = false;
  String _receiverName = '';
  bool _prankShown = false;

  // ✅ FIX: Prank ke liye dedicated flag — double call rokta hai
  bool _prankRevealShown = false;
  Timer? _prankAutoTimer;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 4));
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeBalloons());
  }

  void _initializeBalloons() {
    final box = context.read<BoxProvider>().currentBox;
    if (box == null) return;

    _receiverName = box.receiverName;
    _prankShown = false;
    _prankRevealShown = false;
    _currentBalloonIndex = 0;
    _allDone = false;
    _revealInProgress = false;
    _balloons.clear();

    final colors = [
      Colors.red[400]!, Colors.blue[400]!, Colors.green[400]!, Colors.purple[400]!,
      Colors.orange[400]!, Colors.pink[400]!, Colors.teal[400]!, Colors.indigo[400]!,
      Colors.amber[400]!, Colors.cyan[400]!,
    ];

    final surprises = box.surprises;
    final positions = _generatePositions();

    for (int i = 0; i < 10; i++) {
      BalloonSpecialType special = BalloonSpecialType.normal;
      if (i == 9) special = BalloonSpecialType.nested;
      else if (i == 4) special = BalloonSpecialType.teddy;
      else if (i == 2) special = BalloonSpecialType.joker;

      _balloons.add(BalloonItem(
        id: 'b$i',
        color: colors[i],
        surprise: i < surprises.length ? surprises[i] : null,
        left: positions[i].dx,
        top: positions[i].dy,
        special: special,
      ));
    }
    setState(() {});
  }

  List<Offset> _generatePositions() {
    return List.generate(10, (i) => const Offset(130, 240));
  }

  void _onBalloonTap(int i) {
    if (_revealInProgress) return;
    if (i != _currentBalloonIndex) return;
    if (_balloons[i].isBurst) return;

    _directPopPlayer.play(AssetSource('sounds/pop.mp3'));
    _confettiController.play();

    setState(() {
      _balloons[i].isBurst = true;
      _revealInProgress = true;
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _showSurpriseForBalloon(i);
    });
  }

  void _showSurpriseForBalloon(int i) {
    final balloon = _balloons[i];
    switch (balloon.special) {
      case BalloonSpecialType.joker:
        _showJokerBottle(i);
        break;
      case BalloonSpecialType.teddy:
        _showTeddyReveal(i);
        break;
      case BalloonSpecialType.nested:
        _showNestedBalloons(i);
        break;
      case BalloonSpecialType.normal:
        if (balloon.surprise != null) {
          _showSurprisePopup(balloon.surprise!, balloon.color, i);
        } else {
          _onRevealClosed(i);
        }
    }
  }

  void _onRevealClosed(int i) {
    if (!mounted) return;
    setState(() => _revealInProgress = false);

    final next = i + 1;
    if (next >= 10) {
      setState(() => _allDone = true);
      AudioService().playTaDa();
      Future.delayed(const Duration(seconds: 1), _goToCompletion);
    } else {
      // ✅ FIX: Prank sirf balloon index 4 ke baad, ek hi baar
      if (next == 5 && !_prankShown && i == 4) {
        _prankShown = true;
        _prankRevealShown = false; // ✅ Reset for fresh prank flow
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) return;
          _showPrankWarning(onDone: () {
            if (mounted) setState(() => _currentBalloonIndex = next);
          });
        });
      } else {
        setState(() => _currentBalloonIndex = next);
      }
    }
  }

  void _goToCompletion() {
    if (!mounted) return;
    AudioService().stopBackgroundMusic();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const CompletionScreen()),
    );
  }

  void _showJokerBottle(int idx) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _JokerBottleDialog(
        onDone: () { Navigator.pop(ctx); _onRevealClosed(idx); },
      ),
    );
  }

  void _showTeddyReveal(int idx) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _TeddyRevealDialog(
        receiverName: _receiverName,
        onDone: () { Navigator.pop(ctx); _onRevealClosed(idx); },
      ),
    );
  }

  void _showNestedBalloons(int idx) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _NestedBalloonsDialog(
        receiverName: _receiverName,
        onDone: () { Navigator.pop(ctx); _onRevealClosed(idx); },
      ),
    );
  }

  void _showPrankWarning({required VoidCallback onDone}) {
    AudioService().playAlarm();

    // ✅ FIX: Timer cancel karo agar pehle se chal raha ho
    _prankAutoTimer?.cancel();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: _PrankHackScreen(
            onReveal: () {
              // ✅ FIX: Timer cancel — user ne khud tap kiya
              _prankAutoTimer?.cancel();
              Navigator.pop(ctx);
              AudioService().stopAllSounds();
              // ✅ FIX: Guard se double call rok do
              if (!_prankRevealShown) {
                _prankRevealShown = true;
                _showPrankReveal(onDone: onDone);
              }
            },
          ),
        ),
      ),
    );

    // ✅ FIX: Auto-dismiss — sirf ek baar chalega
    _prankAutoTimer = Timer(const Duration(seconds: 6), () {
      if (!mounted) return;
      // ✅ Dialog band karo
      try { Navigator.of(context, rootNavigator: true).pop(); } catch (_) {}
      AudioService().stopAllSounds();
      // ✅ FIX: Guard se double call rok do
      if (!_prankRevealShown) {
        _prankRevealShown = true;
        _showPrankReveal(onDone: onDone);
      }
    });
  }

  void _showPrankReveal({required VoidCallback onDone}) {
    // ✅ Sirf laugh — jokerFaaaa NAHI yahan
    AudioService().playLaugh();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('😂🤣😂', style: TextStyle(fontSize: 60))
                .animate(onPlay: (c) => c.repeat()).shake(duration: 300.ms),
            const SizedBox(height: 16),
            const Text(
              'HAHA! 🎭\nYour phone is totally fine! 😄\n\nIt was just a little prank!',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  onDone();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple[600]),
                child: const Text('😂 Haha OK! Continue →'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── SURPRISE POPUP ─────────────────────────────────────

  void _showSurprisePopup(Surprise surprise, Color color, int idx) {
    final bool isVideo = surprise.type == SurpriseType.video;
    final ValueNotifier<bool> canProceed = ValueNotifier<bool>(!isVideo);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          decoration: BoxDecoration(
            color: const Color(0xFF1a1a2e),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withOpacity(0.5), width: 2),
            boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 30, spreadRadius: 5)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '🎉 Surprise #${idx + 1}!',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amber[400]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ValueListenableBuilder<bool>(
                      valueListenable: canProceed,
                      builder: (_, ready, __) => GestureDetector(
                        onTap: !ready ? null : () { Navigator.pop(ctx); _onRevealClosed(idx); },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(ready ? 0.1 : 0.03),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close, color: ready ? Colors.white : Colors.white24, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      _buildSurpriseContent(surprise, color, idx, onAllVideosDone: () {
                        canProceed.value = true;
                        // ⭐ miniGift complete hone pe dialog close + next balloon
                        if (surprise.type == SurpriseType.miniGift) {
                          Future.delayed(const Duration(milliseconds: 300), () {
                            if (mounted) {
                              Navigator.pop(ctx);        // ✅ Parent dialog close
                              _onRevealClosed(idx);       // ✅ Next balloon lao
                            }
                          });
                        }
                      }),
                      const SizedBox(height: 16),

                      // ⭐ Button sirf non-miniGift types ke liye
                      if (surprise.type != SurpriseType.miniGift)
                        ValueListenableBuilder<bool>(
                          valueListenable: canProceed,
                          builder: (_, ready, __) => SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: !ready ? null : () { Navigator.pop(ctx); _onRevealClosed(idx); },
                              icon: Icon(ready ? Icons.arrow_forward : Icons.hourglass_top),
                              label: Text(!ready
                                  ? 'Wait until all the videos are finished…...'
                                  : (idx == 9 ? '🎊 Finish!' : 'Next Balloon 🎈')),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ready ? color : Colors.grey[700],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ).animate().scale(duration: 400.ms, curve: Curves.elasticOut).fadeIn(duration: 300.ms),
      ),
    );
  }

  Widget _buildSurpriseContent(Surprise surprise, Color color, int idx, {VoidCallback? onAllVideosDone}) {
    switch (surprise.type) {
      case SurpriseType.image:
        if (surprise.mediaUrl != null && surprise.mediaUrl!.isNotEmpty) {
          final url = surprise.mediaUrl!;
          if (url.startsWith('http')) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                url,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (ctx, child, progress) => progress == null
                    ? child
                    : Container(
                  height: 200,
                  color: Colors.black,
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
                errorBuilder: (ctx, err, stack) => _iconDisplay(
                    Icons.image, Colors.blue, '📸 The photo hasn’t loaded'),
              ),
            );
          } else {
            // Phone par local file
            try {
              final file = File(url);
              if (file.existsSync()) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(file, width: double.infinity, fit: BoxFit.cover),
                );
              }
            } catch (_) {}
          }
        }
        return _iconDisplay(Icons.image, Colors.blue, '📸 Photo Surprise!');

      case SurpriseType.video:
        if (surprise.mediaUrl != null) {
          final allPaths = surprise.mediaUrl!.split('|||').where((p) => p.isNotEmpty).toList();
          // Web URLs
          final webPaths = allPaths.where((p) => p.startsWith('http')).toList();
          // Local files
          final localPaths = allPaths.where((p) => !p.startsWith('http') && File(p).existsSync()).toList();
          final paths = webPaths.isNotEmpty ? webPaths : localPaths;
          if (paths.isNotEmpty) {
            return _VideoSequencePlayer(
              paths: paths,
              onAllDone: () { if (onAllVideosDone != null) onAllVideosDone(); },
            );
          }
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (onAllVideosDone != null) onAllVideosDone();
        });
        return _iconDisplay(Icons.videocam, Colors.red, '🎬 Video Surprise!');

      case SurpriseType.message:
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.withOpacity(0.4)),
          ),
          child: Column(children: [
            Icon(Icons.message, size: 50, color: Colors.green[400]),
            const SizedBox(height: 12),
            Text(
              surprise.content ?? 'A special message!',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ]),
        );

      case SurpriseType.voiceNote:
        return _buildVoiceWidget(surprise, color);

      case SurpriseType.mindGame:
      case SurpriseType.funnyPopup:
      case SurpriseType.jokerAnimation:
        return _MindGameQuiz(
          onComplete: () { if (onAllVideosDone != null) onAllVideosDone(); },
        );

      case SurpriseType.soundEffect:
        return const _MagicianCakeWidget();

      case SurpriseType.miniGift:
        return _NestedGiftWidget(
          totalLevels: 10,
          note: surprise.content ?? '',
          onComplete: onAllVideosDone!,           // ⭐ ADD YEH LINE
        );
}
}

  Widget _buildVoiceWidget(Surprise surprise, Color color) {
    return StatefulBuilder(
      builder: (context, setLocalState) {
        bool isPlaying = false;
        final String? recordedPath = surprise.mediaUrl;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange.withOpacity(0.4)),
          ),
          child: Column(children: [
            Icon(Icons.mic, size: 60, color: Colors.orange[400]),
            const SizedBox(height: 8),
            Text('🎙️ Voice Message!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange[300])),
            const SizedBox(height: 16),
            if (recordedPath != null && (recordedPath.startsWith('http') || File(recordedPath).existsSync()))
              ElevatedButton.icon(
                onPressed: () async {
                  if (isPlaying) {
                    await _voicePlayer.stop();
                    setLocalState(() => isPlaying = false);
                  } else {
                    await _voicePlayer.play(
                        recordedPath.startsWith('http')
                            ? UrlSource(recordedPath)
                            : DeviceFileSource(recordedPath)
                    );
                    setLocalState(() => isPlaying = true);
                    _voicePlayer.onPlayerComplete.listen((_) {
                      if (mounted) setLocalState(() => isPlaying = false);
                    });
                  }
                },
                icon: Icon(isPlaying ? Icons.stop : Icons.play_arrow),
                label: Text(isPlaying ? 'Stop' : 'Play Voice 🎵'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[600]),
              ),
          ]),
        );
      },
    );
  }

  Widget _iconDisplay(IconData icon, Color color, String label) {
    return Column(children: [
      Icon(icon, size: 80, color: color),
      const SizedBox(height: 8),
      Text(label, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
    ]);
  }

  @override
  void dispose() {
    _prankAutoTimer?.cancel();
    _directPopPlayer.dispose();
    _voicePlayer.dispose();
    _recorder.closeRecorder();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0d0d1a),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0d0d1a), Color(0xFF1a0d3a), Color(0xFF0d0d1a)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 40,
              gravity: 0.3,
              colors: const [Colors.red, Colors.blue, Colors.green, Colors.purple, Colors.orange, Colors.pink],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🎈 Pop the Balloons!',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.amber[400])),
                  Text(
                    'Balloon ${_currentBalloonIndex + 1} / 10 • Pop them one by one!',
                    style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.6)),
                  ),
                ],
              ),
            ),
          ),
          if (_balloons.isNotEmpty && !_allDone)
            Positioned.fill(
              child: Center(
                child: Builder(builder: (_) {
                  if (_currentBalloonIndex >= _balloons.length) return const SizedBox.shrink();
                  final b = _balloons[_currentBalloonIndex];
                  return AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: b.isBurst ? 0 : 1,
                    child: GestureDetector(
                      onTap: () => _onBalloonTap(_currentBalloonIndex),
                      child: _buildBalloon(b, _currentBalloonIndex),
                    ),
                  );
                }),
              ),
            ),
          if (_allDone)
            Positioned(
              bottom: 30, left: 16, right: 16,
              child: ElevatedButton.icon(
                onPressed: _goToCompletion,
                icon: const Icon(Icons.celebration),
                label: const Text('See All Gifts! 🎁'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple[600],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ).animate().fadeIn(duration: 500.ms).scale(duration: 500.ms, curve: Curves.elasticOut),
            ),
        ],
      ),
    );
  }

  Widget _buildBalloon(BalloonItem b, int index) {
    String emoji;
    if (b.special == BalloonSpecialType.nested) emoji = '🎊';
    else if (b.special == BalloonSpecialType.teddy) emoji = '🧸';
    else if (b.special == BalloonSpecialType.joker) emoji = '🃏';
    else emoji = '${index + 1}';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 110,
          height: 135,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [b.color.withOpacity(0.7), b.color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(55),
            boxShadow: [
              BoxShadow(color: b.color.withOpacity(0.6), blurRadius: 25, spreadRadius: 6),
              BoxShadow(color: Colors.white.withOpacity(0.2), blurRadius: 20, spreadRadius: 3),
            ],
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 40,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 4)])),
                Text('Tap!', style: TextStyle(fontSize: 13,
                    color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        Container(width: 3, height: 60, color: Colors.white38),
      ],
    ).animate(onPlay: (c) => c.repeat())
        .moveY(begin: 0, end: -18, duration: Duration(milliseconds: 1300 + index * 80))
        .then()
        .moveY(begin: -18, end: 0, duration: Duration(milliseconds: 1300 + index * 80));
  }
}

// ─────────────────────────────────────────────────────────
// VIDEO SEQUENCE PLAYER
// ─────────────────────────────────────────────────────────
class _VideoSequencePlayer extends StatefulWidget {
  final List<String> paths;
  final VoidCallback onAllDone;
  const _VideoSequencePlayer({required this.paths, required this.onAllDone});

  @override
  State<_VideoSequencePlayer> createState() => _VideoSequencePlayerState();
}

class _VideoSequencePlayerState extends State<_VideoSequencePlayer> {
  VideoPlayerController? _controller;
  int _currentIndex = 0;
  bool _initializing = true;
  bool _allDone = false;
  bool _hasStartedPlaying = false;

  @override
  void initState() { super.initState(); _loadVideo(0); }

  Future<void> _loadVideo(int index) async {
    if (mounted) setState(() { _initializing = true; _hasStartedPlaying = false; });
    if (_controller != null) {
      _controller!.removeListener(_videoListener);
      try { await _controller!.pause(); } catch (_) {}
      try { await _controller!.dispose(); } catch (_) {}
      _controller = null;
    }
    final c = widget.paths[index].startsWith('http')
        ? VideoPlayerController.networkUrl(Uri.parse(widget.paths[index]))
        : VideoPlayerController.file(File(widget.paths[index]));
    try {
      await c.initialize();
      await c.setVolume(1.0);
      await c.setLooping(false);
      c.addListener(_videoListener);
      if (!mounted) { c.dispose(); return; }
      setState(() { _controller = c; _currentIndex = index; _initializing = false; });
      await c.play();
    } catch (e) {
      debugPrint('Video init error: $e');
      if (mounted) setState(() { _initializing = false; });
    }
  }

  void _videoListener() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (c.value.isPlaying) _hasStartedPlaying = true;
    if (mounted) setState(() {});

    // Web par position-based check
    final isNearEnd = c.value.duration > Duration.zero &&
        c.value.position.inMilliseconds > 0 &&
        c.value.duration.inMilliseconds > 0 &&
        c.value.position.inMilliseconds >=
            (c.value.duration.inMilliseconds - 800);

    if ((_hasStartedPlaying &&
        c.value.duration > Duration.zero &&
        !c.value.isPlaying &&
        !c.value.isBuffering) || isNearEnd) {
      _hasStartedPlaying = false;
      if (_currentIndex + 1 < widget.paths.length) {
        _loadVideo(_currentIndex + 1);
      } else if (!_allDone) {
        _allDone = true;
        widget.onAllDone();
        if (mounted) setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_videoListener);
    try { _controller?.pause(); } catch (_) {}
    try { _controller?.dispose(); } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final isReady = controller != null && controller.value.isInitialized && !_initializing;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.paths.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text('Video ${_currentIndex + 1} / ${widget.paths.length}',
                style: TextStyle(color: Colors.amber[300], fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: isReady
              ? AspectRatio(aspectRatio: controller.value.aspectRatio, child: VideoPlayer(controller))
              : Container(width: double.infinity, height: 220, color: Colors.black,
              child: const Center(child: CircularProgressIndicator(color: Colors.white))),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: !isReady ? null : () {
            setState(() {
              if (controller.value.isPlaying) { controller.pause(); }
              else { controller.setVolume(1.0); controller.play(); }
            });
          },
          icon: Icon((controller?.value.isPlaying ?? false) ? Icons.pause : Icons.play_arrow),
          label: Text((controller?.value.isPlaying ?? false) ? 'Pause' : 'Play'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600]),
        ),
        // ✅ Manual Next button — video khatam hone ke baad bhi use kar sakte hain
        if (!_allDone)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton.icon(
              onPressed: () {
                if (_currentIndex + 1 < widget.paths.length) {
                  _loadVideo(_currentIndex + 1);
                } else {
                  _allDone = true;
                  widget.onAllDone();
                  if (mounted) setState(() {});
                }
              },
              icon: const Icon(Icons.skip_next, color: Colors.white54),
              label: Text('Skip / Next →',
                  style: TextStyle(color: Colors.white54, fontSize: 11)),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// PRANK HACK SCREEN
// ─────────────────────────────────────────────────────────

class _PrankHackScreen extends StatelessWidget {
  final VoidCallback onReveal;
  const _PrankHackScreen({required this.onReveal});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text('⚠️ SYSTEM ALERT ⚠️',
              style: TextStyle(color: Colors.red[400], fontSize: 22,
                  fontWeight: FontWeight.bold, fontFamily: 'monospace'))
              .animate(onPlay: (c) => c.repeat()).fadeIn(duration: 300.ms).then().fadeOut(duration: 300.ms),
          const SizedBox(height: 20),
          ...[
            'Scanning device...',
            'Accessing contacts... ✓',
            'Reading messages... ✓',
            'Uploading data... ████░░ 67%',
            'Deleting files... ⚡',
            'System compromised!',
          ].asMap().entries.map((e) {
            return Text('> ${e.value}',
                style: TextStyle(color: Colors.green[400], fontSize: 14, fontFamily: 'monospace'))
                .animate(delay: (e.key * 600).ms).fadeIn(duration: 400.ms).slideX(begin: -0.2, end: 0);
          }),
          const SizedBox(height: 30),
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.red, width: 3),
                  borderRadius: BorderRadius.circular(12)),
              child: Text('💀 YOUR PHONE IS HACKED! 💀',
                  style: TextStyle(color: Colors.red[300], fontSize: 20,
                      fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                  textAlign: TextAlign.center)
                  .animate(onPlay: (c) => c.repeat()).shake(duration: 500.ms),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text('🔊 BEEP BEEP BEEP...',
                style: TextStyle(color: Colors.red[300], fontSize: 18, fontFamily: 'monospace'))
                .animate(onPlay: (c) => c.repeat()).fadeIn(duration: 200.ms).then().fadeOut(duration: 200.ms),
          ),
          const Spacer(),
          Center(
            child: TextButton(
              onPressed: onReveal,
              child: Text('JUST KIDDING! 😂 Tap here!',
                  style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 12)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// JOKER BOTTLE DIALOG
// ─────────────────────────────────────────────────────────

class _JokerBottleDialog extends StatefulWidget {
  final VoidCallback onDone;
  const _JokerBottleDialog({required this.onDone});

  @override
  State<_JokerBottleDialog> createState() => _JokerBottleDialogState();
}

class _JokerBottleDialogState extends State<_JokerBottleDialog>
    with TickerProviderStateMixin {
  bool _jokerOut = false;
  late AnimationController _shakeCtrl;
  late AnimationController _bounceCtrl;
  Timer? _boingTimer;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(duration: const Duration(milliseconds: 400), vsync: this);
    _bounceCtrl = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      _shakeCtrl.repeat();
      AudioService().playBoing();
      _boingTimer = Timer.periodic(const Duration(milliseconds: 2500), (t) {
        if (!mounted || _jokerOut) { t.cancel(); return; }
        AudioService().playBoing();
      });
    });
  }

  @override
  void dispose() {
    _boingTimer?.cancel();
    _shakeCtrl.dispose();
    _bounceCtrl.dispose();
    super.dispose();
  }

  void _tapBottle() {
    if (_jokerOut) return;
    _boingTimer?.cancel();
    _shakeCtrl.stop();
    AudioService().playBoing();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) AudioService().playJokerFaaaa();
    });
    _bounceCtrl.forward();
    setState(() => _jokerOut = true);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1a1a2e),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🃏 Tap the Bottle!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.amber[400])),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _tapBottle,
              child: AnimatedBuilder(
                animation: _shakeCtrl,
                builder: (context, child) => Transform.rotate(
                  angle: _jokerOut ? 0 : sin(_shakeCtrl.value * pi * 6) * 0.15,
                  child: child,
                ),
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Container(
                      width: 80, height: 130,
                      margin: const EdgeInsets.only(top: 30),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B0000), Color(0xFFFF4444)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.5), blurRadius: 20)],
                      ),
                      child: const Center(child: Text('🎭', style: TextStyle(fontSize: 36))),
                    ),
                    Container(
                      width: 30, height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF8B0000), Color(0xFFFF4444)]),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      ),
                    ),
                    if (!_jokerOut)
                      Positioned(
                        top: 0,
                        child: Container(
                          width: 36, height: 20,
                          decoration: BoxDecoration(
                              color: Colors.brown[400], borderRadius: BorderRadius.circular(4)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (_jokerOut)
              AnimatedBuilder(
                animation: _bounceCtrl,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, -120 * _bounceCtrl.value),
                  child: Opacity(opacity: _bounceCtrl.value, child: child),
                ),
                child: Column(
                  children: [
                    const Text('🤡', style: TextStyle(fontSize: 80))
                        .animate(onPlay: (c) => c.repeat())
                        .rotate(duration: 1000.ms)
                        .scale(begin: const Offset(0.5, 0.5), end: const Offset(1.2, 1.2), duration: 500.ms)
                        .then()
                        .scale(begin: const Offset(1.2, 1.2), end: const Offset(1.0, 1.0), duration: 300.ms),
                    const SizedBox(height: 8),
                    Text('BOO! 😱\nWhy so serious?! 😂',
                        style: TextStyle(color: Colors.yellow[300], fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center).animate().fadeIn(duration: 400.ms),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: widget.onDone,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.purple[700]),
                      child: const Text('😂 Haha! Next →'),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text('tap on Bottle! 👆',
                    style: TextStyle(color: Colors.white.withOpacity(0.7))),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// TEDDY REVEAL DIALOG
// ─────────────────────────────────────────────────────────

class _TeddyRevealDialog extends StatefulWidget {
  final String receiverName;
  final VoidCallback onDone;
  const _TeddyRevealDialog({required this.receiverName, required this.onDone});

  @override
  State<_TeddyRevealDialog> createState() => _TeddyRevealDialogState();
}

class _TeddyRevealDialogState extends State<_TeddyRevealDialog>
    with TickerProviderStateMixin {
  bool _opened = false;
  late AnimationController _bounceCtrl;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) AudioService().playMagic();
    });
  }

  @override
  void dispose() { _bounceCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1a1a2e),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Colors.pink, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🧸 Special Surprise!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.pink[300])),
            const SizedBox(height: 20),
            if (!_opened) ...[
              GestureDetector(
                onTap: () {
                  setState(() => _opened = true);
                  _bounceCtrl.forward();
                  AudioService().playMagic();
                },
                child: Container(
                  width: 140, height: 140,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.pink[800]!, Colors.pink[600]!]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.pink.withOpacity(0.5), blurRadius: 20)],
                  ),
                  child: const Center(child: Text('🎀', style: TextStyle(fontSize: 60))),
                ),
              ).animate(onPlay: (c) => c.repeat()).shake(duration: 800.ms),
              const SizedBox(height: 16),
              Text('Tap to open! 💕', style: TextStyle(color: Colors.pink[200])),
            ] else ...[
              AnimatedBuilder(
                animation: _bounceCtrl,
                builder: (context, child) =>
                    Transform.scale(scale: 0.5 + (_bounceCtrl.value * 0.5), child: child),
                child: Column(
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
                      Text('🌸', style: TextStyle(fontSize: 32)),
                      Text('🌺', style: TextStyle(fontSize: 28)),
                      Text('🌸', style: TextStyle(fontSize: 32)),
                    ]).animate(onPlay: (c) => c.repeat())
                        .moveY(begin: -5, end: 5, duration: 1200.ms)
                        .then().moveY(begin: 5, end: -5, duration: 1200.ms),
                    const SizedBox(height: 8),
                    Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        const Text('🧸', style: TextStyle(fontSize: 100)),
                        Positioned(
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.pink[700],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                            child: Text('💕 ${widget.receiverName}',
                                style: const TextStyle(color: Colors.white,
                                    fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                        ),
                      ],
                    ).animate(onPlay: (c) => c.repeat())
                        .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.05, 1.05), duration: 1000.ms)
                        .then().scale(begin: const Offset(1.05, 1.05), end: const Offset(0.95, 0.95), duration: 1000.ms),
                    const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
                      Text('🌷', style: TextStyle(fontSize: 28)),
                      Text('💐', style: TextStyle(fontSize: 32)),
                      Text('🌷', style: TextStyle(fontSize: 28)),
                    ]),
                    const SizedBox(height: 16),
                    Text(
                      'just for u! 💝\n${widget.receiverName} teddy! 🧸',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: widget.onDone,
                icon: const Icon(Icons.favorite),
                label: const Text('Aww! Next 🎈'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink[600],
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// NESTED BALLOONS DIALOG — Balloon 10
// ─────────────────────────────────────────────────────────

class _NestedBalloonsDialog extends StatefulWidget {
  final VoidCallback onDone;
  final String receiverName;
  const _NestedBalloonsDialog({required this.onDone, required this.receiverName});

  @override
  State<_NestedBalloonsDialog> createState() => _NestedBalloonsDialogState();
}

class _NestedBalloonsDialogState extends State<_NestedBalloonsDialog>
    with TickerProviderStateMixin {
  int _phase = 0;
  List<int> _puzzleTiles = [];
  final List<int> _targetTiles = [1, 2, 3, 4, 5, 6, 7, 8, 0];
  bool _puzzleSolved = false;
  late List<bool> _nameBalloonPopped;
  late List<String> _nameLetters;
  late AnimationController _finaleCtrl;

  @override
  void initState() {
    super.initState();
    _finaleCtrl = AnimationController(duration: const Duration(seconds: 2), vsync: this);
    _initPuzzle();
    _initNameBalloons();
  }

  void _initPuzzle() {
    _puzzleTiles = List.generate(9, (i) => i);
    do { _puzzleTiles.shuffle(); } while (!_isSolvable(_puzzleTiles));
  }

  bool _isSolvable(List<int> tiles) {
    int inversions = 0;
    for (int i = 0; i < tiles.length; i++) {
      for (int j = i + 1; j < tiles.length; j++) {
        if (tiles[i] != 0 && tiles[j] != 0 && tiles[i] > tiles[j]) inversions++;
      }
    }
    return inversions % 2 == 0;
  }

  void _initNameBalloons() {
    final name = widget.receiverName.toUpperCase().replaceAll(' ', '');
    _nameLetters = name.isEmpty ? ['🎈', '💕', '🌟', '🎊', '✨'] : name.split('');
    _nameBalloonPopped = List.filled(_nameLetters.length, false);
  }

  void _tapPuzzleTile(int index) {
    if (_puzzleSolved) return;
    final emptyIndex = _puzzleTiles.indexOf(0);
    final row = index ~/ 3, col = index % 3;
    final emptyRow = emptyIndex ~/ 3, emptyCol = emptyIndex % 3;
    final isAdj = (row == emptyRow && (col - emptyCol).abs() == 1) ||
        (col == emptyCol && (row - emptyRow).abs() == 1);
    if (isAdj) {
      setState(() {
        _puzzleTiles[emptyIndex] = _puzzleTiles[index];
        _puzzleTiles[index] = 0;
        _puzzleSolved = _puzzleTiles.join() == _targetTiles.join();
        if (_puzzleSolved) AudioService().playSuccess();
      });
    }
  }

  void _popNameBalloon(int i) {
    if (_nameBalloonPopped[i]) return;
    AudioService().playPop();
    setState(() => _nameBalloonPopped[i] = true);
    if (_nameBalloonPopped.every((p) => p)) {
      AudioService().playCelebration();
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) { setState(() => _phase = 2); _finaleCtrl.forward(); }
      });
    }
  }

  @override
  void dispose() { _finaleCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1a1a2e),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Colors.amber, width: 2),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _phase == 0 ? '🎊 Special Balloon 10!' :
              _phase == 1 ? '🎈 ${widget.receiverName} Balloons!' : '🌟 Grand Finale!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amber[400]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            if (_phase == 0) _buildPuzzlePhase(),
            if (_phase == 1) _buildNameBalloonsPhase(),
            if (_phase == 2) _buildFinalePhase(),
          ],
        ),
      ),
    );
  }

  Widget _buildPuzzlePhase() {
    return Column(
      children: [
        Text(
          _puzzleSolved ? '🎉 Solved! u r very smart!' : '🧩 Put the numbers in order (1-8)!\nslide in empty place.',
          style: TextStyle(color: _puzzleSolved ? Colors.green[300] : Colors.white.withOpacity(0.8), fontSize: 13),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.amber.withOpacity(0.5), width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, mainAxisSpacing: 4, crossAxisSpacing: 4),
            itemCount: 9,
            itemBuilder: (context, index) {
              final val = _puzzleTiles[index];
              final isEmpty = val == 0;
              return GestureDetector(
                onTap: () => _tapPuzzleTile(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isEmpty ? Colors.transparent : _puzzleSolved ? Colors.green[700] : Colors.purple[700],
                    borderRadius: BorderRadius.circular(8),
                    border: isEmpty ? null : Border.all(color: Colors.white24),
                  ),
                  child: isEmpty ? null : Center(
                      child: Text('$val', style: const TextStyle(
                          color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            OutlinedButton.icon(
              onPressed: () => setState(() { _puzzleSolved = false; _initPuzzle(); }),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Shuffle', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.white54),
            ),
            if (_puzzleSolved)
              ElevatedButton.icon(
                onPressed: () => setState(() => _phase = 1),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Next! 🎈'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
          ],
        ),
        TextButton(
          onPressed: () => setState(() => _phase = 1),
          child: Text('Skip →', style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 11)),
        ),
      ],
    );
  }

  Widget _buildNameBalloonsPhase() {
    final colors = [Colors.red, Colors.pink, Colors.purple, Colors.blue, Colors.green,
      Colors.orange, Colors.teal, Colors.amber, Colors.cyan, Colors.indigo];
    return Column(
      children: [
        Text('${widget.receiverName} name balloons!\npop all! 🎈',
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
            textAlign: TextAlign.center),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10, runSpacing: 14, alignment: WrapAlignment.center,
          children: List.generate(_nameLetters.length, (i) {
            final color = colors[i % colors.length];
            if (_nameBalloonPopped[i]) {
              return SizedBox(width: 52, child: Column(children: [
                Container(width: 48, height: 56,
                  decoration: BoxDecoration(color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: color.withOpacity(0.4))),
                  child: Center(child: Text(_nameLetters[i],
                      style: TextStyle(fontSize: 18, color: color, fontWeight: FontWeight.bold))),
                ).animate().scale(duration: 300.ms, curve: Curves.elasticOut),
                Container(width: 2, height: 10, color: Colors.white24),
              ]));
            }
            return GestureDetector(
              onTap: () => _popNameBalloon(i),
              child: SizedBox(width: 52, child: Column(children: [
                Container(width: 48, height: 56,
                  decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [color.withOpacity(0.7), color],
                          begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8)]),
                  child: Center(child: Text(_nameLetters[i],
                      style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold))),
                ).animate(onPlay: (c) => c.repeat())
                    .moveY(begin: 0, end: -8, duration: Duration(milliseconds: 900 + i * 120))
                    .then().moveY(begin: -8, end: 0, duration: Duration(milliseconds: 900 + i * 120)),
                Container(width: 2, height: 10, color: Colors.white38),
              ])),
            );
          }),
        ),
        const SizedBox(height: 14),
        Text('${_nameBalloonPopped.where((p) => p).length} / ${_nameBalloonPopped.length} popped!',
            style: TextStyle(color: Colors.amber[300], fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildFinalePhase() {
    return Column(
      children: [
        const Text('🎉🌟✨', style: TextStyle(fontSize: 60))
            .animate(onPlay: (c) => c.repeat())
            .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 700.ms)
            .then().scale(begin: const Offset(1.2, 1.2), end: const Offset(0.8, 0.8), duration: 700.ms),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.purple[800]!, Colors.pink[800]!]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'Done all surprises! 🎊\n${widget.receiverName}, u r very special! 💝\nAlways be happy! 🌟',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: widget.onDone,
            icon: const Icon(Icons.celebration),
            label: const Text('🎊 Finish! See All Gifts!'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// NESTED GIFT WIDGET
// ─────────────────────────────────────────────────────────

class _NestedGiftWidget extends StatefulWidget {
  final int totalLevels;
  final String note;
  final VoidCallback onComplete;              // ⭐ ADD YEH LINE
  const _NestedGiftWidget({required this.totalLevels, required this.note, required this.onComplete});  // ⭐ ADD required this.onComplete
  @override
  State<_NestedGiftWidget> createState() => _NestedGiftWidgetState();
}

class _NestedGiftWidgetState extends State<_NestedGiftWidget>
    with TickerProviderStateMixin {
  int _level = 0;
  bool _letterOpen = false;
  bool _messageRevealed = false;
  late AnimationController _doveCtrl;

  final List<Color> _giftColors = [
    Colors.red, Colors.blue, Colors.green, Colors.purple,
    Colors.orange, Colors.pink, Colors.teal, Colors.indigo, Colors.amber, Colors.cyan,
  ];
  final List<String> _giftEmojis = ['🎁', '🎀', '🎊', '🎉', '🌟', '💝', '🎈', '✨', '🌸', '🕊️'];

  @override
  void initState() {
    super.initState();
    _doveCtrl = AnimationController(duration: const Duration(seconds: 2), vsync: this)..repeat();
  }

  @override
  void dispose() { _doveCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) =>
      _level < widget.totalLevels ? _buildGiftLevel() : _buildFinalReveal();

  Widget _buildGiftLevel() {
    final color = _giftColors[_level % _giftColors.length];
    return GestureDetector(
      onTap: () { AudioService().playMagicWand(); setState(() => _level++); },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color.withOpacity(0.3), color.withOpacity(0.1)]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.6), width: 2),
          boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 20)],
        ),
        child: Column(children: [
          Text('Gift #${_level + 1}',
              style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(_giftEmojis[_level % _giftEmojis.length], style: const TextStyle(fontSize: 70))
              .animate(onPlay: (c) => c.repeat())
              .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 800.ms)
              .then().scale(begin: const Offset(1.1, 1.1), end: const Offset(0.9, 0.9), duration: 800.ms),
          const SizedBox(height: 12),
          Text(
            _level < widget.totalLevels - 1 ? 'Tap to open! There are more gifts inside! 🎁' : 'Last gift! Tap to open! ✨',
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text('${_level + 1} / ${widget.totalLevels}',
              style: TextStyle(color: color.withOpacity(0.7), fontSize: 12)),
        ]),
      ),
    );
  }

  Widget _buildFinalReveal() {
    return Column(children: [
      AnimatedBuilder(
        animation: _doveCtrl,
        builder: (context, child) => Transform.translate(
          offset: Offset(sin(_doveCtrl.value * 2 * pi) * 20, -sin(_doveCtrl.value * pi) * 15),
          child: child,
        ),
        child: const Text('🕊️', style: TextStyle(fontSize: 70)),
      ),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
        Text('🎈', style: TextStyle(fontSize: 32)), SizedBox(width: 8),
        Text('🎈', style: TextStyle(fontSize: 40)), SizedBox(width: 8),
        Text('🎈', style: TextStyle(fontSize: 32)),
      ]).animate(onPlay: (c) => c.repeat())
          .moveY(begin: 0, end: -10, duration: 1200.ms)
          .then().moveY(begin: -10, end: 0, duration: 1200.ms),
      const SizedBox(height: 16),
      GestureDetector(
        onTap: () { if (!_letterOpen) setState(() => _letterOpen = true); },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          padding: EdgeInsets.all(_letterOpen ? 20 : 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _letterOpen
                  ? [const Color(0xFF2d1b69), const Color(0xFF4a1942)]
                  : [Colors.brown[700]!, Colors.brown[500]!],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _letterOpen ? Colors.amber : Colors.brown[300]!, width: 2),
            boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 20)],
          ),
          child: Column(children: [
            Text(
              _letterOpen ? '📜 Hidden Message' : '💌 Tap to Open Letter',
              style: TextStyle(
                  color: _letterOpen ? Colors.amber[300] : Colors.white,
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (_letterOpen) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  if (!_messageRevealed) {
                    setState(() => _messageRevealed = true);
                    AudioService().playMagic();
                  }
                },
                child: _messageRevealed
                    ? Container(
                  padding: const EdgeInsets.all(12),
                  constraints: const BoxConstraints(minHeight: 120),
                  decoration: BoxDecoration(
                      color: const Color(0xFFFFF8DC),
                      borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    widget.note.isNotEmpty
                        ? widget.note
                        : '💝 This is a special message just for you!\nYou are the most special happiness in my life! 🌟',
                    style: const TextStyle(color: Color(0xFF3d2b1f), fontSize: 14,
                        fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                ).animate().fadeIn(duration: 500.ms)
                    : Container(
                  constraints: const BoxConstraints(minHeight: 120),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Colors.brown[600]!, Colors.brown[400]!],
                        begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withOpacity(0.5), width: 1.5),
                  ),
                  child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('🔒', style: TextStyle(fontSize: 36)),
                    const SizedBox(height: 8),
                    Text('Tap to Reveal! ✨',
                        style: TextStyle(color: Colors.white.withOpacity(0.95),
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('special message is hide inside 💌',
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
                  ])),
                ).animate(onPlay: (c) => c.repeat())
                    .shimmer(duration: 1500.ms, color: Colors.amber.withOpacity(0.3)),
              ),
            ],
          ]),
        ),
      ),

      // ⭐⭐⭐ NEXT BALLOON BUTTON - Sirf message reveal hone ke BAAD dikhega
      // ⭐⭐⭐ NEXT BALLOON BUTTON - Sirf message reveal hone ke BAAD dikhega
      if (_messageRevealed) ...[
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // ⭐ Sirf parent ko inform karo - parent sab handle karega
              widget.onComplete();
            },
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Next Balloon 🎈'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal[600],  // ⭐ Teal color same rakho
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.3, end: 0),
      ],
    ]);
  }
}

// ─────────────────────────────────────────────────────────
// MAGICIAN HAT → CAKE
// ─────────────────────────────────────────────────────────

class _MagicianCakeWidget extends StatefulWidget {
  const _MagicianCakeWidget();

  @override
  State<_MagicianCakeWidget> createState() => _MagicianCakeWidgetState();
}

class _MagicianCakeWidgetState extends State<_MagicianCakeWidget>
    with TickerProviderStateMixin {
  bool _tapped = false;
  late AnimationController _riseCtrl;
  late AnimationController _hatShakeCtrl;

  @override
  void initState() {
    super.initState();
    _riseCtrl = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _hatShakeCtrl = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        _hatShakeCtrl.repeat();
        AudioService().playBoing(); // ✅ boing while hat is shaking
      }
    });
  }

  @override
  void dispose() { _riseCtrl.dispose(); _hatShakeCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.indigo[900]!, Colors.purple[900]!]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.cyan.withOpacity(0.5), width: 2),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('🎩 Magic Show!',
            style: TextStyle(color: Colors.cyan[300], fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () {
            if (!_tapped) {
              _hatShakeCtrl.stop();
              setState(() => _tapped = true);
              _riseCtrl.forward();
              AudioService().playMagicWand(); // ✅ magic sound on cake reveal
            }
          },
          child: Stack(alignment: Alignment.bottomCenter, children: [
            if (_tapped)
              AnimatedBuilder(
                animation: _riseCtrl,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, 80 * (1 - _riseCtrl.value)),
                  child: Opacity(opacity: _riseCtrl.value, child: child),
                ),
                child: Column(children: [
                  const Text('🎂', style: TextStyle(fontSize: 90))
                      .animate(onPlay: (c) => c.repeat())
                      .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.1, 1.1), duration: 700.ms)
                      .then().scale(begin: const Offset(1.1, 1.1), end: const Offset(0.8, 0.8), duration: 700.ms),
                  Text('🎊 SURPRISE! 🎊',
                      style: TextStyle(color: Colors.amber[300], fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('Happy Birthday! 🎂✨',
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                ]),
              ),
            AnimatedBuilder(
              animation: _hatShakeCtrl,
              builder: (context, child) => Transform.rotate(
                angle: _tapped ? 0 : sin(_hatShakeCtrl.value * pi * 4) * 0.08,
                child: child,
              ),
              child: Text('🎩', style: TextStyle(fontSize: _tapped ? 40 : 80)),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        if (!_tapped)
          Text('Tap the hat! ✨', style: TextStyle(color: Colors.white.withOpacity(0.7)))
              .animate(onPlay: (c) => c.repeat()).fadeIn(duration: 600.ms).then().fadeOut(duration: 600.ms),
        if (_tapped)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
              Text('✨', style: TextStyle(fontSize: 24)), SizedBox(width: 8),
              Text('⭐', style: TextStyle(fontSize: 20)), SizedBox(width: 8),
              Text('✨', style: TextStyle(fontSize: 24)),
            ]).animate(onPlay: (c) => c.repeat())
                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 600.ms)
                .then().scale(begin: const Offset(1.2, 1.2), end: const Offset(0.8, 0.8), duration: 600.ms),
          ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────
// MIND GAME QUIZ
// ─────────────────────────────────────────────────────────

class _MindGameQuiz extends StatefulWidget {
  final VoidCallback onComplete;
  const _MindGameQuiz({required this.onComplete});

  @override
  State<_MindGameQuiz> createState() => _MindGameQuizState();
}

class _MindGameQuizState extends State<_MindGameQuiz> with TickerProviderStateMixin {
  int _qIndex = 0;
  int _score = 0;
  int? _selected;
  bool _showFeedback = false;
  late ConfettiController _popper;

  final List<Map<String, dynamic>> _questions = [
    {'q': 'I get sliced on your special day Guess who i am?', 'options': ['🎂', '🎁', '🎈', '🍕'], 'correct': 0},
    {'q': 'I sit still, but something special sleeps inside me?', 'options': ['📦', '🎁', '👜', '📚'], 'correct': 1},
    {'q': 'I shine but I’m not the sun, I melt while your wish is done?', 'options': ['💡', '🔥', '🕯️', '⭐'], 'correct': 2},
    {'q': 'I rise up when happiness is near, light and colorful, I disappear in the air?', 'options': ['✈️', '🦅', '🎀', '🎈'], 'correct': 3},
    {'q': 'I have no body, yet I have a voice; I spread happiness and make hearts rejoice?', 'options': ['🎵', '📞', '📺', '🔔'], 'correct': 0},
  ];

  @override
  void initState() { super.initState(); _popper = ConfettiController(duration: const Duration(seconds: 2)); }

  @override
  void dispose() { _popper.dispose(); super.dispose(); }
  void _onSelect(int i) {
    if (_showFeedback) return;
    final correct = _questions[_qIndex]['correct'] as int;
    setState(() { _selected = i; _showFeedback = true; });
    if (i == correct) {
      _score++; _popper.play(); AudioService().playSuccess();
    } else {
      AudioService().playBoing();
    }
    // ✅ Auto next SIRF NAHI — user khud Next dabayega
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_qIndex];
    final correct = q['correct'] as int;
    final options = q['options'] as List<String>;
    final isLast = _qIndex == _questions.length - 1 && _showFeedback;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.deepPurple[900]!, Colors.indigo[900]!]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.deepPurple.withOpacity(0.5), width: 2),
      ),
      child: Stack(alignment: Alignment.topCenter, children: [
        Column(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('🧠 Mind Game',
                style: TextStyle(color: Colors.amber[300], fontSize: 18, fontWeight: FontWeight.bold)),
            Text('${_qIndex + 1} / ${_questions.length}',
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13,
                    fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
            child: Text(q['q'] as String,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.2),
            itemCount: 4,
            itemBuilder: (_, i) {
              Color bg = Colors.white.withOpacity(0.08);
              Color border = Colors.white.withOpacity(0.2);
              if (_showFeedback) {
                if (i == correct) { bg = Colors.green.withOpacity(0.3); border = Colors.green; }
                else if (i == _selected) { bg = Colors.red.withOpacity(0.3); border = Colors.red; }
              }
              return GestureDetector(
                onTap: () => _onSelect(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: border, width: 2)),
                  child: Center(child: Text(options[i], style: const TextStyle(fontSize: 44))),
                ),
              );
            },
          ),
          if (_showFeedback) ...[
            const SizedBox(height: 14),
            if (_selected == correct)
              Column(children: [
                const Text('🎉', style: TextStyle(fontSize: 60))
                    .animate(onPlay: (c) => c.repeat())
                    .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 400.ms)
                    .then().scale(begin: const Offset(1.2, 1.2), end: const Offset(0.8, 0.8), duration: 400.ms),
                Text('correct answer! 🎊',
                    style: TextStyle(color: Colors.green[300], fontSize: 18, fontWeight: FontWeight.bold)),
              ])
            else
              Column(children: [
                const Text('😠', style: TextStyle(fontSize: 60))
                    .animate(onPlay: (c) => c.repeat()).shake(duration: 400.ms),
                Text('wrong answer! 😤',
                    style: TextStyle(color: Colors.red[300], fontSize: 18, fontWeight: FontWeight.bold)),
              ]),
            if (isLast) ...[
              const SizedBox(height: 8),
              Text('Score: $_score / ${_questions.length}',
                  style: TextStyle(color: Colors.amber[300], fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => widget.onComplete(),
                  icon: const Icon(Icons.celebration),
                  label: const Text('🎊 Finish Quiz!'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
            if (_showFeedback && !isLast) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _qIndex++;
                      _selected = null;
                      _showFeedback = false;
                    });
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Next Question →'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        ]),
        ConfettiWidget(
          confettiController: _popper,
          blastDirectionality: BlastDirectionality.explosive,
          numberOfParticles: 30,
          gravity: 0.3,
          colors: const [Colors.green, Colors.amber, Colors.pink, Colors.cyan],
        ),
      ]),
    );
  }
}