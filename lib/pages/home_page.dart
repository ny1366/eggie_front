import 'package:eggie2/pages/device_off.dart';
import 'package:eggie2/pages/mode_off.dart';
import 'package:eggie2/pages/mode_on.dart';
import 'package:eggie2/widgets/bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(gradient: AppGradients.LG_home_bg),
          child: ListView(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 80,
              bottom: 24,
            ),
            children: const [HomeContent()],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentRoute: '/'),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final GlobalKey<_DeviceShortcutState> _eggieShortcutKey =
      GlobalKey<_DeviceShortcutState>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 페이지가 다시 포커스될 때 EGGie 디바이스 상태 새로고침
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _eggieShortcutKey.currentState?.loadDeviceStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 상단바
        _buildTopBar(),
        SizedBox(height: 16),
        // 홈 위치 설정 위젯
        _buildHomeLocationWidget(),
        const SizedBox(height: 16),
        // 육아 일지 바로가기 위젯
        _buildSleepLogWidget(),
        const SizedBox(height: 32),
        // 즐겨 찾는 제품
        Row(
          children: const [
            Text(
              '즐겨 찾는 제품',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            Spacer(),
            Icon(Icons.edit, size: 20, color: Color(0xFF606C80)),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            const _DeviceShortcut(
              icon: 'assets/images/home_washer.png',
              label: '세탁기',
            ),
            _DeviceShortcut(
              key: _eggieShortcutKey, // EGGie 디바이스에 키 추가
              icon: 'assets/images/EGGie_device.png',
              label: 'EGGie',
            ),
          ],
        ),
        const SizedBox(height: 32),
        // 스마트 루틴
        Row(
          children: [
            const Text(
              '스마트 루틴',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Icon(
              Icons.keyboard_arrow_right_rounded,
              size: 20,
              color: Color(0xFF606C80),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.only(
            left: 16,
            right: 40,
            top: 16,
            bottom: 16,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Image.asset(
                'assets/images/home_smart_routine.png',
                width: 32,
                height: 32,
              ),
              SizedBox(width: 8),
              const Text(
                '루틴 알아보기',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF111111),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 120),
      ],
    );
  }
}

class _DeviceShortcut extends StatefulWidget {
  final String icon;
  final String label;
  const _DeviceShortcut({super.key, required this.icon, required this.label});

  @override
  State<_DeviceShortcut> createState() => _DeviceShortcutState();
}

class _DeviceShortcutState extends State<_DeviceShortcut> {
  // EGGie 디바이스인지 확인
  bool get isEggieDevice => widget.label == 'EGGie';

  // EGGie 디바이스 상태 관리 (다른 디바이스는 상태 관리 안함)
  bool isDeviceOn = false;
  bool isSleeping = false;

  @override
  void initState() {
    super.initState();
    if (isEggieDevice) {
      loadDeviceStatus();
    }
  }

  // 디바이스 상태 불러오기 (EGGie만)
  Future<void> loadDeviceStatus() async {
    if (!isEggieDevice) return;

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
        isSleeping = false;
      } else {
        // 수면 세션이 활성화되어 있으면 수면 중
        isSleeping = isSleepSessionActive;
      }
    });

    print('Home page device status loaded:');
    print('  - Device on: $isDeviceOn');
    print('  - Sleep session active: $isSleepSessionActive');
    print('  - Is sleeping: $isSleeping');
  }

  // EGGie 디바이스 탭했을 때 적절한 페이지로 이동
  void _onEggieDeviceTap() {
    if (!isDeviceOn) {
      // 디바이스가 꺼져있으면 device_off 페이지로
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DeviceOff()),
      );
    } else if (isSleeping) {
      // 디바이스가 켜져있고 수면 중이면 mode_on 페이지로
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ModeOnPage()),
      );
    } else {
      // 디바이스가 켜져있고 수면 완료 상태면 mode_off 페이지로
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ModeOffPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEggieDevice ? _onEggieDeviceTap : null, // EGGie만 탭 이벤트 추가
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 135,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFC1D2DC),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Image.asset(
                widget.icon,
                width: 40,
                height: 40,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.label,
            style: const TextStyle(fontSize: 14, color: Color(0xFF111111)),
          ),
        ],
      ),
    );
  }
}

class _buildSleepLogWidget extends StatelessWidget {
  const _buildSleepLogWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset('assets/images/gpt_baby.png', width: 80, height: 80),
          const SizedBox(width: 32),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Text(
                    '우리 아기 태어난지',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(width: 6),
                  Text(
                    '16',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    ' 주차',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Color(0xFFD5DBFF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '육아일지 바로가기',
                  style: TextStyle(
                    color: Color(0xFF4A57BF),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _buildHomeLocationWidget extends StatelessWidget {
  const _buildHomeLocationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Image.asset(
            'assets/images/home_page_home.png',
            width: 64,
            height: 64,
          ),
          const SizedBox(height: 12),
          const Text(
            '홈 위치를 설정하면맞춤 정보와 기능을 사용할 수 있어요.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4A57BF),
              shape: const StadiumBorder(),
            ),
            onPressed: () {},
            child: const Text(
              '설정하기',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
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

class AppGradients {
  static const LinearGradient LG_home_bg = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFFE9F4F7), Color(0xFFD1E5F3), Color(0xFFE9F4F7)],
  );
}
