import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/box_provider.dart';
import '../models/box_model.dart';
import '../services/settings_service.dart';
import 'create_box_screen.dart';
import 'open_box_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      context.read<BoxProvider>().loadUserBoxes(context.read<AuthProvider>().user!.uid);
      if (await SettingsService().getMusic()) SettingsService().playBgMusic();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final boxes = context.watch<BoxProvider>().userBoxes;

    return Scaffold(
      backgroundColor: const Color(0xFF0d0d1a),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('🎁 My Gift Boxes',
            style: TextStyle(color: Colors.amber[400], fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
              icon: Icon(Icons.settings, color: Colors.purple[200]),
              onPressed: () => _showSettings(context)),
          IconButton(
              icon: Icon(Icons.logout, color: Colors.red[300]),
              onPressed: () => _showLogoutDialog(context)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          SettingsService().hapticTap();
          Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CreateBoxScreen()));
        },
        backgroundColor: Colors.purple[600],
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Gift Box',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
      body: Column(children: [
        // ─── User header card ───────────────────────────────
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              Colors.purple[900]!.withOpacity(0.6),
              Colors.indigo[900]!.withOpacity(0.6)
            ]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.purple.withOpacity(0.3)),
          ),
          child: Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  color: Colors.purple[600],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.amber.withOpacity(0.5), width: 2)),
              child: Center(
                  child: Text(
                    (auth.user?.displayName ?? auth.user?.email ?? 'U')
                        .substring(0, 1)
                        .toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  )),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(auth.user?.displayName ?? 'Gift Creator',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(auth.user?.email ?? '',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.6), fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withOpacity(0.5))),
              child: Text('${boxes.length} Boxes',
                  style: TextStyle(
                      color: Colors.amber[300],
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ),
          ]),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.3),

        // ─── Box list ────────────────────────────────────────
        Expanded(
          child: boxes.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            itemCount: boxes.length,
            itemBuilder: (context, i) => _buildBoxCard(context, boxes[i], i)
                .animate()
                .fadeIn(duration: 300.ms, delay: (i * 80).ms)
                .slideX(begin: 0.3, end: 0),
          ),
        ),
      ]),
    );
  }

  Widget _buildEmptyState() => Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('🎁', style: TextStyle(fontSize: 80))
            .animate(onPlay: (c) => c.repeat())
            .scale(
            begin: const Offset(0.9, 0.9),
            end: const Offset(1.1, 1.1),
            duration: 1200.ms)
            .then()
            .scale(
            begin: const Offset(1.1, 1.1),
            end: const Offset(0.9, 0.9),
            duration: 1200.ms),
        const SizedBox(height: 16),
        Text('There is no gift box!',
            style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 22,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('first of all make gift box ! 🎊',
            style:
            TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
      ]));

  Widget _buildBoxCard(BuildContext context, GiftBox box, int i) {
    final colors = [
      Colors.purple,
      Colors.pink,
      Colors.blue,
      Colors.orange,
      Colors.green
    ];
    final color = colors[i % colors.length];

    return Card(
      color: Colors.white.withOpacity(0.05),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color.withOpacity(0.4), width: 1.5)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          SettingsService().hapticTap();
          context.read<BoxProvider>().setCurrentBox(box);
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const OpenBoxScreen()));
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            // ─── Box emoji icon ──────────────────────────────
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    color.withOpacity(0.3),
                    color.withOpacity(0.6)
                  ]),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withOpacity(0.5))),
              child: Center(
                  child: Text(_getBoxEmoji(box.selectedBoxColor),
                      style: const TextStyle(fontSize: 28))),
            ),
            const SizedBox(width: 10),

            // ─── Box info ────────────────────────────────────
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(box.giftName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(children: [
                        Icon(Icons.person_outline,
                            color: Colors.white.withOpacity(0.5), size: 14),
                        const SizedBox(width: 4),
                        Flexible(
                            child: Text('For: ${box.receiverName}',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis)),
                      ]),
                      const SizedBox(height: 2),
                      Row(children: [
                        Icon(Icons.card_giftcard,
                            color: color.withOpacity(0.7), size: 13),
                        const SizedBox(width: 3),
                        Flexible(
                            child: Text('${box.surprises.length} surprises',
                                style: TextStyle(
                                    color: color.withOpacity(0.8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 8),
                        Icon(Icons.access_time,
                            color: Colors.white.withOpacity(0.3), size: 11),
                        const SizedBox(width: 3),
                        Flexible(
                            child: Text(_formatDate(box.createdAt),
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.3),
                                    fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis)),
                      ]),
                    ])),
            const SizedBox(width: 6),

            // ─── Action buttons: Open / Edit / Delete ────────
            SizedBox(
              width: 64,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // Open button
                GestureDetector(
                  onTap: () {
                    SettingsService().hapticTap();
                    context.read<BoxProvider>().setCurrentBox(box);
                    Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const OpenBoxScreen()));
                  },
                  child: Container(
                    width: double.infinity,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                    decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: color.withOpacity(0.5))),
                    child: Text('Open',
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
                ),
                const SizedBox(height: 5),

                // ✅ Edit button — CreateBoxScreen pre-filled ke saath khulega
                GestureDetector(
                  onTap: () => _editBox(context, box),
                  child: Container(
                    width: double.infinity,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                    decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.withOpacity(0.4))),
                    child: Text('Edit',
                        style: TextStyle(
                            color: Colors.amber[400],
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
                ),
                const SizedBox(height: 5),

                // Delete button
                GestureDetector(
                  onTap: () => _showDeleteDialog(context, box),
                  child: Container(
                    width: double.infinity,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                    decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border:
                        Border.all(color: Colors.red.withOpacity(0.3))),
                    child: Text('Delete',
                        style: TextStyle(
                            color: Colors.red[400],
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  // ✅ Edit function — CreateBoxScreen mein editBox pass karo
  void _editBox(BuildContext context, GiftBox box) {
    SettingsService().hapticTap();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateBoxScreen(editBox: box),
      ),
    );
  }

  String _getBoxEmoji(String? c) {
    if (c == 'Ruby Box') return '❤️';
    if (c == 'Sapphire Box') return '💙';
    if (c == 'Emerald Box') return '💚';
    if (c == 'Golden Box') return '💛';
    return '🎁';
  }

  String _formatDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';

  void _showDeleteDialog(BuildContext context, GiftBox box) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1a1a2e),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Text('Delete Gift Box?',
              style: TextStyle(
                  color: Colors.red[300], fontWeight: FontWeight.bold)),
          content: Text('"${box.giftName}" ko delete karna chahte ho?',
              style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel',
                    style: TextStyle(color: Colors.grey[400]))),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.read<BoxProvider>().deleteBox(box.id);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: const Text('🗑️ Deleted!'),
                    backgroundColor: Colors.red[700]));
              },
              style:
              ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
              child: const Text('Delete'),
            ),
          ],
        ));
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1a1a2e),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Text('Logout?',
              style: TextStyle(
                  color: Colors.amber[400], fontWeight: FontWeight.bold)),
          content: const Text('you want to logout?',
              style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel',
                    style: TextStyle(color: Colors.grey[400]))),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await context.read<AuthProvider>().signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                  );
                }
              },
              style:
              ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
              child: const Text('Logout'),
            ),
          ],
        ));
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1a1a2e),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) {
        return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 16,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
              child: FutureBuilder<List<bool>>(
                future: Future.wait([
                  SettingsService().getNotifications(),
                  SettingsService().getMusic(),
                  SettingsService().getHaptic()
                ]),
                builder: (_, snap) {
                  final n = snap.data?[0] ?? true;
                  final m = snap.data?[1] ?? false;
                  final h = snap.data?[2] ?? true;
                  return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                            child: Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(2)))),
                        const SizedBox(height: 20),
                        Text('⚙️ Settings',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber[400])),
                        const SizedBox(height: 16),
                        _toggleTile(Icons.notifications, 'Notifications',
                            n ? 'On' : 'Off', Colors.blue, n, (v) async {
                              await SettingsService().setNotifications(v);
                              setSt(() {});
                            }),
                        _toggleTile(Icons.music_note, 'Background Music',
                            m ? 'Playing 🎵' : 'Off', Colors.purple, m,
                                (v) async {
                              await SettingsService().setMusic(v);
                              setSt(() {});
                            }),
                        _toggleTile(Icons.vibration, 'Haptic Feedback',
                            h ? 'On' : 'Off', Colors.orange, h, (v) async {
                              await SettingsService().setHaptic(v);
                              SettingsService().hapticTap();
                              setSt(() {});
                            }),
                        _actionTile(Icons.info, 'App Version', 'v1.0.0',
                            Colors.cyan, () {
                              showAboutDialog(
                                  context: context,
                                  applicationName: 'Mystery Gift Box',
                                  applicationVersion: 'v1.0.0',
                                  applicationIcon:
                                  const Text('🎁', style: TextStyle(fontSize: 40)));
                            }),
                        const SizedBox(height: 16),
                        const Divider(color: Colors.white24),
                        const SizedBox(height: 12),
                        SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _showLogoutDialog(context);
                              },
                              icon: const Icon(Icons.logout),
                              label: const Text('Logout',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red[700],
                                  foregroundColor: Colors.white,
                                  padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14))),
                            )),
                        const SizedBox(height: 8),
                      ]);
                },
              ),
            ));
      }),
    );
  }

  Widget _toggleTile(IconData icon, String title, String sub, Color color,
      bool value, Function(bool) onChanged) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 22)),
      title: Text(title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      subtitle: Text(sub,
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
      trailing: Switch(value: value, onChanged: onChanged, activeColor: color),
    );
  }

  Widget _actionTile(IconData icon, String title, String sub, Color color,
      VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 22)),
      title: Text(title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      subtitle: Text(sub,
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
      trailing:
      Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.3)),
    );
  }
}