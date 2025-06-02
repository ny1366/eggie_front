import 'package:eggie2/pages/device_off.dart';
import 'package:eggie2/pages/device_page.dart';
import 'package:eggie2/pages/mode_off.dart';
import 'package:eggie2/pages/mode_on.dart';
import 'package:eggie2/pages/sleep_log.dart';
import 'package:eggie2/pages/useful_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

enum SleepStatus {
  sleeping, // 수면 중
  finished, // 수면 종료
}

class ModeOnPage extends StatefulWidget {
  const ModeOnPage({super.key});

  @override
  State<ModeOnPage> createState() => _ModeOnPageState();
}

class _ModeOnPageState extends State<ModeOnPage> {
  late bool isNap; // 낮잠 모드인지 여부
  bool isNapAuto = true; // 낮잠 모드의 자동 상태
  bool isNightAuto = true; // 밤잠 모드의 자동 상태
  bool _isLogExpanded = false; // 로그 펼침 상태 관리

  // 수면 상태 관리
  SleepStatus currentSleepStatus = SleepStatus.sleeping;
  Timer? _statusCheckTimer;

  final Map<String, List<String>> optionValues = {
    'temp': ['18°C', '19°C', '20°C', '21°C'],
    'humidity': ['20%', '30%', '40%', '50%'],
    'wind': ['OFF', '약풍', '중풍', '강풍'],
    'brightness': ['0%', '5%', '10%', '20%'],
    'humid': ['OFF', '낮음', '중간', '높음'],
    'dehumid': ['OFF', '약하게', '보통', '강하게'],
    'sound': ['20dB', '29dB', '35dB', '40dB'],
  };

  final Map<String, int> currentIndexes = {
    'temp': 2,
    'humidity': 1,
    'wind': 1,
    'brightness': 2,
    'humid': 1,
    'dehumid': 0,
    'sound': 1,
  };

  @override
  void initState() {
    super.initState();
    _setModeBasedOnTime(); // 페이지 진입 시 시간 기준으로 탭 설정
    _loadSavedStates();
    _startSleepStatusMonitoring(); // 수면 상태 모니터링 시작
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel(); // 타이머 정리
    super.dispose();
  }

  // 현재 시간을 기준으로 낮잠/밤잠 모드 설정
  void _setModeBasedOnTime() {
    final now = TimeOfDay.now();
    final eveningStartHour = 18; // 오후 6시

    setState(() {
      isNap = now.hour < eveningStartHour;
    });
  }

