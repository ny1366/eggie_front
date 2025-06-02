import 'package:eggie2/pages/device_off.dart';
import 'package:eggie2/pages/mode_off.dart';
import 'package:eggie2/pages/mode_on.dart';
import 'package:eggie2/widgets/bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class _DeviceContent extends StatefulWidget {
  const _DeviceContent({super.key});

  @override
  State<_DeviceContent> createState() => _DeviceContentState();
}

class _DeviceContentState extends State<_DeviceContent> {
  // 디바이스 상태 관리
  bool isDeviceOn = false; // 디바이스 켜짐/꺼짐 상태
  bool isSleeping = false; // 수면 중인지 여부 (켜진 상태에서만 의미있음)
  String deviceStatus = '꺼짐'; // 표시될 상태 텍스트

  @override
  void initState() {
    super.initState();
    _loadDeviceStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 페이지가 다시 포커스될 때 상태 새로고침
    _loadDeviceStatus();
  }

  // 디바이스 상태 불러오기
  Future<void> _loadDeviceStatus() async {
    final prefs = await SharedPreferences.getInstance();

    // 디바이스 켜짐/꺼짐 상태 확인
    final deviceOn = prefs.getBool('device_on') ?? false;

    // 수면 상태 확인 (수면 시작 시간이 있으면 켜진 상태)
    final currentModeType = prefs.getString('current_mode_type');
    final hasSleepStartTime =
        currentModeType != null &&
        prefs.getString('${currentModeType}_start_time') != null;

    // 수면 세션 상태 확인 (실제로 현재 수면 중인지)
    final isSleepSessionActive = prefs.getBool('sleep_session_active') ?? false;

    setState(() {
      isDeviceOn = deviceOn || hasSleepStartTime; // 수면 시작했으면 디바이스 켜진 것으로 간주

      if (!isDeviceOn) {
        // 디바이스가 꺼져있으면
        deviceStatus = '꺼짐';
        isSleeping = false;
      } else {
        // 디바이스가 켜져있으면
        deviceStatus = '켜짐';

        // 수면 세션이 활성화되어 있으면 수면 중
        isSleeping = isSleepSessionActive;
      }
    });

    print('Device status loaded:');
    print('  - Device on: $isDeviceOn');
    print('  - Sleep session active: $isSleepSessionActive');
    print('  - Is sleeping: $isSleeping');
    print('  - Status text: $deviceStatus');
  }

  // EGGie 디바이스 탭했을 때 적절한 페이지로 이동
  void _onEggieDeviceTap() {
    if (!isDeviceOn) {
      // 디바이스가 꺼져있으면 device_off 페이지로
      Navigator.of(
        context,
        rootNavigator: true,
      ).push(MaterialPageRoute(builder: (context) => const DeviceOff()));
    } else if (isSleeping) {
      // 디바이스가 켜져있고 수면 중이면 mode_on 페이지로
      Navigator.of(
        context,
        rootNavigator: true,
      ).push(MaterialPageRoute(builder: (context) => const ModeOnPage()));
    } else {
      // 디바이스가 켜져있고 수면 완료 상태면 mode_off 페이지로
      Navigator.of(
        context,
        rootNavigator: true,
      ).push(MaterialPageRoute(builder: (context) => const ModeOffPage()));
    }
  }

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

  Widget _buildDeviceList() {
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
              subtitle: deviceStatus, // 동적으로 계산된 상태
              onTap: _onEggieDeviceTap, // 동적 네비게이션
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
