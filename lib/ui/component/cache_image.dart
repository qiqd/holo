import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:holo/ui/component/shimmer.dart';

class CacheImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final int memCacheHeight;
  final int memCacheWidth;

  const CacheImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.fitWidth,
    this.memCacheHeight = 400,
    this.memCacheWidth = 300,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl.startsWith('https://')
          ? imageUrl
          : imageUrl.replaceFirst('http://', 'https://'),
      width: double.infinity,
      height: double.infinity,
      memCacheHeight: memCacheHeight,
      memCacheWidth: memCacheWidth,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return const Center(child: Icon(Icons.error));
      },
      placeholder: (context, url) => ShimmerContainerSkeleton(),
      placeholderFadeInDuration: const Duration(milliseconds: 300),
      fadeInDuration: const Duration(milliseconds: 100),
      fadeOutDuration: const Duration(milliseconds: 100),
    );
  }
}
