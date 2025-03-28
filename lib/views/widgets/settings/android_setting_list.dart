import 'package:flutter/material.dart';

class AndroidSettingList extends StatefulWidget {
  const AndroidSettingList({
    super.key,
    required this.icon,
    required this.mainTitle,
    required this.children,
  });

  final Widget icon;
  final String mainTitle;
  final List<Widget> children;

  @override
  State<AndroidSettingList> createState() => _AndroidSettingListState();
}

class _AndroidSettingListState extends State<AndroidSettingList>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _iconTurns;
  late Animation<double> _heightFactor;
  static final Animatable<double> _easeInTween =
      CurveTween(curve: Curves.easeIn);
  static final Animatable<double> _halfTween =
      Tween<double>(begin: 0.0, end: 0.5);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _heightFactor = _controller.drive(_easeInTween);
    _iconTurns = _controller.drive(_halfTween.chain(_easeInTween));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  Widget _buildHeader() {
    return TextButton(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      onPressed: _toggleExpansion,
      child: Row(
        children: [
          widget.icon,
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              widget.mainTitle,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          RotationTransition(
            turns: _iconTurns,
            child: const Icon(Icons.expand_more),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return ClipRect(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Align(
            heightFactor: _heightFactor.value,
            child: child,
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: widget.children,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(),
        _buildContent(),
      ],
    );
  }
}
