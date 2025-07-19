import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class CustomSearchBar extends StatelessWidget {
  final String hintText;
  final VoidCallback? onTap;
  final TextEditingController? controller;
  final bool enabled;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final Function(String)? onChanged;

  const CustomSearchBar({
    super.key,
    required this.hintText,
    this.onTap,
    this.controller,
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: HopinColors.background,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: HopinColors.onBackground.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                if (prefixIcon != null) ...[
                  prefixIcon!,
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: enabled && onTap == null
                      ? TextField(
                          controller: controller,
                          onChanged: onChanged,
                          decoration: InputDecoration(
                            hintText: hintText,
                            border: InputBorder.none,
                            hintStyle: TextStyle(
                              color: HopinColors.onSurfaceVariant,
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      : Text(
                          hintText,
                          style: TextStyle(
                            color: enabled
                                ? HopinColors.onSurfaceVariant
                                : HopinColors.onSurfaceVariant.withValues(alpha: 0.5),
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                ),
                if (suffixIcon != null) ...[
                  const SizedBox(width: 12),
                  suffixIcon!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WhereToSearchBar extends StatelessWidget {
  final VoidCallback? onTap;

  const WhereToSearchBar({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return CustomSearchBar(
      hintText: 'Where to?',
      onTap: onTap,
      prefixIcon: Container(
        width: 12,
        height: 12,
        decoration: const BoxDecoration(
          color: HopinColors.primary,
          shape: BoxShape.circle,
        ),
      ),
      suffixIcon: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: HopinColors.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.schedule,
          size: 16,
          color: HopinColors.onSurfaceVariant,
        ),
      ),
    );
  }
} 