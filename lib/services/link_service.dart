import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/box_model.dart';
import 'firebase_service.dart';

class LinkService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseService _firebaseService = FirebaseService();

  // ✅ Apna Firebase project ID yahan daalo
  // Firebase Console > Project Settings > Project ID
  static const String _firebaseProjectId = 'mysterybox-abc12';

  // ✅ Yeh real link hoga jab Firebase Hosting deploy ho
  static String get _baseUrl => 'https://$_firebaseProjectId.web.app';

  // ─── GIFT CLOUD PE SAVE KARO AUR LINK BANAO ────────────

  Future<String> generateShareableLink(GiftBox box) async {
    // 1. Gift data Firebase pe save karo
    final saved = await _firebaseService.saveGiftToCloud(box);

    if (!saved) {
      // Cloud save fail — fallback link
      return '$_baseUrl/gift/${box.id}';
    }

    // 2. Real shareable link
    final link = '$_baseUrl/gift/${box.id}';

    // 3. Link record karo
    await _firestore.collection('gift_links').doc(box.id).set({
      'boxId': box.id,
      'giftName': box.giftName,
      'receiverName': box.receiverName,
      'link': link,
      'createdAt': DateTime.now().toIso8601String(),
      'isOpened': false,
      'openCount': 0,
    });

    return link;
  }

  // ─── WHATSAPP PE SHARE ──────────────────────────────────

  Future<void> shareOnWhatsApp({
    required String link,
    required String giftName,
    required String receiverName,
    required String senderName,
  }) async {
    final message = '''🎁 *${receiverName} ke liye ek khaas gift!* 🎁

*${senderName}* ne tumhare liye ek magical mystery box banaya hai! ✨

🎈 Balloons hain andar
🎊 Surprises chhupe hain
💝 Sirf tumhare liye!

*Yahan tap karo aur apna gift kholo:*
$link

_Browser mein khulega — koi app ki zaroorat nahi!_ 🌟''';

    await Share.share(
      message,
      subject: '🎁 Tumhare liye ek khaas gift!',
    );
  }

  // ─── GIFT OPENED TRACK KARO ─────────────────────────────

  Future<void> markGiftOpened(String giftId) async {
    try {
      await _firestore.collection('gift_links').doc(giftId).update({
        'isOpened': true,
        'openedAt': DateTime.now().toIso8601String(),
        'openCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('Track error: $e');
    }
  }
}