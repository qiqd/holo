import 'package:easy_localization/easy_localization.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';

class MediaGrid extends StatelessWidget {
  final String id;
  final String imageUrl;
  final String title;
  final double? rating;
  final Function? onTap;
  final String? airDate;
  final String? airTime;
  final bool showCheckBox;
  final bool isChecked;
  final int? currentEpisode;

  const MediaGrid({
    super.key,
    required this.id,
    required this.imageUrl,
    required this.title,
    this.rating,
    this.airDate,
    this.airTime,
    this.onTap,
    this.currentEpisode,
    this.showCheckBox = false,
    this.isChecked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        InkWell(
          onTap: () => onTap?.call(), //
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
                        child: ExtendedImage.network(
                          imageUrl.startsWith("https://")
                              ? imageUrl
                              : imageUrl.replaceFirst("http://", "https://"),
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.fitHeight,
                          loadStateChanged: (state) {
                            if (state.extendedImageLoadState ==
                                LoadState.loading) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            } else if (state.extendedImageLoadState ==
                                LoadState.completed) {
                              return null;
                            } else if (state.extendedImageLoadState ==
                                LoadState.failed) {
                              return const Center(child: Icon(Icons.error));
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    //评分
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
                                Icons.star_rounded,
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
                    //更新时间
                    if (airTime != null)
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
                          child: Text(
                            airTime!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    //放送时间
                    if (airDate != null)
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            currentEpisode != null
                                ? (currentEpisode! > 0
                                      ? '更新至第${currentEpisode.toString()}话'
                                      : '暂未更新')
                                : airDate ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(
                child: Text(
                  title.isEmpty ? context.tr("component.title") : title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),

        // 选中图标
        AnimatedPositioned(
          duration: const Duration(milliseconds: 100),
          top: showCheckBox ? 0 : -60,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Checkbox(value: isChecked, onChanged: (_) => onTap?.call()),
          ),
        ),
      ],
    );
  }
}
