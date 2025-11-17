import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:gallery/photos_library_api_client.dart';

class GooglePhotosScreen extends StatefulWidget {
  const GooglePhotosScreen({super.key, required this.googleSignIn});

  final GoogleSignIn googleSignIn;

  @override
  State<GooglePhotosScreen> createState() => _GooglePhotosScreenState();
}

class _GooglePhotosScreenState extends State<GooglePhotosScreen> {
  bool _isLoading = true;
  List<String> _photoUrls = [];
  PhotosLibraryApiClient? _photosLibraryApiClient;
  String? _nextPageToken;
  String? _error;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _photosLibraryApiClient = PhotosLibraryApiClient(widget.googleSignIn);
    _fetchPhotos();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMorePhotos();
    }
  }

  Future<void> _fetchPhotos() async {
    try {
      print('Fetching photos from Google Photos API...');

      // Check if user is signed in
      final currentUser = widget.googleSignIn.currentUser;
      if (currentUser == null) {
        setState(() {
          _isLoading = false;
          _error = 'User not signed in. Please sign in with Google first.';
        });
        return;
      }

      print('Current user: ${currentUser.email}');

      final response = await _photosLibraryApiClient!.get(
        'https://photoslibrary.googleapis.com/v1/mediaItems',
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 403) {
        // Check if it's a scope issue
        if (response.body.contains('insufficient authentication scopes')) {
          setState(() {
            _isLoading = false;
            _error =
                'Insufficient permissions for Google Photos.\n\nPlease sign out and sign in again to grant the necessary permissions for accessing your Google Photos.';
          });
          return;
        }
      }

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

      print('Number of media items found: ${mediaItems?.length ?? 0}');

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

      print('Successfully loaded ${_photoUrls.length} photos');
    } catch (e, stackTrace) {
      print('Error fetching photos: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
        _error =
            'Failed to load photos: $e\n\nPlease check:\n1. Internet connection\n2. Google Photos permissions\n3. Try signing out and signing in again';
      });
    }
  }

  Future<void> _loadMorePhotos() async {
    if (_nextPageToken == null) {
      return;
    }
    try {
      print('Loading more photos with token: $_nextPageToken');
      final response = await _photosLibraryApiClient!.get(
        'https://photoslibrary.googleapis.com/v1/mediaItems?pageToken=$_nextPageToken',
      );

      print('Load more response status: ${response.statusCode}');

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

      print(
        'Loaded ${mediaItems.length} more photos. Total: ${_photoUrls.length}',
      );
    } catch (e, stackTrace) {
      print('Error loading more photos: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _error = 'Failed to load more photos: $e';
      });
    }
  }

  Future<void> _retry() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _photoUrls.clear();
      _nextPageToken = null;
    });
    await _fetchPhotos();
  }

  Future<void> _signOut() async {
    try {
      await widget.googleSignIn.signOut();
      if (mounted) {
        Navigator.of(context).pop(); // Go back to auth screen
      }
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Photos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
          if (_error != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _retry,
              tooltip: 'Retry',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading Google Photos...'),
                ],
              ),
            )
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        'Error Loading Photos',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(onPressed: _retry, child: Text('Retry')),
                    ],
                  ),
                ),
              ),
            )
          : _photoUrls.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text('No Photos Found', style: TextStyle(fontSize: 18)),
                  Text(
                    'Your Google Photos library appears to be empty.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : GridView.builder(
              controller: _scrollController,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4.0,
                mainAxisSpacing: 4.0,
              ),
              itemCount: _photoUrls.length,
              itemBuilder: (context, index) {
                return Image.network(
                  _photoUrls[index],
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    print('Error loading image at index $index: $error');
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.error, color: Colors.red),
                    );
                  },
                );
              },
            ),
    );
  }
}
