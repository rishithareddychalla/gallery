import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:gallery/screens/gallery_screen.dart';
import 'package:gallery/screens/google_photos_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // IMPORTANT → For google_sign_in: ^7.2.0
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'https://www.googleapis.com/auth/photoslibrary.readonly'],
    serverClientId:
        // "730140148453-52a77dqnecglc36pcrhgtn86k1f1cib9.apps.googleusercontent.com", // ← VERY IMPORTANT !!!
        "730140148453-52a77dqnecglc36pcrhgtn86k1f1cib9.apps.googleusercontent.com",
  );


  // Future<void> _googleSignInHandler() async {
  //   try {
  //     final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
  //     if (googleUser == null) return;

  //     // Firebase Auth Login
  //     final googleAuth = await googleUser.authentication;
  //     final credential = GoogleAuthProvider.credential(
  //       idToken: googleAuth.idToken,
  //       accessToken: googleAuth.accessToken,
  //     );

  //     await _auth.signInWithCredential(credential);

  //     // Navigate to Google Photos Page
  //     Navigator.pushReplacement(
  //       context,
  //       MaterialPageRoute(
  //         builder: (context) => GooglePhotosScreen(googleSignIn: _googleSignIn),
  //       ),
  //     );
  //   } catch (e) {
  //     debugPrint("Google Sign-In error: $e");
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Google Sign-In failed: $e'),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //   }
  // }
  Future<void> _googleSignInHandler() async {
    try {
      // IMPORTANT — completely clear old Google session
      // await _googleSignIn.disconnect();
      await _googleSignIn.signOut();

      // Now sign in fresh
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      // Get tokens
      final googleAuth = await googleUser.authentication;

      print("ID TOKEN: ${googleAuth.idToken}");
      print("ACCESS TOKEN: ${googleAuth.accessToken}");

      print("AUTH HEADERS: ${await googleUser.authHeaders}");

      // Firebase login
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => GooglePhotosScreen(googleSignIn: _googleSignIn),
        ),
      );
    } catch (e) {
      print("GOOGLE LOGIN ERROR: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gallery App')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to Gallery',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _googleSignInHandler,
              icon: const Icon(Icons.login),
              label: const Text("Sign In with Google"),
            ),
          ],
        ),
      ),
    );
  }
}
