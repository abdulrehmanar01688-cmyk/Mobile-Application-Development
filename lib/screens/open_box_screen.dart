import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:provider/provider.dart';
import '../providers/box_provider.dart';
import '../services/audio_service.dart';
import 'balloon_reveal_screen.dart';

class OpenBoxScreen extends StatefulWidget {
  const OpenBoxScreen({super.key});

  @override
  State<OpenBoxScreen> createState() => _OpenBoxScreenState();
}

class _OpenBoxScreenState extends State<OpenBoxScreen>
    with TickerProviderStateMixin {
  late AnimationController _boxController;
  late AnimationController _shakeController;
  late AnimationController _floatController;
  late Animation<double> _boxScale;
  late Animation<double> _lidRotation;
  late ConfettiController _confettiController;
  late ConfettiController _leftConfetti;
  late ConfettiController _rightConfetti;

  bool _isOpened = false;
  bool _showEffects = false;
  bool _showFloatingElements = false;

  final List<_FloatingItem> _floatingItems = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    _boxController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _boxScale = Tween<double>(begin: 1, end: 1.2).animate(
      CurvedAnimation(parent: _boxController, curve: Curves.easeOut),
    );

    _lidRotation = Tween<double>(begin: 0, end: -pi / 3).animate(
      CurvedAnimation(
        parent: _boxController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeInOut),
      ),
    );

    _confettiController = ConfettiController(duration: const Duration(seconds: 6));
    _leftConfetti = ConfettiController(duration: const Duration(seconds: 5));
    _rightConfetti = ConfettiController(duration: const Duration(seconds: 5));

    _generateFloatingItems();
    AudioService().playBackgroundMusic('bg_music');
  }

  void _generateFloatingItems() {
    final emojis = ['🎈', '🌸', '🌺', '🌻', '💐', '🎊', '✨', '🌷', '🎀', '💫'];
    for (int i = 0; i < 20; i++) {
      _floatingItems.add(_FloatingItem(
        emoji: emojis[_random.nextInt(emojis.length)],
        x: _random.nextDouble(),
        startY: 1.0 + _random.nextDouble() * 0.5,
        speed: 0.3 + _random.nextDouble() * 0.7,
        size: 16 + _random.nextDouble() * 24,
        phase: _random.nextDouble(),
      ));
    }
  }

  @override
  void dispose() {
    _boxController.dispose();
    _shakeController.dispose();
    _floatController.dispose();
    _confettiController.dispose();
    _leftConfetti.dispose();
    _rightConfetti.dispose();
    AudioService().stopBackgroundMusic();
    super.dispose();
  }

  void _openBox() async {
    if (_isOpened) return;
    setState(() => _isOpened = true);

    await AudioService().playBoxOpen();

    await Future.delayed(const Duration(milliseconds: 400));
    AudioService().playBackgroundMusic('party');

    _shakeController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    await _boxController.forward();

    await Future.delayed(const Duration(milliseconds: 200));
    AudioService().playCelebration();

    _confettiController.play();
    _leftConfetti.play();
    _rightConfetti.play();

    if (mounted) {
      setState(() {
        _showEffects = true;
        _showFloatingElements = true;
      });
    }

    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const BalloonRevealScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final box = context.watch<BoxProvider>().currentBox;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0d0d1a),
      body: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _floatController,
            builder: (context, _) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(
                      sin(_floatController.value * 2 * pi) * 0.3,
                      cos(_floatController.value * 2 * pi) * 0.3,
                    ),
                    radius: 1.5,
                    colors: const [
                      Color(0xFF2d1b69),
                      Color(0xFF0d0d1a),
                      Color(0xFF1a0a3d),
                    ],
                  ),
                ),
              );
            },
          ),

          if (_showFloatingElements)
            AnimatedBuilder(
              animation: _floatController,
              builder: (context, _) {
                return Stack(
                  children: _floatingItems.map((item) {
                    final t = (_floatController.value + item.phase) % 1.0;
                    final y = size.height * (1.0 - t * 1.5);
                    final x = size.width * item.x +
                        sin(t * pi * 4 + item.phase * 10) * 30;
                    return Positioned(
                      left: x,
                      top: y,
                      child: Opacity(
                        opacity: t < 0.8 ? 1.0 : (1.0 - t) / 0.2,
                        child: Text(item.emoji, style: TextStyle(fontSize: item.size)),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

          Align(
            alignment: Alignment.centerLeft,
            child: ConfettiWidget(
              confettiController: _leftConfetti,
              blastDirection: -pi / 6,
              numberOfParticles: 30,
              gravity: 0.3,
              colors: const [Colors.red, Colors.pink, Colors.orange, Colors.yellow],
            ),
          ),

          Align(
            alignment: Alignment.centerRight,
            child: ConfettiWidget(
              confettiController: _rightConfetti,
              blastDirection: pi + pi / 6,
              numberOfParticles: 30,
              gravity: 0.3,
              colors: const [Colors.blue, Colors.green, Colors.purple, Colors.cyan],
            ),
          ),

          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 60,
              gravity: 0.2,
              colors: const [
                Colors.red, Colors.blue, Colors.green,
                Colors.purple, Colors.orange, Colors.pink, Colors.yellow,
                Colors.cyan, Colors.lime,
              ],
            ),
          ),

          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (box != null && !_isOpened) ...[
                  Text(
                    '🎁 For: ${box.receiverName}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[400],
                      shadows: [Shadow(color: Colors.amber.withOpacity(0.5), blurRadius: 20)],
                    ),
                  ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.3),
                  const SizedBox(height: 8),
                  if (box.note != null && box.note!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        box.note!,
                        style: TextStyle(fontSize: 16, color: Colors.purple[200]),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
                    ),
                  const SizedBox(height: 60),
                ],

                GestureDetector(
                  onTap: _openBox,
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_boxController, _shakeController]),
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _boxScale.value,
                        child: Transform.rotate(
                          angle: _isOpened
                              ? 0
                              : sin(_shakeController.value * pi * 8) * 0.05,
                          child: _buildGiftBox(box?.selectedBoxColor),
                        ),
                      );
                    },
                  ),
                ).animate().fadeIn(duration: 600.ms).scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1, 1),
                  curve: Curves.elasticOut,
                ),

                const SizedBox(height: 40),

                if (!_isOpened)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Text(
                      '🎊 Tap to Open! 🎊',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ).animate(onPlay: (c) => c.repeat())
                      .fadeIn(duration: 600.ms)
                      .then()
                      .fadeOut(duration: 600.ms),

                if (_showEffects) ...[
                  const SizedBox(height: 20),
                  Text(
                    '✨🎈 Magic Unfolding... 🌸✨',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.amber[400]),
                  ).animate().fadeIn(duration: 500.ms).scale(
                    begin: const Offset(0.5, 0.5),
                    end: const Offset(1.0, 1.0),
                    curve: Curves.elasticOut,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGiftBox(String? colorName) {
    Color boxColor = Colors.purple;
    if (colorName == 'Ruby Box') boxColor = Colors.red;
    else if (colorName == 'Sapphire Box') boxColor = Colors.blue;
    else if (colorName == 'Emerald Box') boxColor = Colors.green;
    else if (colorName == 'Golden Box') boxColor = Colors.orange;

    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: boxColor.withOpacity(0.6),
                  blurRadius: 60,
                  spreadRadius: 20,
                ),
              ],
            ),
          ),

          Positioned(
            bottom: 0,
            child: Container(
              width: 180,
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [boxColor.withOpacity(0.8), boxColor],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: boxColor.withOpacity(0.5),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Center(
                child: Icon(Icons.star, size: 50, color: Colors.amber[400]),
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            child: Container(
              width: 20,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.8),
              ),
            ),
          ),

          // ✅ CAP PE TAP KARO TO AWAZ AYE
          Positioned(
            top: 0,
            child: GestureDetector(
              onTap: () => AudioService().playBoxOpen(),
              child: AnimatedBuilder(
                animation: _lidRotation,
                builder: (context, child) {
                  return Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.003)
                      ..rotateX(_lidRotation.value),
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: 190,
                      height: 65,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [boxColor.withOpacity(0.9), boxColor],
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.amber[400],
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.7),
                                blurRadius: 15,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.card_giftcard, color: Colors.white),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          Positioned(
            top: 10,
            child: _isOpened
                ? const SizedBox()
                : const Text('🎀', style: TextStyle(fontSize: 36))
                .animate(onPlay: (c) => c.repeat())
                .scale(
              begin: const Offset(0.9, 0.9),
              end: const Offset(1.1, 1.1),
              duration: 1000.ms,
            )
                .then()
                .scale(
              begin: const Offset(1.1, 1.1),
              end: const Offset(0.9, 0.9),
              duration: 1000.ms,
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingItem {
  final String emoji;
  final double x;
  final double startY;
  final double speed;
  final double size;
  final double phase;

  _FloatingItem({
    required this.emoji,
    required this.x,
    required this.startY,
    required this.speed,
    required this.size,
    required this.phase,
  });
}