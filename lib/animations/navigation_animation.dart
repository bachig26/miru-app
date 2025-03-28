import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NavigationAnimation {
  /// Navigate to a new page with rounded corners animation using Get.to
  ///
  /// Parameters:
  /// - [page]: The widget to navigate to
  /// - [transition]: The type of transition animation (default is Transition.rightToLeft)
  /// - [duration]: Duration of the animation (default is 500ms)
  /// - [curve]: The animation curve (default is Curves.fastOutSlowIn)
  /// - [borderRadius]: Corner radius during animation (default is 20.0)
  static Future<T?>? roundedGetTo<T>({
    required Widget page,
    Transition transition = Transition.rightToLeft,
    Duration? duration = const Duration(milliseconds: 500),
    Curve curve = Curves.fastOutSlowIn,
    double borderRadius = 20.0,
    String? routeName,
  }) {
    return Get.to(
      () => _AnimationWrapper(
        borderRadius: borderRadius,
        duration: duration ?? const Duration(milliseconds: 500),
        child: page,
      ),
      transition: transition,
      routeName: page.runtimeType.toString(),
      duration: duration,
      curve: curve,
      opaque: false,
    );
  }
}

class _AnimationWrapper extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final Duration duration;

  const _AnimationWrapper({
    required this.child,
    required this.borderRadius,
    required this.duration,
  });

  @override
  State<_AnimationWrapper> createState() => _AnimationWrapperState();
}

class _AnimationWrapperState extends State<_AnimationWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _borderRadiusAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _borderRadiusAnimation = Tween<double>(
      begin: widget.borderRadius,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(
        0.9, // 开始时间：动画进行到90%
        1.0, // 结束时间：动画结束
        curve: Curves.easeOutCubic,
      ),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Material(
          type: MaterialType.transparency,
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: (Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey
                          : Colors.black)
                      .withValues(alpha: 0.2 * _opacityAnimation.value),
                  blurRadius: 10.0,
                  spreadRadius: 2.0,
                ),
              ],
            ),
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  _borderRadiusAnimation.value,
                ),
                child: widget.child,
              ),
            ),
          ),
        );
      },
    );
  }
}
