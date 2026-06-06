import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/box_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/web_gift_receiver_screen.dart';
import 'services/audio_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Audio setup — sirf mobile pe (web pe yeh crash karta hai)
  if (!kIsWeb) {
    AudioPlayer.global.setAudioContext(
      AudioContext(
        android: AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gain,
        ),
      ),
    );
    await AudioService().init();
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BoxProvider()),
      ],
      child: MaterialApp(
        title: 'Mystery Gift Box',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.purple,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        // ✅ Web routing — /gift/:giftId URL handle karo
        home: _buildHome(),
        onGenerateRoute: (settings) {
          final uri = Uri.parse(settings.name ?? '/');
          if (uri.pathSegments.length == 2 &&
              uri.pathSegments[0] == 'gift') {
            final giftId = uri.pathSegments[1];
            return MaterialPageRoute(
              builder: (_) => WebGiftReceiverScreen(giftId: giftId),
            );
          }
          return MaterialPageRoute(
            builder: (_) => const SplashScreen(),
          );
        },
      ),
    );
  }

  // ✅ Web pe URL check karo — gift link hai toh seedha open karo
  Widget _buildHome() {
    if (kIsWeb) {
      final uri = Uri.base;
      final segments = uri.pathSegments;
      if (segments.length >= 2 && segments[0] == 'gift') {
        return WebGiftReceiverScreen(giftId: segments[1]);
      }
    }
    // Normal app flow
    return const SplashScreen();
  }
}