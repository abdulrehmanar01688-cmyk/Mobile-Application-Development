import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/box_model.dart';
import '../providers/box_provider.dart';
import '../services/audio_service.dart';
import 'open_box_screen.dart';

class BoxSelectionScreen extends StatefulWidget {
  const BoxSelectionScreen({super.key});

  @override
  State<BoxSelectionScreen> createState() => _BoxSelectionScreenState();
}

class _BoxSelectionScreenState extends State<BoxSelectionScreen> {
  int? _selectedIndex;
  final List<Map<String, dynamic>> _boxes = [
    {'color': Colors.red, 'name': 'Ruby Box', 'gradient': [Colors.red[800]!, Colors.red[400]!]},
    {'color': Colors.blue, 'name': 'Sapphire Box', 'gradient': [Colors.blue[800]!, Colors.blue[400]!]},
    {'color': Colors.green, 'name': 'Emerald Box', 'gradient': [Colors.green[800]!, Colors.green[400]!]},
    {'color': Colors.purple, 'name': 'Amethyst Box', 'gradient': [Colors.purple[800]!, Colors.purple[400]!]},
    {'color': Colors.orange, 'name': 'Golden Box', 'gradient': [Colors.orange[800]!, Colors.amber[400]!]},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Choose Your Box',
          style: TextStyle(color: Colors.amber[400]),
        ),
        iconTheme: IconThemeData(color: Colors.purple[200]),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),

          Text(
            'Select a Magical Box',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.purple[200],
            ),
          )
              .animate()
              .fadeIn(duration: 500.ms),

          const SizedBox(height: 8),

          Text(
            'Each box holds unique surprises!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.6),
            ),
          )
              .animate()
              .fadeIn(duration: 500.ms, delay: 200.ms),

          const SizedBox(height: 40),

          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _boxes.length,
              itemBuilder: (context, index) {
                final box = _boxes[index];
                final isSelected = _selectedIndex == index;

                return GestureDetector(
                  onTap: () {
                    AudioService().playSound('tap');  // ✅ Sirf sound name do, path nahi
                    setState(() => _selectedIndex = index);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    transform: isSelected
                        ? (Matrix4.identity()..scale(1.05))
                        : Matrix4.identity(),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: box['gradient'],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 3)
                          : Border.all(color: Colors.transparent),
                      boxShadow: [
                        BoxShadow(
                          color: box['color'].withOpacity(isSelected ? 0.6 : 0.3),
                          blurRadius: isSelected ? 25 : 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.card_giftcard,
                          size: 60,
                          color: Colors.white.withOpacity(0.9),
                        )
                            .animate(onPlay: (c) => c.repeat())
                            .shimmer(duration: 2000.ms),

                        const SizedBox(height: 12),

                        Text(
                          box['name'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),

                        if (isSelected)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Icon(
                              Icons.check_circle,
                              color: Colors.white.withOpacity(0.9),
                              size: 28,
                            ),
                          ),
                      ],
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: (index * 100).ms)
                    .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1));
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: ElevatedButton.icon(
              onPressed: _selectedIndex == null
                  ? null
                  : () {
                final boxProvider = context.read<BoxProvider>();
                final currentBox = boxProvider.currentBox;

                if (currentBox != null) {
                  final updatedBox = currentBox.copyWith(
                    selectedBoxColor: _boxes[_selectedIndex!]['name'],
                  );
                  boxProvider.setCurrentBox(updatedBox);

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const OpenBoxScreen(),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text(
                'Open Selected Box',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 600.ms),
        ],
      ),
    );
  }
}