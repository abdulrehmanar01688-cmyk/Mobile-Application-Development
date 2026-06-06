import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/box_model.dart';

class FirebaseService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─── FILE UPLOAD ────────────────────────────────────────

  Future<String?> uploadFile(File file, String path) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = await ref.putFile(file);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }

  Future<void> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      print('Delete error: $e');
    }
  }

  // ─── GIFT SAVE TO FIRESTORE ─────────────────────────────
  // ✅ Poora gift Firestore mein save karo taake web pe bhi kaam kare

  Future<bool> saveGiftToCloud(GiftBox box) async {
    try {
      // Surprises mein se media files ko Firebase Storage pe upload karo
      final List<Map<String, dynamic>> surprisesJson = [];

      for (final surprise in box.surprises) {
        String? cloudMediaUrl = surprise.mediaUrl;

        // Agar local file hai toh cloud pe upload karo
        if (surprise.mediaUrl != null &&
            !surprise.mediaUrl!.startsWith('http') &&
            !surprise.mediaUrl!.startsWith('https')) {

          if (surprise.mediaUrl!.contains('|||')) {
            // Multiple video files
            final paths = surprise.mediaUrl!.split('|||').where((p) => p.isNotEmpty).toList();
            final List<String> cloudUrls = [];

            for (final path in paths) {
              if (File(path).existsSync()) {
                final ext = path.split('.').last;
                final cloudPath = 'gifts/${box.id}/videos/${DateTime.now().millisecondsSinceEpoch}.$ext';
                final url = await uploadFile(File(path), cloudPath);
                if (url != null) cloudUrls.add(url);
              }
            }
            cloudMediaUrl = cloudUrls.join('|||');
          } else if (File(surprise.mediaUrl!).existsSync()) {
            // Single file (image, voice, etc)
            final ext = surprise.mediaUrl!.split('.').last;
            final cloudPath = 'gifts/${box.id}/${surprise.type.name}/${surprise.id}.$ext';
            cloudMediaUrl = await uploadFile(File(surprise.mediaUrl!), cloudPath);
          }
        }

        surprisesJson.add({
          'id': surprise.id,
          'type': surprise.type.name,
          'content': surprise.content,
          'mediaUrl': cloudMediaUrl,
        });
      }

      // Firestore mein save karo
      await _firestore.collection('gifts').doc(box.id).set({
        'id': box.id,
        'creatorId': box.creatorId,
        'giftName': box.giftName,
        'receiverName': box.receiverName,
        'note': box.note,
        'surprises': surprisesJson,
        'createdAt': Timestamp.fromDate(box.createdAt),
        'selectedBoxColor': box.selectedBoxColor,
        'isComplete': box.isComplete,
        'savedToCloud': true,
        'savedAt': Timestamp.now(),
      });

      print('✅ Gift saved to cloud: ${box.id}');
      return true;
    } catch (e) {
      print('❌ Cloud save error: $e');
      return false;
    }
  }

  // ─── GIFT FETCH FROM FIRESTORE ──────────────────────────

  Future<Map<String, dynamic>?> getGiftFromCloud(String giftId) async {
    try {
      final doc = await _firestore.collection('gifts').doc(giftId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('❌ Fetch error: $e');
      return null;
    }
  }

  // ─── CHECK IF GIFT EXISTS ───────────────────────────────

  Future<bool> giftExistsInCloud(String giftId) async {
    try {
      final doc = await _firestore.collection('gifts').doc(giftId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }
}