import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerGridSkeleton extends StatelessWidget {
  const ShimmerGridSkeleton({super.key});
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = constraints.maxWidth > constraints.maxHeight;
        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isLandscape ? 6 : 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.6,
          ),
          itemBuilder: (context, index) {
            return const ShimmerContainerSkeleton();
          },
        );
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
