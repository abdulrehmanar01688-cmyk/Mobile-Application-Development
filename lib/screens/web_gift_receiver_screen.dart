import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/box_model.dart';
import '../services/link_service.dart';
import 'open_box_screen.dart';
import '../providers/box_provider.dart';
import 'package:provider/provider.dart';

/// ✅ Yeh screen browser mein khulti hai jab receiver link click kare
/// Route: /gift/:giftId
class WebGiftReceiverScreen extends StatefulWidget {
  final String giftId;
  const WebGiftReceiverScreen({super.key, required this.giftId});

  @override
  State<WebGiftReceiverScreen> createState() => _WebGiftReceiverScreenState();
}

class _WebGiftReceiverScreenState extends State<WebGiftReceiverScreen> {
  bool _loading = true;
  String? _error;
  GiftBox? _giftBox;

  @override
  void initState() {
    super.initState();
    _loadGift();
  }

  Future<void> _loadGift() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('gifts')
          .doc(widget.giftId)
          .get(const GetOptions(source: Source.server));  // ✅ SERVER se fresh data!

      if (!doc.exists) {
        setState(() { _error = 'Gift not found 😢\nmaybe link is old.'; _loading = false; });
        return;
      }

      final data = doc.data()!;

      // Surprises parse karo
      final surprisesList = (data['surprises'] as List<dynamic>? ?? [])
          .map((s) => Surprise.fromJson(s as Map<String, dynamic>))
          .toList();

      final box = GiftBox(
        id: data['id'] as String,
        creatorId: data['creatorId'] as String,
        giftName: data['giftName'] as String,
        receiverName: data['receiverName'] as String,
        note: data['note'] as String?,
        surprises: surprisesList,
        createdAt: data['createdAt'] is String
            ? DateTime.parse(data['createdAt'] as String)
            : (data['createdAt'] as dynamic).toDate(),
        shareableLink: '',
        selectedBoxColor: data['selectedBoxColor'] as String?,
        isComplete: data['isComplete'] as bool? ?? false,
      );

      // Opened track karo
      LinkService().markGiftOpened(widget.giftId);

      setState(() { _giftBox = box; _loading = false; });
    } catch (e) {
      setState(() { _error = 'something occur wrong: $e'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0d0d1a),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎁', style: TextStyle(fontSize: 80)),
              const SizedBox(height: 24),
              const CircularProgressIndicator(color: Colors.purple),
              const SizedBox(height: 16),
              Text('your gift is loading...',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16)),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0d0d1a),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('😢', style: TextStyle(fontSize: 60)),
              const SizedBox(height: 16),
              Text(_error!,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    // Gift mila — open box screen pe bhejo
    if (_giftBox != null) {
      // BoxProvider mein set karo
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<BoxProvider>().setCurrentBox(_giftBox!);
      });

      return ChangeNotifierProvider.value(
        value: context.read<BoxProvider>(),
        child: _GiftWelcomeScreen(
          box: _giftBox!,
          onOpen: () {
            context.read<BoxProvider>().setCurrentBox(_giftBox!);
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const OpenBoxScreen()),
            );
          },
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

// ─── WELCOME SCREEN BEFORE OPENING ──────────────────────

class _GiftWelcomeScreen extends StatelessWidget {
  final GiftBox box;
  final VoidCallback onOpen;
  const _GiftWelcomeScreen({required this.box, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0d0d1a),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0d0d1a), Color(0xFF1a0d3a), Color(0xFF0d0d1a)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Floating gift emoji
                  const Text('🎁', style: TextStyle(fontSize: 100)),
                  const SizedBox(height: 24),
                  Text(
                    '${box.receiverName} ke liye',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'a special Gift! 🌟',
                    style: TextStyle(
                        color: Colors.amber[400],
                        fontSize: 28,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  if (box.note != null && box.note!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.purple.withOpacity(0.3)),
                      ),
                      child: Text(
                        box.note!,
                        style: TextStyle(
                            color: Colors.purple[200], fontSize: 16,
                            fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  Text(
                    '${box.surprises.length} surprise is waiting for u! 🎈',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.6), fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onOpen,
                      icon: const Icon(Icons.card_giftcard, size: 24),
                      label: const Text(
                        'open your gift! 🎊',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 8,
                        shadowColor: Colors.purple.withOpacity(0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}