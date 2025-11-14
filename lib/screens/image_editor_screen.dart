import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_editor_plus/image_editor_plus.dart';
import 'package:photo_manager/photo_manager.dart';

class ImageEditorScreen extends StatefulWidget {
  final AssetEntity photo;

  const ImageEditorScreen({required this.photo, Key? key}) : super(key: key);

  @override
  State<ImageEditorScreen> createState() => _ImageEditorScreenState();
}

class _ImageEditorScreenState extends State<ImageEditorScreen> {
  Uint8List? _imageData;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final bytes = await widget.photo.originBytes;
    if (bytes != null && mounted) {
      setState(() {
        _imageData = bytes;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Photo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () async {
              // TODO: Save image
            },
          ),
        ],
      ),
      body: _imageData == null
          ? const Center(child: CircularProgressIndicator())
          : ImageEditor(
              image: _imageData!,
            ),
    );
  }
}
