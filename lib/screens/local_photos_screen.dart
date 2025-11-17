import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:gallery/screens/cloud_photos_screen.dart';
import 'package:photo_manager/photo_manager.dart';

class LocalPhotosScreen extends StatefulWidget {
  const LocalPhotosScreen({super.key});

  @override
  State<LocalPhotosScreen> createState() => _LocalPhotosScreenState();
}

class _LocalPhotosScreenState extends State<LocalPhotosScreen> {
  List<AssetEntity> _photos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPhotos();
  }

  Future<void> _fetchPhotos() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (ps.isAuth) {
      final List<AssetPathEntity> albums =
          await PhotoManager.getAssetPathList(onlyAll: true);
      if (albums.isNotEmpty) {
        final List<AssetEntity> photos =
            await albums.first.getAssetListPaged(page: 0, size: 100);
        setState(() {
          _photos = photos;
          _isLoading = false;
        });
      }
    } else {
      // Handle permission denial
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Photos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CloudPhotosScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4.0,
                mainAxisSpacing: 4.0,
              ),
              itemCount: _photos.length,
              itemBuilder: (context, index) {
                return FutureBuilder<Uint8List?>(
                  future: _photos[index].thumbnailData,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done &&
                        snapshot.data != null) {
                      return Image.memory(snapshot.data!, fit: BoxFit.cover);
                    }
                    return const Center(child: CircularProgressIndicator());
                  },
                );
              },
            ),
    );
  }
}
