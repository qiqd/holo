import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:holo/util/datetime_util.dart';

class MediaGrid extends StatelessWidget {
  final String id;
  final String? imageUrl;
  final String? title;
  final String? rating;
  final Function? onTap;
  final bool showRating;
  final String? airDate;
  final bool showAriTime;
  final bool showCheckBox;
  final bool isChecked;

  const MediaGrid({
    super.key,
    required this.id,
    this.imageUrl,
    this.title,
    this.rating,
    this.showRating = true,
    this.airDate,
    this.onTap,
    this.showAriTime = true,
    this.showCheckBox = false,
    this.isChecked = false,
  });

  @override
  Widget build(BuildContext context) {
    var updatedTo = -1;
    String? updateAt;

    if (airDate?.contains('/') ?? false) {
      updatedTo = checkUpdateAt(airDate!.split('/').first);
      updateAt = airDate!.split('/').last;
    } else if (airDate != null) {
      updatedTo = checkUpdateAt(airDate!);
    }

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
                        child: CachedNetworkImage(
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.fitHeight,
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
                    //评分
                    if ((rating != null || updateAt != null))
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
                              if (rating != null)
                                const Icon(
                                  Icons.star_rounded,
                                  color: Colors.yellow,
                                  size: 14,
                                ),
                              const SizedBox(width: 2),
                              Text(
                                rating ?? updateAt ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
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
                            showAriTime
                                ? (updatedTo > 0
                                      ? '更新至第${updatedTo.toString()}话'
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
                  title == null || title!.isEmpty
                      ? context.tr("component.title")
                      : title!,
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
