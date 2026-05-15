import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

class ShimmerPrayerLoader extends StatelessWidget {
  const ShimmerPrayerLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: Column(
        children: [
          // Hero card placeholder
          Container(
            height: 180,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          // List items
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: List.generate(6, (i) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                height: 68,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
              )),
            ),
          ),
        ],
      ),
    );
  }
}
