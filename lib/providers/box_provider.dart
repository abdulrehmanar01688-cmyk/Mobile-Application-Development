import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../models/box_model.dart';

class BoxProvider extends ChangeNotifier {
  GiftBox? _currentBox;
  List<GiftBox> _userBoxes = [];

  GiftBox? get currentBox => _currentBox;
  List<GiftBox> get userBoxes => List.unmodifiable(_userBoxes);

  void setCurrentBox(GiftBox box) {
    _currentBox = box;
    notifyListeners();
    _saveBoxToLocal(box);
  }

  void updateCurrentBox(GiftBox box) {
    _currentBox = box;
    final idx = _userBoxes.indexWhere((b) => b.id == box.id);
    if (idx != -1) {
      _userBoxes[idx] = box;
    } else {
      _userBoxes.add(box);
    }
    notifyListeners();
    _persistBoxes();
  }

  // ─── LOAD ──────────────────────────────────────────────

  Future<void> loadUserBoxes(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'boxes_$userId';
      final raw = prefs.getString(key);
      if (raw != null) {
        final List decoded = jsonDecode(raw);
        _userBoxes = decoded
            .map((e) => GiftBox.fromJson(e as Map<String, dynamic>))
            .toList();
        _userBoxes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('BoxProvider loadUserBoxes error: $e');
    }
  }

  // ─── SAVE (Local + Cloudinary + Firestore) ─────────────

  Future<void> _saveBoxToLocal(GiftBox box) async {
    final idx = _userBoxes.indexWhere((b) => b.id == box.id);
    if (idx != -1) {
      _userBoxes[idx] = box;
    } else {
      _userBoxes.insert(0, box);
    }
    notifyListeners();
    await _persistBoxes();
  }

  Future<String?> _uploadToCloudinary(String localPath) async {
    try {
      final file = File(localPath);
      if (!file.existsSync()) return null;

      final uri = Uri.parse(
          'https://api.cloudinary.com/v1_1/dhhkze4yj/auto/upload'
      );
      final request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = 'mysterybox_preset';
      request.files.add(await http.MultipartFile.fromPath('file', localPath));

      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final jsonResponse = jsonDecode(String.fromCharCodes(responseData));

      if (jsonResponse['secure_url'] != null) {
        debugPrint('✅ Cloudinary upload: ${jsonResponse['secure_url']}');
        return jsonResponse['secure_url'];
      }
      return null;
    } catch (e) {
      debugPrint('❌ Cloudinary error: $e');
      return null;
    }
  }

  Future<void> saveBoxToFirestore(GiftBox box) async {
    try {
      List<Surprise> updatedSurprises = [];

      for (var surprise in box.surprises) {
        if ((surprise.type == SurpriseType.image ||
            surprise.type == SurpriseType.video ||
            surprise.type == SurpriseType.voiceNote) &&
            surprise.mediaUrl != null &&
            !surprise.mediaUrl!.startsWith('http')) {

          final urls = <String>[];
          final paths = surprise.mediaUrl!.split('|||');

          for (var localPath in paths) {
            if (localPath.isEmpty) continue;
            final uploadedUrl = await _uploadToCloudinary(localPath);
            urls.add(uploadedUrl ?? localPath);
          }

          updatedSurprises.add(Surprise(
            id: surprise.id,
            type: surprise.type,
            content: surprise.content,
            mediaUrl: urls.join('|||'),
          ));
        } else {
          updatedSurprises.add(surprise);
        }
      }

      final updatedBox = box.copyWith(surprises: updatedSurprises);
      await FirebaseFirestore.instance
          .collection('gifts')
          .doc(box.id)
          .set(updatedBox.toJson());

      debugPrint('✅ Gift Firestore mein save ho gaya: ${box.id}');
    } catch (e) {
      debugPrint('❌ Firestore save error: $e');
    }
  }

  Future<void> _persistBoxes() async {
    try {
      if (_userBoxes.isEmpty) return;
      final userId = _userBoxes.first.creatorId;
      final prefs = await SharedPreferences.getInstance();
      final key = 'boxes_$userId';
      final encoded =
      jsonEncode(_userBoxes.map((b) => b.toJson()).toList());
      await prefs.setString(key, encoded);
    } catch (e) {
      debugPrint('BoxProvider _persistBoxes error: $e');
    }
  }

  // ─── DELETE ────────────────────────────────────────────

  Future<void> deleteBox(String boxId) async {
    _userBoxes.removeWhere((b) => b.id == boxId);
    if (_currentBox?.id == boxId) _currentBox = null;
    notifyListeners();
    await _persistBoxes();

    try {
      await FirebaseFirestore.instance
          .collection('gifts')
          .doc(boxId)
          .delete();
    } catch (e) {
      debugPrint('Firestore delete error: $e');
    }
  }

  // ─── EDIT ──────────────────────────────────────────────

  Future<void> editBox(GiftBox updatedBox) async {
    final idx = _userBoxes.indexWhere((b) => b.id == updatedBox.id);
    if (idx != -1) {
      // ✅ YEH ADD KARO - Time update karo taake pata chale ke edit hua
      final boxWithTime = updatedBox.copyWith(
        createdAt: DateTime.now(),  // Ya alag field banao `updatedAt`
      );

      _userBoxes[idx] = boxWithTime;
      if (_currentBox?.id == updatedBox.id) _currentBox = boxWithTime;
      notifyListeners();
      await _persistBoxes();
      await saveBoxToFirestore(boxWithTime);
    }
  }

  void clearCurrentBox() {
    _currentBox = null;
    notifyListeners();
  }
}