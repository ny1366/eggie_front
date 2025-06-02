import 'package:eggie2/widgets/nav_item.dart';
import 'package:flutter/material.dart';
import 'package:eggie2/pages/home_page.dart';
import 'package:eggie2/pages/device_page.dart';

class BottomNavBar extends StatelessWidget {
  final String currentRoute;

  const BottomNavBar({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      color: const Color(0xFFEDF2F4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => _changePage(context, '/'),
              child: SizedBox(
                width: 89,
                child: NavItem(
                  iconPath: 'home_icon.svg',
                  label: '홈',
                  active: currentRoute == '/',
                ),
              ),
            ),
            GestureDetector(
              onTap: () => _changePage(context, '/device'),
              child: SizedBox(
                width: 89,
                child: NavItem(
                  iconPath: 'device_icon.svg',
                  label: '디바이스',
                  active: currentRoute == '/device',
                ),
              ),
            ),
            const SizedBox(
              width: 89,
              child: NavItem(iconPath: 'report_icon.svg', label: '리포트'),
            ),
            const SizedBox(
              width: 89,
              child: NavItem(iconPath: 'menu_icon.svg', label: '메뉴'),
            ),
          ],
        ),
      ),
    );
  }
}

final Map<String, Widget Function()> routePages = {
  '/': () => const HomePage(),
  '/device': () => const DevicePage(),
};

void _changePage(BuildContext context, String route) {
  if (ModalRoute.of(context)?.settings.name != route &&
      routePages.containsKey(route)) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return routePages[route]!();
        },
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }
}
