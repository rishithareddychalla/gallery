import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_editor_plus/image_editor_plus.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class PhotoViewScreen extends StatefulWidget {
  final AssetEntity photo;
  const PhotoViewScreen({required this.photo, Key? key}) : super(key: key);

  @override
  State<PhotoViewScreen> createState() => _PhotoViewScreenState();
}

class _PhotoViewScreenState extends State<PhotoViewScreen> {
  Uint8List? _currentImageData;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final bytes = await widget.photo.originBytes;
    if (mounted && bytes != null) {
      setState(() {
        _currentImageData = bytes;
      });
    }
  }

  Future<void> _shareImage() async {
    if (_currentImageData == null) return;

    try {
      final tempDir = await getTemporaryDirectory();
      final tempFile =
          await File('${tempDir.path}/share_image.jpg').create();
      await tempFile.writeAsBytes(_currentImageData!);

      await Share.shareXFiles([XFile(tempFile.path)]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share failed: $e')),
        );
      }
    }
  }

  Future<void> _editImage() async {
    if (_currentImageData == null) return;

    try {
      final tempDir = await getTemporaryDirectory();
      final editedBytes = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ImageEditor(image: _currentImageData!, savePath: tempDir.path),
        ),
      );

      if (editedBytes is Uint8List && mounted) {
        setState(() {
          _currentImageData = editedBytes;
        });

        await _saveEditedImage(editedBytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Edit failed: $e')));
      }
    }
  }

  Future<void> _saveEditedImage(Uint8List imageData) async {
    try {
      final fileName = 'edited_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final result = await PhotoManager.editor.saveImage(
        imageData,
        title: fileName,
        filename: fileName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo saved to gallery!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _currentImageData != null ? _editImage : null,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _currentImageData != null ? _shareImage : null,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _currentImageData != null
                ? () => _saveEditedImage(_currentImageData!)
                : null,
          ),
        ],
      ),
      body: Center(
        child: _currentImageData != null
            ? InteractiveViewer(
                child: Image.memory(_currentImageData!, fit: BoxFit.contain),
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}
