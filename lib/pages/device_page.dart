import 'package:eggie2/pages/device_off.dart';
import 'package:eggie2/widgets/bottom_nav_bar.dart';
import 'package:flutter/material.dart';

class DevicePage extends StatelessWidget {
  const DevicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          color: const Color(0xFFEDF2F4),
          child: Stack(
            children: [
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: Image.asset('assets/images/device_girl.png'),
                ),
              ),
              ListView(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 80,
                  bottom: 24,
                ),
                children: const [_DeviceContent()],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentRoute: '/device'),
    );
  }
}

class _DeviceContent extends StatelessWidget {
  const _DeviceContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 상단바
        _buildTopBar(),
        const SizedBox(height: 16),
        // 디바이스 목록
        _buildDeviceList(),
      ],
    );
  }
}

class _buildDeviceList extends StatelessWidget {
  const _buildDeviceList({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        Material(
          color: Colors.transparent,
          child: SizedBox(
            width: (MediaQuery.of(context).size.width - 44) / 2,
            height: 114,
            child: _DeviceCard(
              image: 'assets/images/home_washer.png',
              title: '세탁기',
              subtitle: '꺼짐',
            ),
          ),
        ),
        Material(
          color: Colors.transparent,
          child: SizedBox(
            width: (MediaQuery.of(context).size.width - 44) / 2,
            height: 114,
            child: _DeviceCard(
              image: 'assets/images/EGGie_device.png',
              title: 'EGGie',
              subtitle: '꺼짐',
              onTap: () {
                Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(builder: (context) => const DeviceOff()),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final String image, title, subtitle;
  final VoidCallback? onTap;

  const _DeviceCard({
    required this.image,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFD8DADC),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(image, width: 41.25, height: 41.25),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Color(0xFF111111),
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 13,
                color: Color(0xFF606C80),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _buildTopBar extends StatelessWidget {
  const _buildTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '이주은 홈',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111111),
          ),
        ),
        SizedBox(width: 4),
        Icon(
          Icons.keyboard_arrow_down_rounded,
          size: 20,
          color: Color(0xFF606C80),
        ),
        Spacer(),
        IconButton(
          icon: const Icon(Icons.add, color: Color(0xFF606C80)),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.notifications, color: Color(0xFF606C80)),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.more_horiz, color: Color(0xFF606C80)),
          onPressed: () {},
        ),
      ],
    );
  }
}
