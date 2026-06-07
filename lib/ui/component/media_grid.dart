import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:holo/ui/component/cache_image.dart';

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
  final int? latestEpisode;

  /// 观看状态 0:无状态 1:想看 2:看过 3:在看
  final int? status;
  const MediaGrid({
    super.key,
    required this.id,
    required this.imageUrl,
    required this.title,
    this.rating,
    this.airDate,
    this.airTime,
    this.latestEpisode,
    this.showCheckBox = false,
    this.isChecked = false,
    this.onTap,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        InkWell(
          onTap: () => onTap?.call(), //
          borderRadius: BorderRadius.circular(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Hero(
                      tag: id,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: RepaintBoundary(
                          child: CacheImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.fitHeight,
                          ),
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
                    //最新话/放送日期
                    if (latestEpisode != null || airDate != null)
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
                            airDate != null
                                ? airDate!
                                : (latestEpisode! > 0
                                      ? tr(
                                          "component.media_card.current_episode",
                                          args: [latestEpisode.toString()],
                                        )
                                      : tr("component.media_card.status")),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),

                    ///
                    ///Tab(text: tr("subscribe.tab_subs_wish")),
                    // Tab(text: tr("subscribe.tab_subs_watched")),
                    //Tab(text: tr("subscribe.tab_subs_watching")),
                    ///
                    ///
                    //观看状态
                    if (status != null && status != 0)
                      Positioned(
                        left: 4,
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
                            status == 1
                                ? tr("subscribe.tab_subs_wish")
                                : (status == 2
                                      ? tr("subscribe.tab_subs_watched")
                                      : (status == 3
                                            ? tr("subscribe.tab_subs_watching")
                                            : "")),
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
