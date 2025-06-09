import 'package:eggie2/pages/device_off.dart';
import 'package:eggie2/pages/device_page.dart';
import 'package:eggie2/pages/mode_on.dart';
import 'package:eggie2/pages/sleep_log.dart';
import 'package:eggie2/pages/useful_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

import '../services/api.dart';

class ModeOffPage extends StatefulWidget {
  final bool showStopModal;

  const ModeOffPage({super.key, this.showStopModal = false});

  @override
  State<ModeOffPage> createState() => _ModeOffPageState();
}

class _ModeOffPageState extends State<ModeOffPage> {
  late bool isNap; // 낮잠 모드인지 여부
  bool isNapAuto = true; // 낮잠 모드의 자동 상태
  bool isNightAuto = true; // 밤잠 모드의 자동 상태
  bool _isLogExpanded = false; // 로그 펼침 상태 관리

  bool _hasFetchedAutoEnv = false;

  Map<String, String> autoEnvValues = {};

  // 수면 시간 변수들
  String? sleepStartTime; // 수면 시작 시간
  String? sleepEndTime; // 수면 종료 시간
  String sleepDuration = '1시간 2분'; // 수면 시간 (계산된 값)

  String? _nextDaySleepModeLabel;
  String? _nextNightSleepModeLabel;

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

  String? _nextModeLabel;

