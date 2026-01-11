import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class MediaGrid extends StatelessWidget {
  final String id;
  final String? imageUrl;
  final String? title;
  final double? rating;
  final Function? onTap;
  final bool showRating;
  final String? airDate;
  final bool showDeleteIcon;

  final Function(int)? onDelete;
  final Function(bool)? onLongPress;

  const MediaGrid({
    super.key,
    required this.id,
    this.imageUrl,
    this.title,
    this.rating = 0,
    this.showRating = true,
    this.airDate,
    this.onTap,
    this.showDeleteIcon = false,

    this.onDelete,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        InkWell(
          onLongPress: () => onLongPress?.call(true),
          onTap: showDeleteIcon ? null : () => onTap?.call(), //
          borderRadius: BorderRadius.circular(10),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Hero(
                      tag: id,
                      child: ClipRRect(
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
                          errorWidget: (context, url, error) =>
                              Icon(Icons.error),
                        ),
                      ),
                    ),

                    if (rating != null && showRating && !showDeleteIcon)
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
                    // if (airDate != null)
                    //   Positioned(
                    //     left: 4,
                    //     bottom: 4,
                    //     child: Container(
                    //       padding: const EdgeInsets.symmetric(
                    //         horizontal: 6,
                    //         vertical: 2,
                    //       ),
                    //       decoration: BoxDecoration(
                    //         color: Colors.black54,
                    //         borderRadius: BorderRadius.circular(12),
                    //       ),
                    //       child: Text(
                    //         airDate!,
                    //         style: const TextStyle(
                    //           color: Colors.white,
                    //           fontSize: 12,
                    //         ),
                    //       ),
                    //     ),
                    //   ),
                  ],
                ),
              ),
              SizedBox(
                child: Text(
                  title ?? context.tr("component.title"),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),

        // 删除图标
        AnimatedPositioned(
          duration: const Duration(milliseconds: 100),
          top: showDeleteIcon ? 8 : -30,
          right: 8,
          child: GestureDetector(
            onTap: () =>
                onDelete?.call(int.parse(id.split('_').last)), // 调用删除回调
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }
}
