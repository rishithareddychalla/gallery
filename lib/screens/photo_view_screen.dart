import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:gallery/screens/image_editor_screen.dart';
import 'package:photo_manager/photo_manager.dart';

class PhotoViewScreen extends StatefulWidget {
  final AssetEntity photo;

  const PhotoViewScreen({required this.photo, Key? key}) : super(key: key);

  @override
  State<PhotoViewScreen> createState() => _PhotoViewScreenState();
}

class _PhotoViewScreenState extends State<PhotoViewScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ImageEditorScreen(photo: widget.photo),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: FutureBuilder<Uint8List?>(
          future: widget.photo.originBytes,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.data != null) {
              return Image.memory(
                snapshot.data!,
                fit: BoxFit.contain,
              );
            }
            return const CircularProgressIndicator();
          },
        ),
      ),
    );
  }
}
