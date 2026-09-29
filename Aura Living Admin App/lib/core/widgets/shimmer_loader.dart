import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// ShimmerLoader provides smooth skeleton loading animations
/// matching target screen geometry.
class ShimmerLoader extends StatefulWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final Widget? child;

  const ShimmerLoader({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
    this.child,
  });

  @override
  State<ShimmerLoader> createState() => _ShimmerLoaderState();
}

class _ShimmerLoaderState extends State<ShimmerLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.3).clamp(0.0, 1.0),
              ],
              colors: const [
                Color(0xFFE4E4E7),
                Color(0xFFF4F4F6),
                Color(0xFFE4E4E7),
              ],
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}

/// ShimmerCard for generic card skeletons matching height and width
class ShimmerCard extends StatelessWidget {
  final double height;
  final double? width;
  final double borderRadius;

  const ShimmerCard({
    super.key,
    required this.height,
    this.width,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerLoader(
      height: height,
      width: width,
      borderRadius: borderRadius,
    );
  }
}

/// Shimmer skeleton for metric cards (2x2 grid)
class MetricCardSkeleton extends StatelessWidget {
  const MetricCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerLoader(width: 80, height: 14),
              ShimmerLoader(width: 24, height: 24, borderRadius: 12),
            ],
          ),
          SizedBox(height: 12),
          ShimmerLoader(width: 120, height: 28),
          SizedBox(height: 8),
          ShimmerLoader(width: 70, height: 12),
        ],
      ),
    );
  }
}

/// Shimmer skeleton for list items (products/orders)
class ListItemSkeleton extends StatelessWidget {
  const ListItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          ShimmerLoader(width: 56, height: 56, borderRadius: 6),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLoader(width: double.infinity, height: 14),
                SizedBox(height: 8),
                ShimmerLoader(width: 140, height: 12),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerLoader(width: 80, height: 14),
                    ShimmerLoader(width: 60, height: 18, borderRadius: 4),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
