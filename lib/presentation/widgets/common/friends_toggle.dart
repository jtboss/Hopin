import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';

/// FriendsToggle - Snapchat-style friends filter toggle
/// 
/// Allows users to filter for friends-only rides with gold accent
/// and smooth animations. Essential for social prioritization in
/// the Snapchat-Uber hybrid experience.
class FriendsToggle extends StatefulWidget {
  final bool isActive;
  final VoidCallback onToggle;

  const FriendsToggle({
    super.key,
    required this.isActive,
    required this.onToggle,
  });

  @override
  State<FriendsToggle> createState() => _FriendsToggleState();
}

class _FriendsToggleState extends State<FriendsToggle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: HopinAnimations.fast,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: HopinAnimations.snapEase,
    ));

    _colorAnimation = ColorTween(
      begin: HopinColors.surfaceVariant,
      end: HopinColors.friendGold,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: HopinAnimations.snapEase,
    ));

    if (widget.isActive) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(FriendsToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.selectionClick();
    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: _colorAnimation.value,
                borderRadius: BorderRadius.circular(20),
                boxShadow: widget.isActive
                    ? [
                        BoxShadow(
                          color: HopinColors.friendGold.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.isActive ? Icons.star : Icons.star_outline,
                    size: 20,
                    color: widget.isActive 
                        ? HopinColors.midnightBlue
                        : HopinColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.isActive ? 'FRIENDS' : 'ALL',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: widget.isActive 
                          ? HopinColors.midnightBlue
                          : HopinColors.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}