import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class NavItem extends StatelessWidget {
  final String iconPath;
  final String label;
  final bool active;

  const NavItem({
    super.key,
    required this.iconPath,
    required this.label,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF111111) : const Color(0xFFBEC1C1);

    return Semantics(
      label: label,
      selected: active,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'assets/icons/$iconPath',
            width: 24,
            height: 24,
            color: color,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.54,
              letterSpacing: -0.20,
            ).copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
