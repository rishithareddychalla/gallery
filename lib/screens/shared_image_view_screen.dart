import 'dart:io';

import 'package:flutter/material.dart';

class SharedImageViewScreen extends StatelessWidget {
  final String imagePath;

  const SharedImageViewScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shared Image'),
      ),
      body: Center(
        child: Image.file(File(imagePath)),
      ),
    );
  }
}
