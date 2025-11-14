// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:gallery/screens/gallery_screen.dart';
// import 'package:gallery/screens/google_photos_screen.dart';

// class AuthScreen extends StatefulWidget {
//   const AuthScreen({super.key});

//   @override
//   State<AuthScreen> createState() => _AuthScreenState();
// }

// class _AuthScreenState extends State<AuthScreen> {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: <String>[
//     'https://www.googleapis.com/auth/photoslibrary.readonly'
//   ]);
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   bool _isLogin = true;
//   bool _isLoading = false;

//   Future<void> _authenticate() async {
//     if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please fill in all fields')),
//       );
//       return;
//     }

//     setState(() => _isLoading = true);

//     try {
//       if (_isLogin) {
//         await _auth.signInWithEmailAndPassword(
//           email: _emailController.text.trim(),
//           password: _passwordController.text.trim(),
//         );
//       } else {
//         await _auth.createUserWithEmailAndPassword(
//           email: _emailController.text.trim(),
//           password: _passwordController.text.trim(),
//         );
//       }

//       if (mounted) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (context) => GalleryScreen()),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Authentication failed: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     }
//   }

//   // Future<void> _googleSignInHandler() async {
//   //   try {
//   //     final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
//   //     if (googleUser == null) {
//   //       // The user canceled the sign-in
//   //       return;
//   //     }
//   //     final GoogleSignInAuthentication googleAuth =
//   //         await googleUser.authentication;
//   //     final AuthCredential credential = GoogleAuthProvider.credential(
//   //       accessToken: googleAuth.accessToken,
//   //       idToken: googleAuth.idToken,
//   //     );
//   //     await _auth.signInWithCredential(credential);
//   //     if (mounted) {
//   //       Navigator.pushReplacement(
//   //         context,
//   //         MaterialPageRoute(
//   //             builder: (context) =>
//   //                 GooglePhotosScreen(googleSignIn: _googleSignIn)),
//   //       );
//   //     }
//   //   } catch (e) {
//   //     if (mounted) {
//   //       ScaffoldMessenger.of(context).showSnackBar(
//   //         SnackBar(
//   //           content: Text('Google Sign-In failed: $e'),
//   //           backgroundColor: Colors.red,
//   //         ),
//   //       );
//   //     }
//   //   }
//   // }
// Future<void> _googleSignInHandler() async {
//   try {
//     final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
//     if (googleUser == null) return;

//     // Required for Firebase Auth
//     final googleAuth = await googleUser.authentication;

//     final credential = GoogleAuthProvider.credential(
//       idToken: googleAuth.idToken,
//       accessToken: googleAuth.accessToken,
//     );

//     await _auth.signInWithCredential(credential);

//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(
//         builder: (context) => GooglePhotosScreen(
//           googleSignIn: _googleSignIn,
//         ),
//       ),
//     );
//   } catch (e) {
//     print("Error: $e");
//   }
// }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Gallery App'),
//         backgroundColor: Theme.of(context).colorScheme.inversePrimary,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Text(
//               'Welcome to Gallery',
//               style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 32),
//             TextField(
//               controller: _emailController,
//               decoration: const InputDecoration(
//                 labelText: 'Email',
//                 border: OutlineInputBorder(),
//                 prefixIcon: Icon(Icons.email),
//               ),
//               keyboardType: TextInputType.emailAddress,
//             ),
//             const SizedBox(height: 16),
//             TextField(
//               controller: _passwordController,
//               decoration: const InputDecoration(
//                 labelText: 'Password',
//                 border: OutlineInputBorder(),
//                 prefixIcon: Icon(Icons.lock),
//               ),
//               obscureText: true,
//             ),
//             const SizedBox(height: 24),
//             SizedBox(
//               width: double.infinity,
//               height: 48,
//               child: ElevatedButton(
//                 onPressed: _isLoading ? null : _authenticate,
//                 child: _isLoading
//                     ? const CircularProgressIndicator()
//                     : Text(_isLogin ? 'Sign In' : 'Sign Up'),
//               ),
//             ),
//             const SizedBox(height: 16),
//             TextButton(
//               onPressed: () => setState(() => _isLogin = !_isLogin),
//               child: Text(
//                 _isLogin
//                     ? 'Don\'t have an account? Sign Up'
//                     : 'Already have an account? Sign In',
//               ),
//             ),
//             const SizedBox(height: 16),
//             TextButton(
//               onPressed: () {
//                 Navigator.pushReplacement(
//                   context,
//                   MaterialPageRoute(builder: (context) => GalleryScreen()),
//                 );
//               },
//               child: const Text('Skip for now'),
//             ),
//             const SizedBox(height: 16),
//             ElevatedButton.icon(
//               onPressed: _googleSignInHandler,
//               icon: const Icon(Icons.login),
//               label: const Text('Sign in with Google'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }
// }
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
    scopes: [
      'email',
      'openid',
      'https://www.googleapis.com/auth/photoslibrary.readonly',
    ],
    serverClientId: "730140148453-52a77dqnecglc36pcrhgtn86k1f1cib9.apps.googleusercontent.com", // ← VERY IMPORTANT !!!
  );

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  Future<void> _authenticate() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const GalleryScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Authentication failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _googleSignInHandler() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      // Firebase Auth Login
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      await _auth.signInWithCredential(credential);

      // Navigate to Google Photos Page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => GooglePhotosScreen(
            googleSignIn: _googleSignIn,
          ),
        ),
      );
    } catch (e) {
      debugPrint("Google Sign-In error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google Sign-In failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery App'),
      ),
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
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _authenticate,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(_isLogin ? 'Sign In' : 'Sign Up'),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => setState(() => _isLogin = !_isLogin),
              child: Text(
                _isLogin
                    ? "Don't have an account? Sign Up"
                    : "Already have an account? Sign In",
              ),
            ),
            const SizedBox(height: 16),
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
