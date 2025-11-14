
// import 'dart:typed_data';

// import 'package:flutter/material.dart';
// import 'package:photo_manager/photo_manager.dart';
// import 'package:permission_handler/permission_handler.dart';

// class GalleryScreen extends StatefulWidget {
//   @override
//   _GalleryScreenState createState() => _GalleryScreenState();
// }

// class _GalleryScreenState extends State<GalleryScreen> {
//   List<AssetEntity> _media = [];

//   @override
//   void initState() {
//     super.initState();
//     _fetchMedia();
//   }

//   _fetchMedia() async {
//     var status = await Permission.storage.request();
//     if (status.isGranted) {
//       final albums = await PhotoManager.getAssetPathList(
//         type: RequestType.common,
//       );
//       final recentAlbum = albums.first;
//       final recentAssets = await recentAlbum.getAssetListRange(
//         start: 0,
//         end: 1000,
//       );
//       setState(() => _media = recentAssets);
//     } else {
//       // Handle permission denied
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Gallery'),
//       ),
//       body: _media.isEmpty
//           ? Center(child: CircularProgressIndicator())
//           : GridView.builder(
//               gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                 crossAxisCount: 3,
//                 crossAxisSpacing: 4.0,
//                 mainAxisSpacing: 4.0,
//               ),
//               itemCount: _media.length,
//               itemBuilder: (context, index) {
//                 return FutureBuilder<Uint8List?>(
//                   future: _media[index].thumbnailData,
//                   builder: (context, snapshot) {
//                     if (snapshot.connectionState == ConnectionState.done &&
//                         snapshot.data != null) {
//                       return Image.memory(
//                         snapshot.data!,
//                         fit: BoxFit.cover,
//                       );
//                     }
//                     return Center(child: CircularProgressIndicator());
//                   },
//                 );
//               },
//             ),
//     );
//   }
// }
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

  @override
  void initState() {
    super.initState();
    _fetchMedia();
  }

  Future<void> _fetchMedia() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Request permission using modern APIs
    final PermissionStatus status = await _requestPermission();
    if (!status.isGranted) {
      setState(() {
        _error = 'Permission denied. Please allow access to photos.';
        _isLoading = false;
      });
      return;
    }

    try {
      // Get all albums (galleries)
      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.common, // images + videos
        // onlyAll: true, // uncomment to get only "Recent" album
      );

      if (albums.isEmpty) {
        setState(() {
          _error = 'No albums found.';
          _isLoading = false;
        });
        return;
      }

      // Use the first album (usually "Recent" or "All")
      final AssetPathEntity recentAlbum = albums.first;

      // Fetch up to 1000 recent media
      final List<AssetEntity> assets = await recentAlbum.getAssetListRange(
        start: 0,
        end: 1000,
      );

      setState(() {
        _media = assets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load media: $e';
        _isLoading = false;
      });
    }
  }

  // Future<PermissionStatus> _requestPermission() async {
  //   // iOS: Use .photos
  //   // Android: Use .photos (Android 13+), fallback to .storage (older)
  //   if (Theme.of(context).platform == TargetPlatform.iOS) {
  //     return await Permission.photos.request();
  //   } else {
  //     // Android 13+ (API 33+)
  //     final isAndroid13OrHigher = Platform.isAndroid && (await PhotoManager.getAndroidSdkVersion()) >= 33;
  //     if (isAndroid13OrHigher) {
  //       return await Permission.photos.request();
  //     } else {
  //       // Android 12 and below
  //       return await Permission.storage.request();
  //     }
  //   }
  // }
 // <-- ADD THIS

Future<PermissionStatus> _requestPermission() async {
  // iOS
  if (Theme.of(context).platform == TargetPlatform.iOS) {
    return await Permission.photos.request();
  }

  // Android
  if (!Platform.isAndroid) {
    return await Permission.photos.request();
  }

  try {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    final int sdkInt = androidInfo.version.sdkInt;

    if (sdkInt >= 33) {
      return await Permission.photos.request();
    } else {
      return await Permission.storage.request();
    }
  } catch (e) {
    // Fallback: assume older Android
    return await Permission.storage.request();
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchMedia,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchMedia,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _media.isEmpty
                  ? const Center(child: Text('No media found'))
                  : GridView.builder(
                      padding: const EdgeInsets.all(4),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 4.0,
                        mainAxisSpacing: 4.0,
                      ),
                      itemCount: _media.length,
                      itemBuilder: (context, index) {
                        final asset = _media[index];
                        return GestureDetector(
                          onTap: () {
                            // Optional: Open full image
                            _showFullImage(asset);
                          },
                          child: FutureBuilder<Uint8List?>(
                            future: asset.thumbnailDataWithSize(
                              const ThumbnailSize(200, 200),
                            ),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                      ConnectionState.done &&
                                  snapshot.data != null) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(
                                    snapshot.data!,
                                    fit: BoxFit.cover,
                                    gaplessPlayback: true,
                                  ),
                                );
                              }
                              return Container(
                                color: Colors.grey[300],
                                child: const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
    );
  }

  void _showFullImage(AssetEntity asset) async {
    final Uint8List? data = await asset.originBytes;
    if (data == null || !mounted) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Image.memory(data, fit: BoxFit.contain),
      ),
    );
  }
}