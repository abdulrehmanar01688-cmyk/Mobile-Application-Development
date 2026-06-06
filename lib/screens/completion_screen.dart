import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart'; // ✅ kIsWeb ke liye
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../models/box_model.dart';
import '../providers/box_provider.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';

class CompletionScreen extends StatefulWidget {
  const CompletionScreen({super.key});

  @override
  State<CompletionScreen> createState() => _CompletionScreenState();
}

class _CompletionScreenState extends State<CompletionScreen>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _floatCtrl;
  final Map<String, VideoPlayerController> _videoControllers = {};
  final Random _random = Random();

  int _mediaIndex = 0;
  List<Surprise> _mediaSurprises = [];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 8));
    _floatCtrl = AnimationController(duration: const Duration(seconds: 4), vsync: this)..repeat();
    _confettiController.play();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initMedia());
  }

  void _initMedia() {
    final box = context.read<BoxProvider>().currentBox;
    if (box == null) return;

    _mediaSurprises = box.surprises.where((s) {
      if ((s.type == SurpriseType.image || s.type == SurpriseType.video) &&
          s.mediaUrl != null) {
        if (kIsWeb) return true;
        return File(s.mediaUrl!).existsSync();
      }
      return false;
    }).toList();

    for (var s in _mediaSurprises) {
      if (s.type == SurpriseType.video && s.mediaUrl != null) {
        final ctrl = kIsWeb
            ? VideoPlayerController.networkUrl(Uri.parse(s.mediaUrl!))
            : VideoPlayerController.file(File(s.mediaUrl!));
        _videoControllers[s.mediaUrl!] = ctrl;
        ctrl.initialize().then((_) {
          if (mounted) setState(() {});
        });
      }
    }
  }

  void _goToMedia(int index) {
    if (index < 0 || index >= _mediaSurprises.length) return;
    final curr = _mediaSurprises[_mediaIndex];
    if (curr.type == SurpriseType.video && curr.mediaUrl != null) {
      _videoControllers[curr.mediaUrl!]?.pause();
      _videoControllers[curr.mediaUrl!]?.seekTo(Duration.zero);
    }
    setState(() => _mediaIndex = index);
    final next = _mediaSurprises[index];
    if (next.type == SurpriseType.video && next.mediaUrl != null) {
      _videoControllers[next.mediaUrl!]?.play();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _floatCtrl.dispose();
    for (var c in _videoControllers.values) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final box = context.watch<BoxProvider>().currentBox;

    return Scaffold(
      backgroundColor: const Color(0xFF0d0d1a),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0d0d1a), Color(0xFF1a0d3a), Color(0xFF0a1a0d)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Floating emojis
          AnimatedBuilder(
            animation: _floatCtrl,
            builder: (context, _) {
              final size = MediaQuery.of(context).size;
              return Stack(
                children: List.generate(15, (i) {
                  final emojis = ['🎉', '🎊', '✨', '💫', '🌟', '🎈', '🎀', '💝'];
                  final t = (_floatCtrl.value + i * 0.07) % 1.0;
                  return Positioned(
                    left: (i * 37.0 % size.width) + sin(t * pi * 2) * 20,
                    top: size.height * (1.0 - t),
                    child: Opacity(
                      opacity: t < 0.8 ? 1.0 : (1.0 - t) / 0.2,
                      child: Text(emojis[i % emojis.length],
                          style: const TextStyle(fontSize: 24)),
                    ),
                  );
                }),
              );
            },
          ),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 80,
              gravity: 0.15,
              colors: const [
                Colors.red, Colors.blue, Colors.green, Colors.purple,
                Colors.orange, Colors.pink, Colors.yellow, Colors.cyan,
              ],
            ),
          ),

          // Main scrollable content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Header emoji
                  const Text('🎊', style: TextStyle(fontSize: 70))
                      .animate(onPlay: (c) => c.repeat())
                      .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 800.ms)
                      .then()
                      .scale(begin: const Offset(1.2, 1.2), end: const Offset(0.8, 0.8), duration: 800.ms),
                  const SizedBox(height: 12),

                  if (box != null)
                    Text(
                      'Happy Birthday\n${box.receiverName}! 🎂',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[400],
                        shadows: [Shadow(color: Colors.amber.withOpacity(0.5), blurRadius: 20)],
                      ),
                      textAlign: TextAlign.center,
                    )
                        .animate()
                        .fadeIn(duration: 800.ms)
                        .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1), curve: Curves.elasticOut),

                  const SizedBox(height: 8),
                  Text(
                    'See all surprises! 🎁✨',
                    style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.8)),
                  ).animate().fadeIn(duration: 600.ms, delay: 300.ms),

                  const SizedBox(height: 24),

                  // ─── Media Slideshow ────────────────────────────
                  if (_mediaSurprises.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.amber.withOpacity(0.5), width: 2),
                        boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.2), blurRadius: 20)],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _buildCurrentMedia(),
                      ),
                    ).animate().fadeIn(duration: 500.ms, delay: 400.ms),
                    const SizedBox(height: 12),

                    // Dot indicators
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 6,
                      children: List.generate(_mediaSurprises.length, (i) {
                        return GestureDetector(
                          onTap: () => _goToMedia(i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: i == _mediaIndex ? 24 : 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: i == _mediaIndex
                                  ? Colors.amber[400]
                                  : Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 12),

                    // Navigation arrows
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () => _goToMedia(
                              (_mediaIndex - 1 + _mediaSurprises.length) % _mediaSurprises.length),
                          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 28),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.1),
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Text(
                          '${_mediaIndex + 1} / ${_mediaSurprises.length}',
                          style: TextStyle(
                              color: Colors.amber[400],
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 20),
                        IconButton(
                          onPressed: () => _goToMedia(
                              (_mediaIndex + 1) % _mediaSurprises.length),
                          icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 28),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.1),
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ─── All Surprises List ────────────────────────
                  if (box != null) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('All Surprises 🎊',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber[400])),
                    ),
                    const SizedBox(height: 12),
                    ...box.surprises.asMap().entries.map((entry) {
                      return _buildSurpriseCard(entry.value, entry.key)
                          .animate()
                          .fadeIn(duration: 300.ms, delay: (entry.key * 100).ms)
                          .slideX(begin: 0.3, end: 0);
                    }),
                  ],

                  const SizedBox(height: 24),

                  // ─── Action Buttons ────────────────────────────
                  // ✅ WEB PE BILKUL NAHI DIKHENGE — sirf mobile app pe
                  if (!kIsWeb)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _shareGift,
                            icon: const Icon(Icons.share),
                            label: const Text('Share Gift'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (_) => const HomeScreen()),
                                    (route) => false,
                              );
                            },
                            icon: const Icon(Icons.home),
                            label: const Text('Home'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple[700],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: 500.ms, delay: 600.ms),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentMedia() {
    if (_mediaSurprises.isEmpty) return const SizedBox();
    final curr = _mediaSurprises[_mediaIndex];

    if (curr.type == SurpriseType.image && curr.mediaUrl != null) {
      // Web pe network image, mobile pe local file
      return kIsWeb
          ? Image.network(
        curr.mediaUrl!,
        width: double.infinity,
        height: 280,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => Container(
          height: 280,
          color: Colors.black,
          child: const Center(
              child: Icon(Icons.broken_image, color: Colors.white54, size: 60)),
        ),
      )
          : Image.file(
        File(curr.mediaUrl!),
        width: double.infinity,
        height: 280,
        fit: BoxFit.cover,
      );
    } else if (curr.type == SurpriseType.video && curr.mediaUrl != null) {
      final ctrl = _videoControllers[curr.mediaUrl!];
      if (ctrl != null && ctrl.value.isInitialized) {
        return Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(aspectRatio: ctrl.value.aspectRatio, child: VideoPlayer(ctrl)),
            StatefulBuilder(
              builder: (context, setLocal) => GestureDetector(
                onTap: () {
                  setLocal(() {
                    ctrl.value.isPlaying ? ctrl.pause() : ctrl.play();
                  });
                },
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                      color: Colors.black54, shape: BoxShape.circle),
                  child: Icon(
                    ctrl.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
          ],
        );
      }
      return Container(
        width: double.infinity,
        height: 200,
        color: Colors.black,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    return const SizedBox();
  }

  Widget _buildSurpriseCard(Surprise surprise, int index) {
    final typeInfo = _getTypeInfo(surprise.type);
    return Card(
      color: Colors.white.withOpacity(0.06),
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: typeInfo.$1.withOpacity(0.3)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration:
          BoxDecoration(color: typeInfo.$1.withOpacity(0.2), shape: BoxShape.circle),
          child: Text(typeInfo.$3, style: const TextStyle(fontSize: 20)),
        ),
        title: Text(
          'Surprise ${index + 1}: ${typeInfo.$2}',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: surprise.content != null
            ? Text(
          surprise.content!,
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        )
            : null,
        trailing: Icon(Icons.check_circle, color: Colors.green[400], size: 20),
      ),
    );
  }

  (Color, String, String) _getTypeInfo(SurpriseType type) {
    switch (type) {
      case SurpriseType.image:       return (Colors.blue,   'Photo',          '📸');
      case SurpriseType.video:       return (Colors.red,    'Video',          '🎬');
      case SurpriseType.message:     return (Colors.green,  'Message',        '💬');
      case SurpriseType.voiceNote:   return (Colors.orange, 'Voice Note',     '🎙️');
      case SurpriseType.funnyPopup:  return (Colors.pink,   'Funny Popup',    '😂');
      case SurpriseType.jokerAnimation: return (Colors.yellow, 'Joker Bottle', '🃏');
      case SurpriseType.soundEffect: return (Colors.cyan,   'Magic Effect',   '💫');
      case SurpriseType.miniGift:    return (Colors.purple, 'Mini Gift Chain','🎁');
      case SurpriseType.mindGame:    return (Colors.teal,   'Mind Game',      '🧠');
    }
  }

  Future<void> _shareGift() async {
    // Ye sirf mobile pe call hoga — web pe button hi nahi dikhta
    final box = context.read<BoxProvider>().currentBox;
    if (box == null) return;

    // Background mein save karo
    context.read<BoxProvider>().saveBoxToFirestore(box);

    Share.share(
      '🎁 A special gift box is waiting just for you!\n\nFrom: ${box.creatorId}\nTo: ${box.receiverName}\n\n${box.giftName}\n\n💌 ${box.note ?? "Open karo aur surprises dekho!"}\n\nhttps://mysterybox-9de5c.web.app/gift/${box.id}',
      subject: '🎊 ${box.giftName} - A Special Gift for You!',
    );
  }
}