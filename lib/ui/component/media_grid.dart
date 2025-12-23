import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class MediaGrid extends StatelessWidget {
  final int id;
  final String? imageUrl;
  final String? title;
  final double? rating;
  final Function? onTap;
  const MediaGrid({
    super.key,
    required this.id,
    this.imageUrl,
    this.title,
    this.rating = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => onTap?.call(),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    memCacheHeight: 1000,
                    memCacheWidth: 800,
                    imageUrl: imageUrl!,
                    placeholder: (context, url) =>
                        Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => Icon(Icons.error),
                  ),
                ),
                if (rating != null)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.yellow,
                            size: 14,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            rating!.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            title ?? '暂无标题',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
