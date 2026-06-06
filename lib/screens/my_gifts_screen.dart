import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/box_provider.dart';
import '../models/box_model.dart';
import '../services/link_service.dart';
import 'create_box_screen.dart';
import 'open_box_screen.dart';

class MyGiftsScreen extends StatefulWidget {
  const MyGiftsScreen({super.key});

  @override
  State<MyGiftsScreen> createState() => _MyGiftsScreenState();
}

class _MyGiftsScreenState extends State<MyGiftsScreen> {
  final LinkService _linkService = LinkService();

  @override
  void initState() {
    super.initState();
    _loadGifts();
  }

  Future<void> _loadGifts() async {
    final authProvider = context.read<AuthProvider>();
    final boxProvider = context.read<BoxProvider>();
    if (authProvider.user != null) {
      await boxProvider.loadUserBoxes(authProvider.user!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final boxProvider = context.watch<BoxProvider>();
    final boxes = boxProvider.userBoxes;

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('My Gifts 🎁', style: TextStyle(color: Colors.amber[400])),
        iconTheme: IconThemeData(color: Colors.purple[200]),
      ),
      body: boxes.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: boxes.length,
        itemBuilder: (context, index) {
          final box = boxes[index];
          return _buildGiftCard(box, index);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CreateBoxScreen()));
        },
        backgroundColor: Colors.purple[600],
        icon: const Icon(Icons.add),
        label: const Text('New Gift'),
      ),
    );
  }

  Widget _buildGiftCard(GiftBox box, int index) {
    return Card(
      color: Colors.white.withOpacity(0.05),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: box.isComplete
              ? Colors.green.withOpacity(0.3)
              : Colors.purple.withOpacity(0.3),
        ),
      ),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: box.isComplete
                ? Colors.green.withOpacity(0.2)
                : Colors.purple.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            box.isComplete ? Icons.check_circle : Icons.card_giftcard,
            color: box.isComplete ? Colors.green : Colors.purple[400],
            size: 28,
          ),
        ),
        title: Text(
          box.giftName,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'To: ${box.receiverName}',
              style: TextStyle(color: Colors.white.withOpacity(0.6)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${box.surprises.length} surprises • ${box.isComplete ? 'Completed ✅' : 'Pending ⏳'}',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.5), fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        onTap: () {
          context.read<BoxProvider>().setCurrentBox(box);
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const OpenBoxScreen()));
        },
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Colors.white.withOpacity(0.6)),
          color: const Color(0xFF2a2a4e),
          padding: EdgeInsets.zero,
          onSelected: (value) async {
            switch (value) {
              case 'open':
                context.read<BoxProvider>().setCurrentBox(box);
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const OpenBoxScreen()));
                break;
              case 'share':
                await _shareGift(box);
                break;
              case 'delete':
                _deleteGift(box.id);
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'open',
              child: Row(children: [
                Icon(Icons.open_in_new, color: Colors.purple[300], size: 20),
                const SizedBox(width: 8),
                const Text('Open', style: TextStyle(color: Colors.white)),
              ]),
            ),
            PopupMenuItem(
              value: 'share',
              child: Row(children: [
                Icon(Icons.share, color: Colors.green[300], size: 20),
                const SizedBox(width: 8),
                const Text('Share Gift 🎁',
                    style: TextStyle(color: Colors.white)),
              ]),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(children: [
                Icon(Icons.delete, color: Colors.red[300], size: 20),
                const SizedBox(width: 8),
                const Text('Delete', style: TextStyle(color: Colors.redAccent)),
              ]),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms, delay: (index * 100).ms)
        .slideX(begin: 0.3, end: 0);
  }

  // ─── SHARE GIFT ──────────────────────────────────────────

  Future<void> _shareGift(GiftBox box) async {
    // Loading dialog dikhao
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.purple),
            const SizedBox(height: 16),
            const Text('Gift is saving on the cloud...',
                style: TextStyle(color: Colors.white), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('wait a second 🎁',
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );

    try {
      // Gift cloud pe save karo aur link generate karo
      final link = await _linkService.generateShareableLink(box);

      // Loading band karo
      if (mounted) Navigator.pop(context);

      // Share options dikhao
      if (mounted) {
        _showShareOptions(box, link);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Share mein error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showShareOptions(GiftBox box, String link) {
    final authProvider = context.read<AuthProvider>();
    final senderName =
        authProvider.user?.displayName ?? authProvider.user?.email ?? 'Someone';

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1a1a2e),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text('Share gift! 🎁',
                style: TextStyle(
                    color: Colors.amber[400],
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              '${box.receiverName} ko yeh link bhejo',
              style: TextStyle(color: Colors.white.withOpacity(0.6)),
            ),
            const SizedBox(height: 20),

            // Link box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      link,
                      style: TextStyle(
                          color: Colors.purple[200], fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: link));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Link copy ho gaya! 📋'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy, color: Colors.white54, size: 20),
                    tooltip: 'Copy link',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // WhatsApp share button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _linkService.shareOnWhatsApp(
                    link: link,
                    giftName: box.giftName,
                    receiverName: box.receiverName,
                    senderName: senderName,
                  );
                },
                icon: const Icon(Icons.share),
                label: const Text('WhatsApp / Kisi bhi app pe share karo',
                    style: TextStyle(fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Info text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Receiver browser mein gift khol sakta hai — koi app ki zaroorat nahi!',
                      style: TextStyle(
                          color: Colors.blue[200], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.card_giftcard, size: 80, color: Colors.purple[800]),
          const SizedBox(height: 20),
          Text('No Gifts Yet 🎁',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[200])),
          const SizedBox(height: 8),
          Text('Create your first mystery gift!',
              style:
              TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.5))),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreateBoxScreen()));
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Gift'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple[600],
              padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteGift(String boxId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Gift? 🗑️',
            style: TextStyle(color: Colors.white)),
        content: const Text('Yeh gift delete ho jayega.\nYeh undo nahi ho sakta!',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.purple[200])),
          ),
          ElevatedButton(
            onPressed: () async {
              await context.read<BoxProvider>().deleteBox(boxId);
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}