import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:gallery/screens/gallery_screen.dart';
import 'package:gallery/screens/google_photos_screen.dart';
import 'package:gallery/screens/auth_screen.dart';


class HomeScreen extends StatefulWidget {
  final GoogleSignIn? googleSignIn;

  const HomeScreen({super.key, this.googleSignIn});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Local'),
            Tab(text: 'Cloud'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const GalleryScreen(),
          if (widget.googleSignIn != null)
            GooglePhotosScreen(googleSignIn: widget.googleSignIn!)
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Sign in to view Google Photos'),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AuthScreen(),
                        ),
                      );
                    },
                    child: const Text('Sign In'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
