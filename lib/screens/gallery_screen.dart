

import 'dart:io';
import 'dart:typed_data';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({Key? key}) : super(key: key);

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<AssetEntity> _media = [];
  bool _isLoading = true;
  String? _error;

  // ---------- CACHING ----------
  // thumbnail cache: asset.id → Uint8List
  final Map<String, Uint8List> _thumbCache = {};
  // full-image cache: asset.id → Uint8List
  final Map<String, Uint8List> _fullCache = {};

  @override
  void initState() {
    super.initState();
    _fetchMedia();
  }

  Future<void> _fetchMedia() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _thumbCache.clear();
      _fullCache.clear();
    });

    final PermissionStatus status = await _requestPermission();
    if (!status.isGranted) {
      setState(() {
        _error = 'Permission denied. Please allow access to photos.';
        _isLoading = false;
      });
      return;
    }

    try {
      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.common,
      );

      if (albums.isEmpty) {
        setState(() {
          _error = 'No albums found.';
          _isLoading = false;
        });
        return;
      }

      final AssetPathEntity recentAlbum = albums.first;
      final List<AssetEntity> assets = await recentAlbum.getAssetListRange(
        start: 0,
        end: 1000,
      );

      setState(() {
        _media = assets;
        _isLoading = false;
      });

      // Pre-load thumbnails **off the UI thread** (optional but nice)
      _preCacheThumbnails(assets);
    } catch (e) {
      setState(() {
        _error = 'Failed to load media: $e';
        _isLoading = false;
      });
    }
  }

  // -------------------------------------------------
  // 1. PRE-CACHE ALL THUMBNAILS (runs in background)
  // -------------------------------------------------
  Future<void> _preCacheThumbnails(List<AssetEntity> assets) async {
    for (final asset in assets) {
      if (_thumbCache.containsKey(asset.id)) continue;
      final bytes = await asset.thumbnailDataWithSize(
        const ThumbnailSize(200, 200),
      );
      if (bytes != null && mounted) {
        _thumbCache[asset.id] = bytes;
      }
    }
    if (mounted) setState(() {}); // refresh once all are cached
  }

  // -------------------------------------------------
  // 2. PERMISSION (unchanged, just moved out)
  // -------------------------------------------------
  Future<PermissionStatus> _requestPermission() async {
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      return await Permission.photos.request();
    }

    if (!Platform.isAndroid) return await Permission.photos.request();

    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      return sdkInt >= 33
          ? await Permission.photos.request()
          : await Permission.storage.request();
    } catch (_) {
      return await Permission.storage.request();
    }
  }

  // -------------------------------------------------
  // 3. BUILD
  // -------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchMedia),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _errorWidget()
              : _media.isEmpty
                  ? const Center(child: Text('No media found'))
                  : GridView.builder(
                      padding: const EdgeInsets.all(4),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                      ),
                      itemCount: _media.length,
                      itemBuilder: (context, index) {
                        final asset = _media[index];
                        return GestureDetector(
                          onTap: () => _showFullImage(asset),
                          child: _ThumbTile(
                            asset: asset,
                            cache: _thumbCache,
                          ),
                        );
                      },
                    ),
    );
  }

  // -------------------------------------------------
  // 4. FULL-IMAGE DIALOG (caches the full bytes)
  // -------------------------------------------------
  Future<void> _showFullImage(AssetEntity asset) async {
    Uint8List? data = _fullCache[asset.id];

    if (data == null) {
      data = await asset.originBytes;
      if (data != null && mounted) {
        _fullCache[asset.id] = data;
      } else {
        return;
      }
    }

    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Image.memory(data!, fit: BoxFit.contain),
      ),
    );
  }

  // -------------------------------------------------
  // 5. ERROR UI
  // -------------------------------------------------
  Widget _errorWidget() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _fetchMedia, child: const Text('Retry')),
          ],
        ),
      );
}

// -----------------------------------------------------------------
// 6. SEPARATE TILE WIDGET – isolates the FutureBuilder logic
// -----------------------------------------------------------------
class _ThumbTile extends StatelessWidget {
  final AssetEntity asset;
  final Map<String, Uint8List> cache;

  const _ThumbTile({required this.asset, required this.cache});

  @override
  Widget build(BuildContext context) {
    // 1. Already in memory → instant
    if (cache.containsKey(asset.id)) {
      return _imageWidget(cache[asset.id]!);
    }

    // 2. Load once and store in cache
    return FutureBuilder<Uint8List?>(
      future: asset.thumbnailDataWithSize(const ThumbnailSize(200, 200)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.data != null) {
          // cache for later scrolls
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