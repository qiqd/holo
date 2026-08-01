import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerGridSkeleton extends StatelessWidget {
  final bool isSliver;
  final bool isLandscape;

  const ShimmerGridSkeleton({
    super.key,
    required this.isSliver,
    required this.isLandscape,
  });
  @override
  Widget build(BuildContext context) {
    final gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: isLandscape ? 6 : 3,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      childAspectRatio: 0.6,
    );
    return isSliver
        ? SliverGrid.builder(
            gridDelegate: gridDelegate,
            itemBuilder: (context, index) => const ShimmerContainerSkeleton(),
          )
        : GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: gridDelegate,
            itemBuilder: (context, index) {
              return const ShimmerContainerSkeleton();
            },
          );
  }
}

class ShimmerContainerSkeleton extends StatelessWidget {
  const ShimmerContainerSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white38,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
