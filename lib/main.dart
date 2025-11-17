import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:gallery/firebase_options.dart';
import 'package:gallery/screens/main_navigation_screen.dart';
import 'package:gallery/screens/shared_image_view_screen.dart';
import 'package:gallery/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late StreamSubscription _intentSub;
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _intentSub =
        ReceiveSharingIntent.instance.getMediaStream().listen((value) {
      if (value.isNotEmpty) {
        _navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) =>
                SharedImageViewScreen(imagePath: value.first.path),
          ),
        );
      }
    });

    ReceiveSharingIntent.instance.getInitialMedia().then((value) {
      if (value.isNotEmpty) {
        _navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) =>
                SharedImageViewScreen(imagePath: value.first.path),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _intentSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            navigatorKey: _navigatorKey,
            debugShowCheckedModeBanner: false,
            title: 'Gallery',
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color.fromARGB(255, 1, 2, 51), // Indigo
                brightness: Brightness.light,
              ),
              appBarTheme: const AppBarTheme(
                centerTitle: true,
                elevation: 0,
                scrolledUnderElevation: 0,
                backgroundColor: Colors.transparent,
                foregroundColor: Color(0xFF1F2937),
              ),
              cardTheme: CardThemeData(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
              ),
              filledButtonTheme: FilledButtonThemeData(
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color.fromARGB(255, 18, 28, 39), // Purple
                brightness: Brightness.dark,
              ),
              scaffoldBackgroundColor: const Color(0xFF0F172A),
              appBarTheme: const AppBarTheme(
                centerTitle: true,
                elevation: 0,
                scrolledUnderElevation: 0,
                backgroundColor: Colors.transparent,
                foregroundColor: Color(0xFFF1F5F9),
              ),
              cardTheme: CardThemeData(
                elevation: 0,
                color: const Color(0xFF1E293B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade800, width: 1),
                ),
              ),
              filledButtonTheme: FilledButtonThemeData(
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            themeMode: themeProvider.themeMode,
            home: const MainNavigationScreen(),
          );
        },
      ),
    );
  }
}