  // SharedPreferences에서 자동/수동 설정 불러오기
  Future<void> _loadSavedStates() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isNapAuto = prefs.getBool('isNapAuto') ?? true;
      isNightAuto = prefs.getBool('isNightAuto') ?? true;
    });
  }

  // 각 모드의 자동/수동 설정을 SharedPreferences에 저장하기
  Future<void> _saveStates() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isNapAuto', isNapAuto);
    await prefs.setBool('isNightAuto', isNightAuto);
  }

  // 현재 선택된 모드(낮잠/밤잠)에 따라 자동/수동 여부를 설정하고 저장하기
  bool get isAuto => isNap ? isNapAuto : isNightAuto;
  set isAuto(bool value) {
    setState(() {
      if (isNap) {
        isNapAuto = value;
      } else {
        isNightAuto = value;
      }
      _saveStates(); // 상태 변경 시 저장
    });
  }

  // 탭 전환 - 자유롭게 이동 가능
  void _onTabChanged(bool isNapMode) {
    setState(() {
      isNap = isNapMode;
    });
  }

  // 수면 상태 실시간 모니터링 시작
  void _startSleepStatusMonitoring() {
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _checkSleepStatus();
    });
  }

  // 수면 상태 확인 (실제로는 API에서 받아올 데이터)
  void _checkSleepStatus() {
    // 👉 TODO: 실제 API에서 수면 상태를 받아오는 로직으로 교체
    // 외부에서 수면 종료 상태가 들어온 경우 처리
    // SleepStatus newStatus = await ApiService.getCurrentSleepStatus();
    // if (newStatus == SleepStatus.finished && currentSleepStatus != SleepStatus.finished) {
    //   _handleSleepFinished();
    // }
  }

  // 수면 상태 업데이트
  void _updateSleepStatus(SleepStatus newStatus) {
    if (mounted && currentSleepStatus != newStatus) {
      setState(() {
        currentSleepStatus = newStatus;
      });

      // 수면 종료 상태가 되면 자동으로 처리
      if (newStatus == SleepStatus.finished) {
        _handleSleepFinished();
      }
    }
  }

  // 수면 종료 처리 (수동/자동 공통)
  void _handleSleepFinished() {
    _statusCheckTimer?.cancel(); // 모니터링 중지
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ModeOffPage(showStopModal: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 현재 시간이 오후 6시 이전이면 낮잠, 이후면 밤잠이 적절
    final now = TimeOfDay.now();
    final eveningStartHour = 18;
    final isNapTime = now.hour < eveningStartHour;

    // 현재 시간대와 선택된 탭이 불일치하는지 확인
    final isWrongTimeOfDay = isNapTime != isNap;

    return Scaffold(
      backgroundColor: const Color(0xFFEDF2F4),
      appBar: _buildEggieTopBar(context),
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          // 상단 여백
          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // EGGie 이미지
          SliverToBoxAdapter(
            child: Center(
              child: Image.asset('assets/images/device_on_eggie.png'),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Sticky Sleep Tab
          SliverPersistentHeader(
            pinned: true,
            floating: false,
            delegate: _SleepTabHeaderDelegate(
              isNap: isNap,
              child: Container(
                color: const Color(0xFFEDF2F4),
                child: _buildSleepTab(),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // 나머지 컨텐츠들
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildDeviceStatus(),

                const SizedBox(height: 8),

                // 수면 중 카드 표시
                _buildSleepingCard(),

                const SizedBox(height: 16),

                _buildModeStopBTN(),

                const SizedBox(height: 40),

                _buildModeToggleAndContent(),

                const SizedBox(height: 24),

                if (isAuto)
                  _buildAutoModeContent()
                else
                  _buildManualModeContent(),

                const SizedBox(height: 70),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomToggleBar(context),
    );
  }

  Widget _buildSleepTab() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _onTabChanged(true),
            child: Column(
              children: [
                Text(
                  '낮잠',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: isNap
                        ? const Color(0xFF111111)
                        : const Color(0xFF606C80),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 3,
                  width: 40,
                  color: isNap ? const Color(0xFF111111) : Colors.transparent,
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          GestureDetector(
            onTap: () => _onTabChanged(false),
            child: Column(
              children: [
                Text(
                  '밤잠',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: !isNap
                        ? const Color(0xFF111111)
                        : const Color(0xFF606C80),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 3,
                  width: 40,
                  color: !isNap ? const Color(0xFF111111) : Colors.transparent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceStatus() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            // 👉🏻 DATA TODO: 모드 이름 + Index 받아오기
            isNap ? '낮잠 2' : '밤잠 1',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          ),
          IconButton(
            icon: SvgPicture.asset(
              'assets/icons/power_on.svg',
              width: 48,
              height: 48,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DeviceOff()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSleepingCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            '수면 중',
            style: TextStyle(
              fontSize: 16,
              height: 24 / 16,
              color: Color(0xFF606C80),
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '00:28 남음', // 👉 TODO: 실제 수면 시간 계산 필요
            style: TextStyle(
              fontSize: 32,
              height: 24 / 32,
              fontWeight: FontWeight.w500,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '수면 시작 오전 9:38', // 👉 TODO: 실제 시간으로 치환
            style: TextStyle(
              fontSize: 14,
              height: 24 / 14,
              color: Color(0xFF606C80),
              fontWeight: FontWeight.w400,
            ),
          ),
          const Text(
            '예상 완료 시각 오전 10:40', // 👉 TODO: 실제 시간으로 치환
            style: TextStyle(
              fontSize: 14,
              height: 24 / 14,
              color: Color(0xFF606C80),
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: 0.6, // 👉 TODO: 실제 수면 진행 비율 (0.0 ~ 1.0) 계산
              minHeight: 8,
              backgroundColor: const Color(0xFFBEC1C1),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF2C92B4),
              ), // 수면 중일 때는 초록색
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggleAndContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAuto ? '자동' : '수동',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              if (isAuto)
                const Text(
                  // 👉🏻 DATA TODO: 아기 개월수 받아오기
                  '34 개월 우리 아기가 가장 잘 자는 환경이에요',
                  style: TextStyle(fontSize: 12, color: Color(0xFF606C80)),
                ),
            ],
          ),
          const Spacer(),
          Switch(
            value: isAuto,
            onChanged: (value) => isAuto = value,
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFF405474),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFD8DADC),
          ),
        ],
      ),
    );
  }

  Widget _buildModeStopBTN() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 44,
        child: ElevatedButton.icon(
          onPressed: () {
            // 수동으로 수면 종료
            _updateSleepStatus(SleepStatus.finished);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3F4D63),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          icon: const Icon(Icons.stop, color: Colors.white, size: 24),
          label: const Text(
            '중지',
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildAutoModeContent() {
    // 👉🏻 TODO: DB에서 낮잠/밤잠 모드별 자동 설정값 불러오기
    final envValues = isNap
        ? {
            'temp': '20°C',
            'humidity': '30%',
            'brightness': '10%',
            'sound': '29dB',
          }
        : {
            'temp': '18°C',
            'humidity': '40%',
            'brightness': '5%',
            'sound': '35dB',
          };
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.only(left: 24, right: 24, top: 22, bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 40,
                height: 24,
                child: Text(
                  '현재',
                  style: TextStyle(
                    fontSize: 16,
                    height: 24 / 16,
                    color: Color(0xFF606C80),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Container(
                width: 40,
                height: 24,
                child: Text(
                  '희망',
                  style: TextStyle(
                    fontSize: 16,
                    height: 24 / 16,
                    color: Color(0xFF606C80),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
          _buildSleepingEnvItem(
            icon: 'assets/images/temp.png',
            label: '온도',
            keyName: 'temp',
            envValues: envValues,
          ),
          _buildDevider(),
          _buildSleepingEnvItem(
            icon: 'assets/images/humidity.png',
            label: '습도',
            keyName: 'humidity',
            envValues: envValues,
          ),
          _buildDevider(),
          _buildSleepingEnvItem(
            icon: 'assets/images/brightness.png',
            label: '밝기',
            keyName: 'brightness',
            envValues: envValues,
          ),
          _buildDevider(),
          _buildSleepingEnvItem(
            icon: 'assets/images/sound.png',
            label: '백색 소음',
            keyName: 'sound',
            envValues: envValues,
          ),
        ],
      ),
    );
  }

  Widget _buildEnvInfoItem({
    required String icon,
    required String label,
    required String keyName,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: EdgeInsets.only(top: 12, bottom: 14, left: 16, right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Image.asset(icon, width: 60, height: 60),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!isAuto)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        final index = currentIndexes[keyName]!;
                        currentIndexes[keyName] =
                            (index - 1 + optionValues[keyName]!.length) %
                            optionValues[keyName]!.length;
                      });
                    },
                    child: SvgPicture.asset(
                      "assets/icons/round_arrow_left.svg",
                      width: 24,
                      height: 24,
                    ),
                  ),
                const Spacer(),
                Column(
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF606C80),
                      ),
                    ),
                    Text(
                      optionValues[keyName]![currentIndexes[keyName]!],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (!isAuto)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        final index = currentIndexes[keyName]!;
                        currentIndexes[keyName] =
                            (index + 1) % optionValues[keyName]!.length;
                      });
                    },
                    child: SvgPicture.asset(
                      "assets/icons/round_arrow_right.svg",
                      width: 24,
                      height: 24,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualModeContent() {
    // 👉🏻 TODO: DB에서 낮잠/밤잠 모드별 수동 설정값 불러오기
    final envValues = isNap
        ? {
            'wind': '약풍',
            'brightness': '10%',
            'humid': '낮음',
            'dehumid': 'OFF',
            'sound': '29dB',
          }
        : {
            'wind': '중풍',
            'brightness': '5%',
            'humid': '중간',
            'dehumid': 'OFF',
            'sound': '35dB',
          };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 환경 정보 카드
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildEnvInfoItem(
                icon: 'assets/images/temp.png',
                label: '바람 세기',
                keyName: 'wind',
              ),
              _buildEnvInfoItem(
                icon: 'assets/images/brightness.png',
                label: '밝기',
                keyName: 'brightness',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildEnvInfoItem(
                icon: 'assets/images/humid.png',
                label: '가습 세기',
                keyName: 'humid',
              ),
              _buildEnvInfoItem(
                icon: 'assets/images/dehumid.png',
                label: '제습 세기',
                keyName: 'dehumid',
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 백색 소음 카드
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Image.asset('assets/images/sound.png', width: 60, height: 60),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '백색 소음',
                      style: TextStyle(fontSize: 16, color: Color(0xFF606C80)),
                    ),
                    Text(
                      optionValues['sound']![currentIndexes['sound']!],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomToggleBar(BuildContext context) {
    return SafeArea(
      child: Container(
        height: 108,
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFFFFFFF), width: 1)),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          child: Center(
            child: Container(
              width: 240,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 2,
                  ),
                ],
              ),
              child: Row(
                children: [
                  // '제품' 탭 (선택된 상태)
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF3F4D63),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: const Center(
                        child: Text(
                          '제품',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // '유용한 기능' 탭 (비선택 상태)
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UsefulFunctionPage(),
                          ),
                        );
                      },
                      child: const Center(
                        child: Text(
                          '유용한 기능',
                          style: TextStyle(
                            color: Color(0xFF606C80),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _buildGoSLDetailPage extends StatelessWidget {
  const _buildGoSLDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TodaySleepLogPage()),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.only(top: 16, bottom: 70),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Colors.transparent)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '오늘 수면 일지 확인하기',
                style: TextStyle(
                  color: Color(0xFF3386AA), // 파란색 계열
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: Color(0xFF3386AA),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildDevider() {
  return const Divider(height: 1, color: Color(0xFFEFF1F4));
}

Container _buildSleepingEnvItem({
  required String icon,
  required String label,
  required String keyName,
  required Map<String, String> envValues,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        Row(
          children: [
            Image.asset(icon, width: 40, height: 40),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Color(0xFF111111),
              ),
            ),
          ],
        ),
        Spacer(),
        SizedBox(
          child: Text(
            getEnvValueByLabel(label),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xFF111111),
            ),
          ),
          width: 40,
        ),
        const SizedBox(width: 24),
        SizedBox(
          child: Text(
            envValues[keyName]!,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xFF111111),
            ),
          ),
          width: 40,
        ),
      ],
    ),
  );
}

String getEnvValueByLabel(String label) {
  switch (label) {
    case '온도':
      return '24°C';
    case '습도':
      return '32%';
    case '밝기':
      return '10%';
    case '백색 소음':
      return '29dB';
    default:
      return '';
  }
}

PreferredSizeWidget _buildEggieTopBar(BuildContext context) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(100),
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: 60, left: 8, right: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DevicePage()),
                );
              },
              color: const Color(0xFF606C80),
            ),
            const Text(
              'EGGie',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111111),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {},
              color: const Color(0xFF606C80),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SleepTabHeaderDelegate extends SliverPersistentHeaderDelegate {
  final bool isNap;
  final Widget child;

  const _SleepTabHeaderDelegate({required this.isNap, required this.child});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox(height: minExtent, child: child);
  }

  @override
  double get maxExtent => 60;

  @override
  double get minExtent => 60;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    if (oldDelegate is _SleepTabHeaderDelegate) {
      return isNap != oldDelegate.isNap;
    }
    return true;
  }
}
