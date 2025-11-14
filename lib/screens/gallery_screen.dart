import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'auth_screen.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<String> _imageUrls = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadSampleImages();
  }

  void _loadSampleImages() {
    setState(() => _loading = true);

    // Sample image URLs for demonstration
    _imageUrls = [
      'https://picsum.photos/400/300?random=1',
      'https://picsum.photos/400/500?random=2',
      'https://picsum.photos/400/400?random=3',
      'https://picsum.photos/400/600?random=4',
      'https://picsum.photos/400/350?random=5',
      'https://picsum.photos/400/450?random=6',
      'https://picsum.photos/400/380?random=7',
      'https://picsum.photos/400/520?random=8',
      'https://picsum.photos/400/320?random=9',
      'https://picsum.photos/400/480?random=10',
      'https://picsum.photos/400/360?random=11',
      'https://picsum.photos/400/440?random=12',
    ];

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Gallery - ${user?.email ?? 'User'}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSampleImages,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _imageUrls.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.photo_library, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No images found',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadSampleImages,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Load Sample Images'),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(4.0),
              child: MasonryGridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                itemCount: _imageUrls.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _showImageDialog(_imageUrls[index]),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: _imageUrls[index],
                        placeholder: (_, __) => Container(
                          height: 200 + (index % 3) * 50,
                          color: Colors.grey[300],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          height: 200,
                          color: Colors.grey[300],
                          child: const Icon(Icons.error, size: 48),
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Image Preview'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Flexible(
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                placeholder: (_, __) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (_, __, ___) =>
                    const Center(child: Icon(Icons.error, size: 48)),
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
