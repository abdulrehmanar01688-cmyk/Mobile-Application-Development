import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/box_model.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/auth_provider.dart';
import '../providers/box_provider.dart';
import 'box_selection_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class CreateBoxScreen extends StatefulWidget {
  // ✅ Optional editBox — agar diya toh edit mode, nahi diya toh create mode
  final GiftBox? editBox;
  const CreateBoxScreen({super.key, this.editBox});

  @override
  State<CreateBoxScreen> createState() => _CreateBoxScreenState();
}

class _CreateBoxScreenState extends State<CreateBoxScreen> {
  final _giftNameController = TextEditingController();
  final _receiverNameController = TextEditingController();
  final _noteController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final List<Surprise> _surprises = [];
  final ImagePicker _picker = ImagePicker();

  // ✅ Edit mode hai ya create mode
  bool get _isEditMode => widget.editBox != null;

  @override
  void initState() {
    super.initState();
    // ✅ Agar editBox diya hai toh fields pre-fill karo
    if (_isEditMode) {
      final box = widget.editBox!;
      _giftNameController.text = box.giftName;
      _receiverNameController.text = box.receiverName;
      _noteController.text = box.note ?? '';
      _surprises.addAll(box.surprises);
    }
  }

  @override
  void dispose() {
    _giftNameController.dispose();
    _receiverNameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // ✅ Title edit/create mode ke hisaab se
        title: Text(
          _isEditMode ? 'Edit Gift Box ✏️' : 'Create Mystery Gift 🎁',
          style: TextStyle(color: Colors.amber[400]),
        ),
        iconTheme: IconThemeData(color: Colors.purple[200]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStepIndicator().animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 30),
              _buildSectionTitle('Gift Details').animate().fadeIn(duration: 400.ms, delay: 100.ms),
              const SizedBox(height: 16),
              _buildTextField(controller: _giftNameController, label: 'Gift Name', hint: 'e.g., Birthday Surprise', icon: Icons.card_giftcard).animate().fadeIn(duration: 400.ms, delay: 200.ms),
              const SizedBox(height: 16),
              _buildTextField(controller: _receiverNameController, label: 'Receiver Name', hint: 'Who is this gift for?', icon: Icons.person).animate().fadeIn(duration: 400.ms, delay: 300.ms),
              const SizedBox(height: 16),
              _buildTextField(controller: _noteController, label: 'Special Message (show inside Letter ) 💌', hint: 'Write a sweet message...', icon: Icons.message, maxLines: 3, required: false).animate().fadeIn(duration: 400.ms, delay: 400.ms),
              const SizedBox(height: 30),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.tips_and_updates, color: Colors.amber[400], size: 16),
                      const SizedBox(width: 6),
                      Text('Tips', style: TextStyle(color: Colors.amber[400], fontWeight: FontWeight.bold)),
                    ]),
                    const SizedBox(height: 6),
                    Text('• there are 10 ballons add 10 surprises if u want', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text('• Balloon 3 = Auto Joker Bottle 🃏 (built-in)', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text('• Balloon 5 = Cute Teddy with flowers 🧸', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text('• Mind Game = 5 quiz questions with icon options 🧠', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text('• Balloon 10 = 3 nested balloons 🎊', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text('• Multiple Videos = 1 balloon, play in sequence ', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text('• Mini Gift = 10 nested gifts → Dove + Letter', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text('• your message is hide into letter 💌', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 450.ms),

              const SizedBox(height: 20),
              _buildSectionTitle('Add Surprises (${_surprises.length}/10)').animate().fadeIn(duration: 400.ms, delay: 500.ms),
              const SizedBox(height: 8),
              Text('Photo/Video and Message add multiple time!', style: TextStyle(color: Colors.purple[300], fontSize: 12)).animate().fadeIn(duration: 400.ms, delay: 550.ms),
              const SizedBox(height: 16),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildSurpriseChip('📸 Photo', Icons.image, Colors.blue, _addPhoto),
                  _buildSurpriseChip('🎬 Video', Icons.videocam, Colors.red, _addVideo),
                  _buildSurpriseChip('💬 Message', Icons.message, Colors.green, _addMessage),
                  _buildSurpriseChip('🎙️ Voice', Icons.mic, Colors.orange, _addVoice),
                  _buildSurpriseChip('🧠 Mind Game', Icons.psychology, Colors.deepPurple, _addMindGame),
                  _buildSurpriseChip('🎩 Magician', Icons.auto_awesome, Colors.cyan, _addMagicEffect),
                  _buildSurpriseChip('🎁 Mini Gift', Icons.card_giftcard, Colors.purple, _addMiniGift),
                ],
              ).animate().fadeIn(duration: 400.ms, delay: 600.ms),

              const SizedBox(height: 20),
              if (_surprises.isNotEmpty)
                ..._surprises.asMap().entries.map((entry) {
                  return _buildSurpriseCard(entry.value, entry.key).animate().fadeIn(duration: 300.ms);
                }),

              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _surprises.isEmpty ? null : () {
                  if (_formKey.currentState!.validate()) {
                    final authProvider = context.read<AuthProvider>();
                    final boxProvider = context.read<BoxProvider>();

                    // ✅ Edit mode: purana ID rakho, naya ID mat banao
                    final box = GiftBox(
                      id: _isEditMode ? widget.editBox!.id : const Uuid().v4(),
                      creatorId: authProvider.user!.uid,
                      giftName: _giftNameController.text,
                      receiverName: _receiverNameController.text,
                      note: _noteController.text.isEmpty ? null : _noteController.text,
                      surprises: _surprises,
                      // ✅ Edit mode: purani createdAt rakho
                      createdAt: _isEditMode ? widget.editBox!.createdAt : DateTime.now(),
                      shareableLink: _isEditMode ? widget.editBox!.shareableLink : '',
                      // ✅ Edit mode: purana selectedBoxColor rakho agar tha
                      selectedBoxColor: _isEditMode ? widget.editBox!.selectedBoxColor : null,
                    );
                    boxProvider.setCurrentBox(box);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const BoxSelectionScreen()),
                    );
                  }
                },
                icon: Icon(_isEditMode ? Icons.save : Icons.arrow_forward),
                label: Text(
                  _isEditMode ? 'Save Changes' : 'Continue to Box Selection',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isEditMode ? Colors.green[700] : Colors.purple[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 700.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(children: [
      _buildStepCircle(1, 'Details', true),
      _buildStepLine(),
      _buildStepCircle(2, 'Box', false),
      _buildStepLine(),
      _buildStepCircle(3, 'Share', false),
    ]);
  }

  Widget _buildStepCircle(int step, String label, bool active) {
    return Column(children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: active ? Colors.purple[600] : Colors.grey[800],
          shape: BoxShape.circle,
          border: Border.all(color: active ? Colors.purple[400]! : Colors.grey[700]!, width: 2),
        ),
        child: Center(child: Text('$step', style: TextStyle(color: active ? Colors.white : Colors.grey[500], fontWeight: FontWeight.bold))),
      ),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 12, color: active ? Colors.purple[200] : Colors.grey[600])),
    ]);
  }

  Widget _buildStepLine() {
    return Expanded(child: Container(height: 2, margin: const EdgeInsets.only(bottom: 20), color: Colors.grey[800]));
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amber[400]));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    bool required = true,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: Colors.purple[200]),
        hintStyle: TextStyle(color: Colors.grey[600]),
        prefixIcon: Icon(icon, color: Colors.purple[300]),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.purple.withOpacity(0.2))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.purple, width: 2)),
      ),
      validator: (value) {
        if (required && (value?.isEmpty ?? true)) return '$label required';
        return null;
      },
    );
  }

  Widget _buildSurpriseChip(String label, IconData icon, Color color, VoidCallback onTap) {
    return ActionChip(
      avatar: Icon(icon, color: color, size: 18),
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      backgroundColor: color.withOpacity(0.2),
      side: BorderSide(color: color.withOpacity(0.3)),
      onPressed: _surprises.length >= 10 ? null : onTap,
    );
  }

  Widget _buildSurpriseCard(Surprise surprise, int index) {
    IconData icon;
    Color color;
    String subtitle;

    switch (surprise.type) {
      case SurpriseType.image: icon = Icons.image; color = Colors.blue; subtitle = 'Photo 📸'; break;
      case SurpriseType.video:
        icon = Icons.videocam; color = Colors.red;
        final count = (surprise.mediaUrl ?? '').split('|||').where((p) => p.isNotEmpty).length;
        subtitle = count > 1 ? 'Video Sequence 🎬 ($count videos)' : 'Video 🎬';
        break;
      case SurpriseType.message: icon = Icons.message; color = Colors.green; subtitle = surprise.content ?? 'Message'; break;
      case SurpriseType.voiceNote: icon = Icons.mic; color = Colors.orange; subtitle = 'Voice Note 🎙️'; break;
      case SurpriseType.funnyPopup: icon = Icons.warning_amber; color = Colors.pink; subtitle = 'Prank Warning 😈'; break;
      case SurpriseType.jokerAnimation: icon = Icons.theater_comedy; color = Colors.yellow; subtitle = 'Joker Bottle 🃏'; break;
      case SurpriseType.soundEffect: icon = Icons.auto_awesome; color = Colors.cyan; subtitle = 'Magician Cake 🎩'; break;
      case SurpriseType.miniGift: icon = Icons.card_giftcard; color = Colors.purple; subtitle = 'Mini Gift Chain 🎁'; break;
      case SurpriseType.mindGame: icon = Icons.psychology; color = Colors.deepPurple; subtitle = 'Mind Game 🧠'; break;
    }

    Widget leading;
    if (surprise.type == SurpriseType.image && surprise.mediaUrl != null && File(surprise.mediaUrl!).existsSync()) {
      leading = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(File(surprise.mediaUrl!), width: 44, height: 44, fit: BoxFit.cover),
      );
    } else {
      leading = Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color),
      );
    }

    return Card(
      color: Colors.white.withOpacity(0.05),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
      child: ListTile(
        leading: leading,
        title: Text('Surprise ${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.7)), maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
          onPressed: () => setState(() => _surprises.removeAt(index)),
        ),
      ),
    );
  }

  Future<void> _addPhoto() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        for (var image in images) {
          if (_surprises.length < 10) {
            _surprises.add(Surprise(id: const Uuid().v4(), type: SurpriseType.image, mediaUrl: image.path));
          }
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('📸 ${images.length} photo(s) add ho gayi!'), backgroundColor: Colors.green[700], duration: const Duration(seconds: 2)),
        );
      }
    }
  }

  Future<void> _addVideo() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('🎬 add video', style: TextStyle(color: Colors.amber[400]), textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
                if (video != null && _surprises.length < 10) {
                  setState(() {
                    _surprises.add(Surprise(id: const Uuid().v4(), type: SurpriseType.video, mediaUrl: video.path));
                  });
                }
              },
              icon: const Icon(Icons.video_library),
              label: const Text(' Choose 1 Video '),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600], minimumSize: const Size(double.infinity, 48)),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                final List<String> collectedPaths = [];
                while (_surprises.length < 10) {
                  final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
                  if (video == null) break;
                  collectedPaths.add(video.path);
                  if (!mounted) break;
                  final addMore = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      backgroundColor: const Color(0xFF1a1a2e),
                      title: Text('more video? (${collectedPaths.length} added)', style: const TextStyle(color: Colors.white)),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(c, false), child: Text('enough, done', style: TextStyle(color: Colors.grey[400]))),
                        ElevatedButton(onPressed: () => Navigator.pop(c, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.purple[600]), child: const Text('Haan, aur add karo')),
                      ],
                    ),
                  ) ?? false;
                  if (!addMore) break;
                }
                if (collectedPaths.isNotEmpty && _surprises.length < 10) {
                  setState(() {
                    _surprises.add(Surprise(
                      id: const Uuid().v4(),
                      type: SurpriseType.video,
                      mediaUrl: collectedPaths.join('|||'),
                    ));
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('🎬 ${collectedPaths.length} videos add in 1 ballon! play in sequence.'),
                        backgroundColor: Colors.deepOrange[700],
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.video_collection),
              label: const Text('Multiple Videos (in 1 balloon )'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange[600], minimumSize: const Size(double.infinity, 48)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: Colors.grey[400]))),
        ],
      ),
    );
  }

  void _addMessage() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1a1a2e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('💬 add Message ', style: TextStyle(color: Colors.amber[400], fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.purple.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                  child: Text('till now there are ${_surprises.where((s) => s.type == SurpriseType.message).length} messages', style: TextStyle(color: Colors.purple[200], fontSize: 12)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'write your message...',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.purple.withOpacity(0.3))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.purple.withOpacity(0.3))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.purple, width: 2)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: Colors.grey[400]))),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        if (controller.text.isNotEmpty && _surprises.length < 10) {
                          setState(() { _surprises.add(Surprise(id: const Uuid().v4(), type: SurpriseType.message, content: controller.text)); });
                          controller.clear();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Add! Aur likho...'), backgroundColor: Colors.green[700], duration: const Duration(seconds: 1)));
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
                      child: const Text('+ more'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (controller.text.isNotEmpty && _surprises.length < 10) {
                          setState(() { _surprises.add(Surprise(id: const Uuid().v4(), type: SurpriseType.message, content: controller.text)); });
                        }
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.purple[600]),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addVoice() async {
    final FlutterSoundRecorder recorder = FlutterSoundRecorder();
    bool isRecording = false;
    String? recordedPath;
    await Permission.microphone.request();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1a1a2e),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('🎙️ Voice Message', style: TextStyle(color: Colors.amber[400]), textAlign: TextAlign.center),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('record from mic or choose from file', style: TextStyle(color: Colors.white70), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                if (recordedPath != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [Icon(Icons.check_circle, color: Colors.green[400]), const SizedBox(width: 8), const Text('Voice ready!', style: TextStyle(color: Colors.white))]),
                  ),
                if (!isRecording)
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await recorder.openRecorder();
                        final dir = await getTemporaryDirectory();
                        final path = p.join(dir.path, 'voice_${DateTime.now().millisecondsSinceEpoch}.aac');
                        await recorder.startRecorder(toFile: path);
                        setDialogState(() { isRecording = true; recordedPath = path; });
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                      }
                    },
                    icon: const Icon(Icons.mic),
                    label: const Text('Start Recording 🔴'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600], minimumSize: const Size(double.infinity, 48)),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () async {
                      await recorder.stopRecorder();
                      await recorder.closeRecorder();
                      setDialogState(() => isRecording = false);
                    },
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop Recording ⏹️'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[700], minimumSize: const Size(double.infinity, 48)),
                  ),
                if (isRecording)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))
                            .animate(onPlay: (c) => c.repeat()).fadeIn(duration: 500.ms).then().fadeOut(duration: 500.ms),
                        const SizedBox(width: 8),
                        Text('Recording...', style: TextStyle(color: Colors.red[300])),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                const Divider(color: Colors.white24),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final XFile? file = await _picker.pickMedia();
                    if (file != null) setDialogState(() => recordedPath = file.path);
                  },
                  icon: const Icon(Icons.folder_open),
                  label: const Text('choose from files'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: BorderSide(color: Colors.purple[300]!), minimumSize: const Size(double.infinity, 48)),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  if (isRecording) { await recorder.stopRecorder(); await recorder.closeRecorder(); }
                  Navigator.pop(ctx);
                },
                child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
              ),
              ElevatedButton(
                onPressed: recordedPath == null || isRecording ? null : () {
                  setState(() { _surprises.add(Surprise(id: const Uuid().v4(), type: SurpriseType.voiceNote, mediaUrl: recordedPath)); });
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple[600]),
                child: const Text('Add Voice'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _addMindGame() {
    setState(() { _surprises.add(Surprise(id: const Uuid().v4(), type: SurpriseType.mindGame)); });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('🧠 Mind Game added! (5 questions)'),
      backgroundColor: Colors.deepPurple[700],
      duration: const Duration(seconds: 2),
    ));
  }

  void _addMagicEffect() {
    setState(() { _surprises.add(Surprise(id: const Uuid().v4(), type: SurpriseType.soundEffect)); });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('🎩 Magician Cake added!'), backgroundColor: Colors.cyan[700], duration: const Duration(seconds: 1)));
  }

  void _addMiniGift() {
    final msgCtrl = TextEditingController(text: _noteController.text);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1a1a2e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🎁 Mini Gift Chain', style: TextStyle(color: Colors.amber[400], fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Text('there are 10 nested gifts !\nIn the final gift, a dove and a hidden letter will appear! 🕊️', style: TextStyle(color: Colors.white70), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                TextField(
                  controller: msgCtrl,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: ' hidden message of letter',
                    labelStyle: TextStyle(color: Colors.purple[200]),
                    hintText: 'it will be hide in letter... 💌',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.purple.withOpacity(0.3))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.purple.withOpacity(0.3))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.purple, width: 2)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: Colors.grey[400]))),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        setState(() { _surprises.add(Surprise(id: const Uuid().v4(), type: SurpriseType.miniGift, content: msgCtrl.text.isNotEmpty ? msgCtrl.text : _noteController.text)); });
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('🎁 Mini Gift Chain add! 10 gifts!'), backgroundColor: Colors.purple[700], duration: const Duration(seconds: 2)));
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.purple[600]),
                      child: const Text('Add Gift Chain'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}