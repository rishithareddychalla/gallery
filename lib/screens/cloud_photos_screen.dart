import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:gallery/photos_library_api_client.dart';
import 'package:gallery/widgets/theme_toggle_button.dart';

class CloudPhotosScreen extends StatefulWidget {
  const CloudPhotosScreen({super.key});

  @override
  State<CloudPhotosScreen> createState() => _CloudPhotosScreenState();
}

class _CloudPhotosScreenState extends State<CloudPhotosScreen> {
  bool _isLoading = true;
  List<String> _photoUrls = [];
  PhotosLibraryApiClient? _photosLibraryApiClient;
  String? _nextPageToken;
  String? _error;
  final ScrollController _scrollController = ScrollController();
  bool _isLoggedIn = false;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'https://www.googleapis.com/auth/photoslibrary.readonly'],
  );

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    final currentUser = await _googleSignIn.signInSilently();
    setState(() {
      _isLoggedIn = currentUser != null;
      _isLoading = false;
    });
    if (_isLoggedIn) {
      _photosLibraryApiClient = PhotosLibraryApiClient(_googleSignIn);
      _fetchPhotos();
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMorePhotos();
    }
  }

  Future<void> _googleSignInHandler() async {
    try {
      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      setState(() {
        _isLoggedIn = true;
      });
      _photosLibraryApiClient = PhotosLibraryApiClient(_googleSignIn);
      _fetchPhotos();
    } catch (e) {
      print("GOOGLE LOGIN ERROR: $e");
    }
  }

  Future<void> _fetchPhotos() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await _photosLibraryApiClient!.get(
        'https://photoslibrary.googleapis.com/v1/mediaItems',
      );

      if (response.statusCode != 200) {
        setState(() {
          _isLoading = false;
          _error = 'API Error: ${response.statusCode}\n${response.body}';
        });
        return;
      }

      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic>? mediaItems = data['mediaItems'];
      _nextPageToken = data['nextPageToken'];

      if (mediaItems == null || mediaItems.isEmpty) {
        setState(() {
          _isLoading = false;
          _error = 'No photos found in your Google Photos library.';
        });
        return;
      }

      setState(() {
        _photoUrls = mediaItems
            .map((item) => item['baseUrl'] as String)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load photos: $e';
      });
    }
  }

  Future<void> _loadMorePhotos() async {
    if (_nextPageToken == null) {
      return;
    }
    try {
      final response = await _photosLibraryApiClient!.get(
        'https://photoslibrary.googleapis.com/v1/mediaItems?pageToken=$_nextPageToken',
      );

      if (response.statusCode != 200) {
        setState(() {
          _error = 'Failed to load more photos: ${response.statusCode}';
        });
        return;
      }

      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic>? mediaItems = data['mediaItems'];
      _nextPageToken = data['nextPageToken'];

      if (mediaItems == null || mediaItems.isEmpty) {
        return;
      }

      setState(() {
        _photoUrls.addAll(
          mediaItems.map((item) => item['baseUrl'] as String).toList(),
        );
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load more photos: $e';
      });
    }
  }

  Future<void> _signOut() async {
    try {
      await _googleSignIn.signOut();
      setState(() {
        _isLoggedIn = false;
        _photoUrls = [];
      });
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Photos'),
        actions: [
          const ThemeToggleButton(),
          if (_isLoggedIn)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _signOut,
              tooltip: 'Sign Out',
            ),
        ],
      ),
      body: _isLoggedIn
          ? _buildPhotoGrid()
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Access Your Google Photos',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                      'Sign in with your Google account to view and access photos stored in Google Photos.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _googleSignInHandler,
                    icon: const Icon(Icons.login),
                    label: const Text("Sign In with Google"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPhotoGrid() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }
    return GridView.builder(
      controller: _scrollController,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4.0,
        mainAxisSpacing: 4.0,
      ),
      itemCount: _photoUrls.length,
      itemBuilder: (context, index) {
        return Image.network(_photoUrls[index], fit: BoxFit.cover);
      },
    );
  }
}
