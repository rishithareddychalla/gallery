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
          : ListView.builder(
              itemCount: _albums.length,
              itemBuilder: (context, index) {
                final album = _albums[index];
                return _AlbumTile(
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

class _AlbumTile extends StatelessWidget {
  final AssetPathEntity album;
  final VoidCallback onTap;

  const _AlbumTile({required this.album, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AssetEntity>>(
      future: album.getAssetListRange(start: 0, end: 1),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData &&
            snapshot.data!.isNotEmpty) {
          final asset = snapshot.data!.first;
          return ListTile(
            leading: FutureBuilder<Uint8List?>(
              future: asset.thumbnailDataWithSize(const ThumbnailSize(80, 80)),
              builder: (context, thumbSnapshot) {
                if (thumbSnapshot.connectionState == ConnectionState.done &&
                    thumbSnapshot.data != null) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      thumbSnapshot.data!,
                      fit: BoxFit.cover,
                      width: 80,
                      height: 80,
                      gaplessPlayback: true,
                    ),
                  );
                }
                return Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[300],
                );
              },
            ),
            title: Text(album.name),
            subtitle: FutureBuilder<int>(
              future: album.assetCountAsync,
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                return Text('$count items');
              },
            ),
            onTap: onTap,
          );
        }
        return ListTile(
          leading: Container(width: 80, height: 80, color: Colors.grey[300]),
          title: Text(album.name),
          subtitle: FutureBuilder<int>(
            future: album.assetCountAsync,
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return Text('$count items');
            },
          ),
        );
      },
    );
  }
}
