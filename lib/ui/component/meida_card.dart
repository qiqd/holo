import 'package:flutter/material.dart';

class MeidaCard extends StatelessWidget {
  final int id;
  final String? name;
  final String nameCn;
  final String? genre;
  final int? episode;
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
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
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
                    Text(
                      genre!,
                      style: const TextStyle(color: Colors.blue, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (episode != null)
                        Text(
                          '共 $episode 集',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      if (airDate != null)
                        Text(
                          airDate!,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  if (rating != null)
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.orange, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          rating!.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
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
