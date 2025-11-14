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
      final response = await _photosLibraryApiClient!
          .get('https://photoslibrary.googleapis.com/v1/mediaItems');
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> mediaItems = data['mediaItems'];
      _nextPageToken = data['nextPageToken'];
      setState(() {
        _photoUrls =
            mediaItems.map((item) => item['baseUrl'] as String).toList();
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
          'https://photoslibrary.googleapis.com/v1/mediaItems?pageToken=$_nextPageToken');
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> mediaItems = data['mediaItems'];
      _nextPageToken = data['nextPageToken'];
      setState(() {
        _photoUrls.addAll(
            mediaItems.map((item) => item['baseUrl'] as String).toList());
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load more photos: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? Center(child: Text(_error!))
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
                  );
                },
              );
  }
}