  @override
  void initState() {
    super.initState();
    _setModeBasedOnTime(); // 페이지 진입 시 시간 기준으로 탭 설정
    _loadSavedStates().then((_) => _fetchAutoEnvValues());
    _fetchNextSleepModeLabel();
    _fetchTodayLogs(); // Pre-fetch logs once

    // 페이지 로드 후 바텀 시트 표시
    if (widget.showStopModal) {
      // 수면 시간 불러오기
      _loadSleepTimes();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _showStopModeBottomSheet(context);
          }
        });
      });
    }
  }

  Future<void> _fetchNextSleepModeLabel() async {
    try {
      final today = DateTime.now();
      final formatter = DateFormat('yyyy-MM-dd');
      final dateStr = formatter.format(today);
      final url = Uri.parse(
        '${getBaseUrl()}/sleep-mode-format?device_id=1&start_dt=$dateStr&end_dt=${dateStr}',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> logs = jsonDecode(response.body);
        int maxDayIndex = 0;
        int maxNightIndex = 0;

        for (var log in logs) {
          final modeString = log['sleep_mode'] ?? '';
          final mode = modeString.toString();

          final dayMatch = RegExp(r'낮잠(\d+)').firstMatch(mode);
          final nightMatch = RegExp(r'밤잠(\d+)').firstMatch(mode);

          if (dayMatch != null) {
            final index = int.tryParse(dayMatch.group(1) ?? '0') ?? 0;
            if (index > maxDayIndex) maxDayIndex = index;
          } else if (nightMatch != null) {
            final index = int.tryParse(nightMatch.group(1) ?? '0') ?? 0;
            if (index > maxNightIndex) maxNightIndex = index;
          }
        }

        setState(() {
          _nextDaySleepModeLabel = '낮잠${maxDayIndex + 1}';
          _nextNightSleepModeLabel = '밤잠${maxNightIndex + 1}';
        });
      } else {
        debugPrint('Failed to fetch today logs: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching today logs: $e');
    }
  }

  Future<void> _fetchAutoEnvValues() async {
    if (_hasFetchedAutoEnv) return;
    setState(() {
      _hasFetchedAutoEnv = true;
    });
    final url = Uri.parse('${getBaseUrl()}/detailed-history/1');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final String currentMode = isNap ? 'day' : 'night';

        final latest = data.reversed.firstWhere(
          (entry) => entry['sleep_mode'] == currentMode,
          orElse: () => null,
        );

        if (latest != null) {
          setState(() {
            autoEnvValues = {
              'temp': '${latest['temperature'].round()}°C',
              'humidity': '${latest['humidity'].round()}%',
              'brightness': '${latest['brightness'].round()}%',
              'sound': '${latest['white_noise_level'].round()}dB',
            };
          });
        } else {
          print('No recent entry found for mode: $currentMode');
        }
      } else {
        print('Failed to fetch environment values: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching auto environment values: $e');
    }
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

  // 모드 시작 시간을 SharedPreferences에 저장하기
  Future<void> _saveModeStartTime() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final modeType = isNap ? 'day' : 'night';

    // 현재 시간을 ISO 8601 형식으로 저장
    await prefs.setString('${modeType}_start_time', now.toIso8601String());

    // 추가적으로 모드 타입도 저장
    await prefs.setString('current_mode_type', modeType);
    await prefs.setBool('current_mode_auto', isAuto);

    // 수면 세션 활성화
    await prefs.setBool('sleep_session_active', true);

    print('Mode start time saved: $modeType at ${now.toIso8601String()}');
    print('Sleep session activated');
  }

  // 저장된 수면 시간들을 불러오기
  Future<void> _loadSleepTimes() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      // 1. 수면 시작 시간 불러오기
      final modeType =
          prefs.getString('current_mode_type') ?? (isNap ? 'day' : 'night');
      final startTimeString = prefs.getString('${modeType}_start_time');

      if (startTimeString != null) {
        final startTime = DateTime.parse(startTimeString);
        sleepStartTime = _formatTimeToKorean(startTime);
      }

      // 2. 수면 종료 시간 불러오기
      final endTimeKorean = prefs.getString('sleep_end_time_korean');
      if (endTimeKorean != null) {
        sleepEndTime = endTimeKorean;
      }

      // 3. 수면 시간 차이 계산
      await _calculateSleepDuration();

      setState(() {}); // UI 업데이트
    } catch (e) {
      print('Error loading sleep times: $e');
    }
  }

  // DateTime을 한국어 시간 형식으로 변환 (오후 HH:MM)
  String _formatTimeToKorean(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;

    String period;
    int displayHour;

    if (hour == 0) {
      period = '오전';
      displayHour = 12;
    } else if (hour < 12) {
      period = '오전';
      displayHour = hour;
    } else if (hour == 12) {
      period = '오후';
      displayHour = 12;
    } else {
      period = '오후';
      displayHour = hour - 12;
    }

    return '$period ${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
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

  // sleepReports: 오늘의 수면 기록을 담는 리스트 (API 등에서 데이터를 받아 populate 해야 함)
  List<dynamic> sleepReports = [];

  // 다음 모드 라벨 getter (오늘 날짜와 모드 기준)
  String get nextModeLabel {
    if (isNap) {
      return _nextDaySleepModeLabel ?? '낮잠1';
    } else {
      return _nextNightSleepModeLabel ?? '밤잠1';
    }
  }

  // 탭 전환 - 자유롭게 이동 가능
  void _onTabChanged(bool isNapMode) {
    setState(() {
      isNap = isNapMode;
      _hasFetchedAutoEnv = false; // allow refetch for new tab
    });
    _fetchAutoEnvValues();
    _fetchNextSleepModeLabel();
  }

  // 수면 시간 계산 메서드
  Future<void> _calculateSleepDuration() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      // 1. 수면 시작 시간 가져오기 (ISO format)
      final modeType =
          prefs.getString('current_mode_type') ?? (isNap ? 'day' : 'night');
      final startTimeString = prefs.getString('${modeType}_start_time');

      // 2. 수면 종료 시간 가져오기 (ISO format)
      final endTimeString = prefs.getString('sleep_end_time');

      if (startTimeString != null && endTimeString != null) {
        final startTime = DateTime.parse(startTimeString);
        final endTime = DateTime.parse(endTimeString);

        // 3. 시간 차이 계산
        final duration = endTime.difference(startTime);

        // 4. 시간, 분으로 변환
        final hours = duration.inHours;
        final minutes = duration.inMinutes % 60;

        // 5. 한국어 형식으로 변환
        String durationText = '';
        if (hours > 0 && minutes > 0) {
          durationText = '${hours}시간 ${minutes}분';
        } else if (hours > 0) {
          durationText = '${hours}시간';
        } else if (minutes > 0) {
          durationText = '${minutes}분';
        } else {
          durationText = '1분 미만';
        }

        setState(() {
          sleepDuration = durationText;
        });

        print('Sleep duration calculated: $durationText');
        print('  - Start: ${startTime.toIso8601String()}');
        print('  - End: ${endTime.toIso8601String()}');
        print('  - Duration: ${duration.inMinutes} minutes');
      } else {
        print('Start or end time not found in SharedPreferences');
      }
    } catch (e) {
      print('Error calculating sleep duration: $e');
      setState(() {
        sleepDuration = '계산 오류';
      });
    }
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

                if (isWrongTimeOfDay) _buildTimeOfDayNotice(),

                _buildTodayLogCard(),

                const SizedBox(height: 40),

                _buildModeToggleAndContent(),

                const SizedBox(height: 24),

                if (isAuto)
                  _buildAutoModeContent()
                else
                  _buildManualModeContent(),

                const SizedBox(height: 20),

                // 시작 버튼
                _buildModeStartBTN(),

                const SizedBox(height: 70),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomToggleBar(context),
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
              width: 230,
              height: 40,
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
                            fontSize: 12,
                            height: 18 / 12,
                            fontWeight: FontWeight.w600,
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
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    const UsefulFunctionPage(),
                            transitionDuration: Duration.zero,
                            reverseTransitionDuration: Duration.zero,
                          ),
                        );
                      },
                      child: const Center(
                        child: Text(
                          '유용한 기능',
                          style: TextStyle(
                            color: Color(0xFF606C80),
                            fontSize: 12,
                            height: 18 / 12,
                            fontWeight: FontWeight.w400,
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

  Widget _buildAutoModeContent() {
    final envValues = autoEnvValues.isNotEmpty
        ? autoEnvValues
        : {
            'temp': '20°C',
            'humidity': '30%',
            'brightness': '10%',
            'sound': '29dB',
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
              _buildAutoEnvInfoItem(
                icon: 'assets/images/temp.png',
                label: '온도',
                value: envValues['temp']!,
              ),
              _buildAutoEnvInfoItem(
                icon: 'assets/images/humidity.png',
                label: '습도',
                value: envValues['humidity']!,
              ),
              _buildAutoEnvInfoItem(
                icon: 'assets/images/brightness.png',
                label: '밝기',
                value: envValues['brightness']!,
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
                      envValues['sound']!,
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

  Widget _buildAutoEnvInfoItem({
    required String icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.only(
          top: 12,
          bottom: 14,
          left: 16,
          right: 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Image.asset(icon, width: 60, height: 60),
            const SizedBox(height: 8),
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
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
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

  Widget _buildEnvInfoItem({
    required String icon,
    required String label,
    required String keyName,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.only(
          top: 12,
          bottom: 14,
          left: 16,
          right: 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Image.asset(icon, width: 60, height: 60),
            const SizedBox(height: 8),
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
                  '16주차 우리 아기가 가장 잘 자는 환경이에요',
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
            nextModeLabel,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          ),
          IconButton(
            icon: SvgPicture.asset(
              'assets/icons/power_on.svg',
              width: 48,
              height: 48,
            ),
            onPressed: () async {
              // 디바이스 끄기 상태 저장
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('device_on', false);

              // 모든 수면 관련 데이터 초기화
              await prefs.remove('current_mode_type');
              await prefs.remove('day_start_time');
              await prefs.remove('night_start_time');
              await prefs.remove('sleep_end_time');
              await prefs.remove('sleep_end_time_korean');
              await prefs.setBool('sleep_session_active', false);

              print('Device turned off and all sleep data cleared');

              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const DeviceOff(),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTodayLogCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFF1F4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목 + 드롭다운 아이콘
          InkWell(
            onTap: () {
              setState(() {
                _isLogExpanded = !_isLogExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  const Text(
                    '오늘 사용 내역',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF606C80),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isLogExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: const Color(0xFF606C80),
                  ),
                ],
              ),
            ),
          ),

          // 로그 아이템들 - 펼침 상태일 때만 표시
          if (_isLogExpanded)
            FutureBuilder<List<Map<String, String>>>(
              future: _fetchTodayLogs(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('사용 내역을 불러오는 중 오류가 발생했습니다.'),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('오늘 사용 내역이 없습니다.'),
                  );
                } else {
                  return Column(
                    children: snapshot.data!
                        .map(
                          (log) => _buildTodayLogItem(
                            title: log['title']!,
                            timeRange: log['timeRange']!,
                          ),
                        )
                        .toList(),
                  );
                }
              },
            ),
        ],
      ),
    );
  }

  Future<List<Map<String, String>>> _fetchTodayLogs() async {
    return [
      {'title': '낮잠 1', 'timeRange': '오전 9:00 - 오전 10:30'},
      {'title': '밤잠 1', 'timeRange': '오후 8:00 - 오후 9:20'},
    ];
  }

  Widget _buildTodayLogItem({
    required String title,
    required String timeRange,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xFF111111),
            ),
          ),
          const Spacer(),
          Text(
            timeRange,
            style: const TextStyle(fontSize: 16, color: Color(0xFF111111)),
          ),
        ],
      ),
    );
  }

  void _showStopModeBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFEDF2F4),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 상단 핸들바
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFBEC1C1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),

                // 낮잠 2
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      isNap ? '낮잠 2' : '밤잠 1',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF111111),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),

                // 시간 카드
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        '수면 종료',
                        style: TextStyle(
                          fontSize: 16,
                          height: 24 / 16,
                          color: Color(0xFF606C80),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        sleepDuration, // 실제 계산된 수면 시간
                        style: const TextStyle(
                          fontSize: 32,
                          height: 24 / 32,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF111111),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${sleepStartTime ?? '오전 09:38'} - ${sleepEndTime ?? '오전 10:40'}', // 실제 수면 시간
                        style: const TextStyle(
                          fontSize: 14,
                          height: 24 / 14,
                          color: Color(0xFF606C80),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 수면 일지 바로가기
                _buildGoSLDetailPage(),

                // 하단 여백 (키보드가 올라올 때를 위한)
                SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGoSLDetailPage() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const TodaySleepLogPage(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.only(top: 16, bottom: 70),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Colors.transparent)),
          ),
          child: const Row(
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
              SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 20, color: Color(0xFF3386AA)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeStartBTN() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 44,
        child: ElevatedButton.icon(
          onPressed: () {
            // 모드 시작 시간을 DB에 저장
            _saveModeStartTime();

            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const ModeOnPage(),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3F4D63),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          icon: const Icon(Icons.play_arrow, color: Colors.white, size: 24),
          label: const Text(
            '시작',
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

Widget _buildTimeOfDayNotice() {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFEFF1F4)),
    ),
    child: Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '잠깐, 현재 시간대와 달라요.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF606C80),
                fontWeight: FontWeight.w400,
                height: 24 / 14,
              ),
            ),
            Text(
              '선택한 모드가 맞나요?',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF111111),
                fontWeight: FontWeight.w400,
                height: 24 / 16,
              ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Color(0xFFD5DBFF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            '확인',
            style: TextStyle(
              color: Color(0xFF4A57BF),
              fontSize: 11,
              fontWeight: FontWeight.w500,
              height: 18 / 11,
            ),
          ),
        ),
      ],
    ),
  );
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
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const DevicePage(),
                    transitionDuration: Duration.zero,
                    reverseTransitionDuration: Duration.zero,
                  ),
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
