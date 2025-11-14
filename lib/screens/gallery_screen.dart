
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';

class GalleryScreen extends StatefulWidget {
  @override
  _GalleryScreenState createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<AssetEntity> _media = [];

  @override
  void initState() {
    super.initState();
    _fetchMedia();
  }

  _fetchMedia() async {
    var status = await Permission.storage.request();
    if (status.isGranted) {
      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.common,
      );
      final recentAlbum = albums.first;
      final recentAssets = await recentAlbum.getAssetListRange(
        start: 0,
        end: 1000,
      );
      setState(() => _media = recentAssets);
    } else {
      // Handle permission denied
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gallery'),
      ),
      body: _media.isEmpty
          ? Center(child: CircularProgressIndicator())
          : GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4.0,
                mainAxisSpacing: 4.0,
              ),
              itemCount: _media.length,
              itemBuilder: (context, index) {
                return FutureBuilder<Uint8List?>(
                  future: _media[index].thumbnailData,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done &&
                        snapshot.data != null) {
                      return Image.memory(
                        snapshot.data!,
                        fit: BoxFit.cover,
                      );
                    }
                    return Center(child: CircularProgressIndicator());
                  },
                );
              },
            ),
    );
  }
}
