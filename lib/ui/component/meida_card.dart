import 'package:flutter/material.dart';
import 'package:holo/util/datetime_util.dart';

class MeidaCard extends StatelessWidget {
  final int id;
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

  const MeidaCard({
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
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap?.call(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: height,
              width: height * 0.7,
              child: Image.network(
                imageUrl ?? '',
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.fill,
                errorBuilder: (context, error, stackTrace) => const SizedBox(
                  height: double.infinity,
                  width: double.infinity,
                  child: Icon(Icons.broken_image),
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(
                    height: double.infinity,
                    width: double.infinity,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 中文名称
                      Text(
                        nameCn,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // 初始名称
                      if (name != null && nameCn.isNotEmpty)
                        Text(
                          name ?? "",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                  //匹配度
                  if (score != 0)
                    Text(
                      "匹配度:${(score * 100).toStringAsFixed(1)}%",
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  // 类型
                  if (genre != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.category_outlined,
                          size: 16,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 5),
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
                    ),
                  // 集数
                  Row(
                    spacing: 5,
                    children: [
                      if (episode != null)
                        const Icon(
                          Icons.info_outline,
                          color: Colors.grey,
                          size: 16,
                        ),
                      Text(
                        episode == 0 ? '待更新' : '共 $episode 集',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  //评分
                  if (rating != null)
                    Row(
                      spacing: 1,
                      children: [
                        const Icon(Icons.star, color: Colors.orange, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          rating!.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  //上映时间
                  if (airDate != null)
                    Row(
                      spacing: 5,
                      children: [
                        const Icon(
                          Icons.date_range,
                          color: Colors.grey,
                          size: 16,
                        ),
                        Text(
                          airDate!,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                  // 历史集数
                  if (historyEpisode != null)
                    Text(
                      '观看至第 ${historyEpisode! + 1} 集',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  if (lastViewAt != null)
                    Text(
                      '上次观看时间: ${formatTimeAgo(lastViewAt!)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
