import 'dart:io';

import 'package:flutter/material.dart';

/// Full-screen image viewer with pinch-to-zoom for message images.
class MessageImageViewer extends StatelessWidget {
  final String? imageUrl;
  final String? localPath;

  const MessageImageViewer({
    super.key,
    this.imageUrl,
    this.localPath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Semantics(
        label: 'Full screen image. Pinch to zoom.',
        child: InteractiveViewer(
          minScale: 1.0,
          maxScale: 4.0,
          child: Center(
            child: _buildImage(),
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (localPath != null) {
      return Image.file(
        File(localPath!),
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildError(),
      );
    }
    if (imageUrl != null) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.contain,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        },
        errorBuilder: (_, __, ___) => _buildError(),
      );
    }
    return _buildError();
  }

  Widget _buildError() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.broken_image_outlined,
          size: 48,
          color: Colors.white54,
        ),
        SizedBox(height: 8),
        Text(
          'Failed to load image',
          style: TextStyle(color: Colors.white54),
        ),
      ],
    );
  }
}
