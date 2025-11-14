import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_editor_plus/image_editor_plus.dart';
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
            onPressed: () async {
              final editedImage = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ImageEditor(
                    image: (await widget.photo.originBytes)!,
                  ),
                ),
              );
              if (editedImage != null) {
                await PhotoManager.editor.saveImage(editedImage);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Photo saved')),
                  );
                }
              }
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
