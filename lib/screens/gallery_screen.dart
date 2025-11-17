import 'dart:io';
import 'dart:typed_data';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:gallery/screens/album_photos_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gallery/widgets/theme_toggle_button.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({Key? key}) : super(key: key);

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<AssetPathEntity> _albums = [];
  bool _isLoading = true;
  String? _error;
  bool _permissionGranted = false;
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    // Don't call _initializeApp here to avoid Theme.of() error
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitialized) {
      _hasInitialized = true;
      _initializeApp();
    }
  }

  Future<void> _initializeApp() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Request permission first
    final PermissionStatus status = await _requestPermission();
    if (!status.isGranted) {
      setState(() {
        _error =
            'Permission denied. Please allow access to photos in your device settings.';
        _isLoading = false;
        _permissionGranted = false;
      });
      return;
    }

    setState(() {
      _permissionGranted = true;
    });

    // Then fetch albums
    await _fetchAlbums();
  }

  Future<void> _fetchAlbums() async {
    if (!_permissionGranted) {
      await _initializeApp();
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.common,
      );
      setState(() {
        _albums = albums;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load albums: $e';
        _isLoading = false;
      });
    }
  }

  Future<PermissionStatus> _requestPermission() async {
    if (Platform.isIOS) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Albums'),
        actions: [
          
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchAlbums),
          const ThemeToggleButton(),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _errorWidget()
          : _albums.isEmpty
          ? const Center(child: Text('No albums found'))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                ),
                itemCount: _albums.length,
                itemBuilder: (context, index) {
                  final album = _albums[index];
                  return _AlbumCard(
                    album: album,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AlbumPhotosScreen(album: album),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
    );
  }

  Widget _errorWidget() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(_error!, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _fetchAlbums, child: const Text('Retry')),
      ],
    ),
  );
}

class _AlbumCard extends StatelessWidget {
  final AssetPathEntity album;
  final VoidCallback onTap;

  const _AlbumCard({required this.album, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: FutureBuilder<List<AssetEntity>>(
                future: album.getAssetListRange(start: 0, end: 1),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.photo_library,
                          size: 48,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }

                  final asset = snapshot.data!.first;
                  return _AlbumThumbnail(asset: asset);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  FutureBuilder<int>(
                    future: album.assetCountAsync,
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      return Text(
                        '$count ${count == 1 ? 'item' : 'items'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlbumThumbnail extends StatefulWidget {
  final AssetEntity asset;

  const _AlbumThumbnail({required this.asset});

  @override
  State<_AlbumThumbnail> createState() => _AlbumThumbnailState();
}

class _AlbumThumbnailState extends State<_AlbumThumbnail>
    with AutomaticKeepAliveClientMixin {
  Uint8List? _thumbnailData;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    try {
      // Use smaller thumbnail size for faster loading
      final thumbnailData = await widget.asset.thumbnailDataWithSize(
        const ThumbnailSize(200, 200),
      );

      if (mounted) {
        setState(() {
          _thumbnailData = thumbnailData;
          _isLoading = false;
          _hasError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_hasError || _thumbnailData == null) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: const Center(
          child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
        ),
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(12),
        topRight: Radius.circular(12),
      ),
      child: Image.memory(
        _thumbnailData!,
        fit: BoxFit.cover,
        width: double.infinity,
        gaplessPlayback: true,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) {
            return child;
          }
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 200),
            child: child,
          );
        },
      ),
    );
  }
}
