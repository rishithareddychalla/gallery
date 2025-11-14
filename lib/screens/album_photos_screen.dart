import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:gallery/screens/photo_view_screen.dart';
import 'package:photo_manager/photo_manager.dart';

class AlbumPhotosScreen extends StatefulWidget {
  final AssetPathEntity album;

  const AlbumPhotosScreen({required this.album, Key? key}) : super(key: key);

  @override
  State<AlbumPhotosScreen> createState() => _AlbumPhotosScreenState();
}

class _AlbumPhotosScreenState extends State<AlbumPhotosScreen> {
  List<AssetEntity> _photos = [];
  bool _isLoading = true;
  String? _error;

  final Map<String, Uint8List> _thumbCache = {};

  @override
  void initState() {
    super.initState();
    _fetchPhotos();
  }

  Future<void> _fetchPhotos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final List<AssetEntity> photos = await widget.album.getAssetListRange(
        start: 0,
        end: widget.album.assetCount,
      );
      setState(() {
        _photos = photos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load photos: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.album.name),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _errorWidget()
              : _photos.isEmpty
                  ? const Center(child: Text('No photos found'))
                  : GridView.builder(
                      padding: const EdgeInsets.all(4),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                      ),
                      itemCount: _photos.length,
                      itemBuilder: (context, index) {
                        final asset = _photos[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    PhotoViewScreen(photo: asset),
                              ),
                            );
                          },
                          child: _ThumbTile(
                            asset: asset,
                            cache: _thumbCache,
                          ),
                        );
                      },
                    ),
    );
  }

  Widget _errorWidget() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchPhotos,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
}

class _ThumbTile extends StatelessWidget {
  final AssetEntity asset;
  final Map<String, Uint8List> cache;

  const _ThumbTile({required this.asset, required this.cache});

  @override
  Widget build(BuildContext context) {
    if (cache.containsKey(asset.id)) {
      return _imageWidget(cache[asset.id]!);
    }

    return FutureBuilder<Uint8List?>(
      future: asset.thumbnailDataWithSize(const ThumbnailSize(200, 200)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.data != null) {
          cache[asset.id] = snapshot.data!;
          return _imageWidget(snapshot.data!);
        }
        return Container(
          color: Colors.grey[300],
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
    );
  }

  Widget _imageWidget(Uint8List bytes) => ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          bytes,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        ),
      );
}
