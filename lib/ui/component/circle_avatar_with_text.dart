import 'package:flutter/material.dart';

class CircleAvatarWithText extends StatelessWidget {
  final String imageUrl;
  final String username;
  final void Function()? onTap;
  const CircleAvatarWithText({
    super.key,
    required this.imageUrl,
    required this.username,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),

      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 30,
            foregroundImage: NetworkImage(imageUrl),
            onForegroundImageError: (_, _) => const Icon(Icons.error),
          ),

          Text(username, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
