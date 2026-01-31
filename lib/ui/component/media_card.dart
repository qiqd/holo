import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class MediaCard extends StatelessWidget {
  final String id;
  final String? name;
  final String nameCn;
  final String? genre;
  final int? episode;
  final int? historyEpisode;
  final DateTime? lastViewAt;
  final String? airDate;
  final String? imageUrl;
  final double? rating;
  final double height;
  final double score;
  final Function? onTap;
  final Function(int)? onDelete;
  final bool showDeleteIcon;
  final bool showShimmer;

  final Function(bool)? onLongPress;

  const MediaCard({
    super.key,
    required this.id,
    required this.imageUrl,
    required this.nameCn,
    this.historyEpisode,
    this.lastViewAt,
    this.name,
    this.genre,
    this.episode,
    this.airDate,
    this.rating,
    this.score = 0,
    this.height = 200,
    this.onTap,
    this.onDelete,
    this.showDeleteIcon = false,
    this.showShimmer = false,

    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        InkWell(
          onLongPress: () => onLongPress?.call(true),
          onTap: showDeleteIcon ? null : () => onTap?.call(),
          child: SizedBox(
            width: double.infinity,
            height: height,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: id,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      height: height,
                      width: height * 0.7,
                      child: CachedNetworkImage(
                        useOldImageOnUrlChange: true,
                        imageUrl: imageUrl!.contains('http')
                            ? imageUrl!
                            : 'https://$imageUrl',
                        memCacheHeight: 1000,
                        memCacheWidth: 800,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.fitHeight,

                        errorWidget: (context, url, error) {
                          log("meida_card.image_url:$url");
                          log("meida_card.image_error:$error");
                          return SizedBox(
                            height: double.infinity,
                            width: double.infinity,
                            child: Icon(Icons.broken_image),
                          );
                        },
                        placeholder: (context, url) => const SizedBox(
                          height: double.infinity,
                          width: double.infinity,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 3,
                        children: [
                          // 中文名称
                          showShimmer
                              ? Shimmer.fromColors(
                                  baseColor: Colors.grey.shade300,
                                  highlightColor: Colors.grey.shade100,
                                  child: Container(
                                    height: 20,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.white38,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                )
                              : Text(
                                  nameCn.isEmpty
                                      ? context.tr("component.title")
                                      : nameCn,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                  maxLines: 5,
                                  overflow: TextOverflow.ellipsis,
                                ),

                          // 初始名称
                          showShimmer
                              ? Shimmer.fromColors(
                                  baseColor: Colors.grey.shade300,
                                  highlightColor: Colors.grey.shade100,
                                  child: Container(
                                    height: 20,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.white38,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                )
                              : (name != null && nameCn.isNotEmpty)
                              ? Text(
                                  name ?? "",
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                  maxLines: 5,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : SizedBox.shrink(),

                          // 匹配度
                          showShimmer
                              ? Shimmer.fromColors(
                                  baseColor: Colors.grey.shade300,
                                  highlightColor: Colors.grey.shade100,
                                  child: Container(
                                    height: 20,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.white38,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                )
                              : (score != 0)
                              ? Text(
                                  "${context.tr("component.media_card.score")}:${(score * 100).toStringAsFixed(1)}%",
                                  style: const TextStyle(
                                    color: Colors.orange,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : SizedBox.shrink(),
                          // 类型
                          showShimmer
                              ? Shimmer.fromColors(
                                  baseColor: Colors.grey.shade300,
                                  highlightColor: Colors.grey.shade100,
                                  child: Container(
                                    height: 20,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.white38,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                )
                              : (genre != null)
                              ? Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        genre!,
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          fontSize: 12,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                )
                              : SizedBox.shrink(),
                          // 集数
                          showShimmer
                              ? Shimmer.fromColors(
                                  baseColor: Colors.grey.shade300,
                                  highlightColor: Colors.grey.shade100,
                                  child: Container(
                                    height: 20,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.white38,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                )
                              : (episode != null)
                              ? Row(
                                  spacing: 5,
                                  children: [
                                    const Icon(
                                      Icons.info_outline,
                                      color: Colors.grey,
                                      size: 16,
                                    ),
                                    Expanded(
                                      child: Text(
                                        episode == 0
                                            ? context.tr(
                                                "component.media_card.status",
                                              )
                                            : context.tr(
                                                "component.media_card.total_episode",
                                                args: [episode.toString()],
                                              ),
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : SizedBox.shrink(),
                          //评分
                          showShimmer
                              ? Shimmer.fromColors(
                                  baseColor: Colors.grey.shade300,
                                  highlightColor: Colors.grey.shade100,
                                  child: Container(
                                    height: 20,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.white38,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                )
                              : (rating != null)
                              ? Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: Colors.orange,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      rating!.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                )
                              : SizedBox.shrink(),
                          //上映时间
                          showShimmer
                              ? Shimmer.fromColors(
                                  baseColor: Colors.grey.shade300,
                                  highlightColor: Colors.grey.shade100,
                                  child: Container(
                                    height: 20,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.white38,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                )
                              : (airDate != null)
                              ? Row(
                                  spacing: 5,
                                  children: [
                                    const Icon(
                                      Icons.date_range,
                                      color: Colors.grey,
                                      size: 16,
                                    ),
                                    Expanded(
                                      child: Text(
                                        airDate!,
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : SizedBox.shrink(),

                          // 历史集数
                          if (historyEpisode != null)
                            Text(
                              context.tr(
                                "component.media_card.lastviewAtEpisode",
                                args: [(historyEpisode! + 1).toString()],
                              ),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          if (lastViewAt != null)
                            Text(
                              context.tr(
                                "component.media_card.lastviewAtTime",
                                args: [formatTimeAgo(lastViewAt!, context)],
                              ),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
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

  String formatTimeAgo(DateTime dateTime, BuildContext context) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return context.tr(
        "component.media_card.days_ago",
        args: [difference.inDays.toString()],
      );
    } else if (difference.inHours > 0) {
      return context.tr(
        "component.media_card.hours_ago",
        args: [difference.inHours.toString()],
      );
    } else if (difference.inMinutes > 0) {
      return context.tr(
        "component.media_card.minutes_ago",
        args: [difference.inMinutes.toString()],
      );
    } else {
      return context.tr("component.media_card.just_now");
    }
  }
}
