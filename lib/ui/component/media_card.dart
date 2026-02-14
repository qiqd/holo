import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:holo/util/datetime_util.dart';
import 'package:shimmer/shimmer.dart';

/// 媒体卡片
class MediaCard extends StatelessWidget {
  final String id;
  final String title;
  final String? genre;
  final int? episode;
  final int? historyEpisode;
  final DateTime? lastViewAt;
  final String? airDate;
  final String? imageUrl;
  final double? rating;
  final int? rank;
  final int? ratingCount;
  final double height;
  final double score;
  final bool isFavorite;
  final Function? onTap;
  final bool showShimmer;
  final bool isChecked;
  final bool showCheckbox;

  /// 观看状态 0:无状态 1:想看 2:看过 3:在看
  final int? viewingStatus;
  final void Function(int status)? onViewingStatusChange;
  const MediaCard({
    super.key,
    required this.id,
    required this.title,
    required this.imageUrl,
    this.historyEpisode,
    this.lastViewAt,
    this.genre,
    this.episode,
    this.airDate,
    this.rating,
    this.rank,
    this.ratingCount,
    this.score = 0,
    this.height = 200,
    this.onTap,

    this.isFavorite = false,

    this.showShimmer = false,
    this.showCheckbox = false,
    this.isChecked = false,
    this.viewingStatus,

    this.onViewingStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    var updateTo = checkUpdateAt(airDate);
    return Stack(
      children: [
        InkWell(
          onTap: () => onTap?.call(),
          child: SizedBox(
            width: double.infinity,
            height: height,
            child: Row(
              spacing: 6,
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
                  child: Column(
                    mainAxisSize: .max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 3,
                    children: [
                      // 标题
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
                              title.isNotEmpty
                                  ? title
                                  : context.tr("component.title"),
                              style: Theme.of(context).textTheme.titleMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),

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
                                    maxLines: 1,
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
                                        : '${updateTo > 0
                                              ? updateTo <= (episode ?? 0)
                                                    ? '更新至$updateTo话'
                                                    : '已完结'
                                              : ''}/${context.tr("component.media_card.total_episode", args: [episode.toString()])}',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
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
                      Spacer(),
                      // 播放状态
                      Align(
                        alignment: Alignment.bottomRight,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: isFavorite
                              ? SegmentedButton(
                                  emptySelectionAllowed: true,
                                  showSelectedIcon: false,
                                  style: ButtonStyle(
                                    padding: WidgetStatePropertyAll(.zero),
                                  ),
                                  segments: [
                                    ButtonSegment(value: 1, label: Text('想看')),
                                    ButtonSegment(value: 3, label: Text('在看')),
                                    ButtonSegment(value: 2, label: Text('看过')),
                                  ],
                                  selected: {viewingStatus ?? 0},
                                  onSelectionChanged: (Set<int> values) {
                                    if (values.isNotEmpty) {
                                      onViewingStatusChange?.call(values.first);
                                    }
                                  },
                                )
                              : SizedBox.shrink(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // 选中图标
        AnimatedPositioned(
          duration: const Duration(milliseconds: 100),
          top: showCheckbox ? 8 : -40,
          right: 8,
          child: Checkbox(value: isChecked, onChanged: (_) => onTap?.call()),
        ),
        // 评分
        if (rating != null && ratingCount != null)
          AnimatedPositioned(
            right: 0,
            bottom: isFavorite ? 50 : 0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Column(
              children: [
                Text(
                  rating!.toStringAsFixed(1),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 20,
                  ),
                ),
                Text(
                  context.tr(
                    "component.media_card.rating_count",
                    args: [ratingCount!.toString()],
                  ),
                ),
              ],
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
