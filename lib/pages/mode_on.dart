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
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:eggie2/utils/time_formatter.dart';
import '../services/api.dart';

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
  Future<Map<String, String>>? _autoEnvFuture;
  late bool isNap; // 낮잠 모드인지 여부
  bool isNapAuto = true; // 낮잠 모드의 자동 상태
  bool isNightAuto = true; // 밤잠 모드의 자동 상태
  bool _isLogExpanded = false; // 로그 펼침 상태 관리

  // 수면 상태 관리
  SleepStatus currentSleepStatus = SleepStatus.sleeping;
  Timer? _statusCheckTimer;

  // 수면 시간 관리
  Timer? _sleepTimer; // 실시간 남은 시간 계산용 타이머
  DateTime? sleepStartDateTime; // 수면 시작 시간 (DateTime)
  DateTime? sleepExpectedEndDateTime; // 예상 수면 완료 시간 (DateTime)
  String remainingTimeText = '00:00:00 남음'; // 남은 시간 텍스트 (HH:MM:SS 형식)
  double sleepProgress = 0.0; // 수면 진행률 (0.0 ~ 1.0)

  // 수면 시작 시간 (= 모드 시작 버튼 누르고 생성된 값)
  String? sleepStartTime;

  // 예상 수면 완료 시간 (= DB에서 가져올 값)
  String sleepExpectedEndTime = ''; // 서버에서 가져온 값으로 초기화

  // 수면 종료 시간
  String? sleepEndTime;

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
    _autoEnvFuture = _fetchAutoEnvValues();
    _setModeBasedOnTime(); // 페이지 진입 시 시간 기준으로 탭 설정
    _loadSavedStates();
    _startSleepStatusMonitoring(); // 수면 상태 모니터링 시작
    _loadAndFormatExpectedEndTime();
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel(); // 타이머 정리
    _sleepTimer?.cancel(); // 수면 타이머 정리
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

    // 저장된 수면 시작 시간 불러오기
    await _loadSleepStartTime();
  }

  // 저장된 수면 시작 시간 불러오기
  Future<void> _loadSleepStartTime() async {
    final prefs = await SharedPreferences.getInstance();
    final modeType =
        prefs.getString('current_mode_type') ?? (isNap ? 'day' : 'night');

    final startTimeString = prefs.getString('${modeType}_start_time');

    if (startTimeString != null) {
      try {
        final startTime = DateTime.parse(startTimeString);
        setState(() {
          sleepStartTime = _formatTimeToKorean(startTime);
          sleepStartDateTime = startTime; // DateTime 설정
        });

        // 수면 타이머 시작
        _startSleepTimer();
      } catch (e) {
        print('Error parsing start time: $e');
        setState(() {
          sleepStartTime = null;
          sleepStartDateTime = null;
        });
      }
    }
  }

  // DateTime을 한국어 시간 형식으로 변환
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

    return '$period ${displayHour}:${minute.toString().padLeft(2, '0')}';
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

  // 탭 전환 - 수면 중일 때는 변경 불가
  void _onTabChanged(bool isNapMode) {
  setState(() {
    isNap = isNapMode;
    _autoEnvFuture = _fetchAutoEnvValues(); // 탭 바뀔 때 자동 환경 새로 로드
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
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const ModeOffPage(showStopModal: true),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  // 예상 완료 시간 문자열을 DateTime으로 변환
  DateTime _parseExpectedEndTimeLegacy(String timeString) {
    final now = DateTime.now();

    // "오후 8:00" 형식 파싱
    final isAfternoon = timeString.contains('오후');
    final timepart = timeString.replaceAll('오전 ', '').replaceAll('오후 ', '');
    final timeParts = timepart.split(':');

    if (timeParts.length != 2) {
      // 파싱 실패시 기본값 (오후 8:00)
      return DateTime(now.year, now.month, now.day, 20, 0);
    }

    int hour = int.tryParse(timeParts[0]) ?? 20;
    int minute = int.tryParse(timeParts[1]) ?? 0;

    if (isAfternoon && hour != 12) {
      hour += 12;
    } else if (!isAfternoon && hour == 12) {
      hour = 0;
    }

    DateTime expectedTime = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // 예상 완료 시간이 현재 시간보다 이전이면 다음날로 설정
    if (expectedTime.isBefore(now)) {
      expectedTime = expectedTime.add(const Duration(days: 1));
      print(
        'Expected end time adjusted to next day: ${expectedTime.toString()}',
      );
    }

    return expectedTime;
  }

  // API에서 예상 완료 시간 받아오기 및 포맷팅 (안전하게 처리)
  Future<void> _loadAndFormatExpectedEndTime() async {
    // 👉 주석처리: 실제 API에서 값을 받아오는 코드
    /*
    final url = Uri.parse('${getBaseUrl()}/sleep-session-summary/1');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('✅ Raw response data: $data');
        if (data.isNotEmpty && data.first['expected_end_at'] != null) {
          final rawEndAt = data.first['expected_end_at'];
          final endAt = HttpDate.parse(rawEndAt).toLocal();
          print('타이머 종료 예정 시각: $endAt');
          final formatted = formatKoreanTime(rawEndAt);

          setState(() {
            sleepExpectedEndDateTime = endAt;
            sleepExpectedEndTime = formatted;
          });
        } else {
          print('❗ No valid expected_end_at found in response');
        }
      } else {
        print('❗ API 응답 오류: ${response.statusCode}');
      }
    } catch (e) {
      print('❗ API 호출 실패: $e');
    }
    */

    // 👉 하드코딩된 종료 예정 시각
    sleepExpectedEndDateTime = DateTime(2025, 6, 10, 7, 55); // 2025-06-10 07:55:00
    sleepExpectedEndTime = '오전 7:55'; // 한국어 포맷 시각

    print('🛠 하드코딩된 종료 예정 시각 사용: $sleepExpectedEndDateTime');
  }

  // DateTime을 HH:mm 형식으로 변환 -> util/time_formatter.dart에서 가져옴

  // 실시간 수면 타이머 시작
  void _startSleepTimer() {
    _sleepTimer?.cancel();

    // 예상 완료 시간을 DateTime으로 변환
    // sleepExpectedEndDateTime = _parseExpectedEndTimeLegacy(sleepExpectedEndTime);
    // 👉 TODO: DB에서 받아온 실제 완료 시간으로 교체
    if (sleepExpectedEndDateTime == null) {
      print('❗ 타이머 시작 실패: 종료 시각 없음');
      return;
    }

    // print('Sleep timer started:');
    // print('  - Expected end time string: $sleepExpectedEndTime');
    // print(
    //   '  - Parsed expected end time: ${sleepExpectedEndDateTime.toString()}',
    // );
    // print('  - Current time: ${DateTime.now().toString()}');

    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateRemainingTime();
    });
  }

  // 남은 시간 및 진행률 계산
  void _updateRemainingTime() {
    if (sleepStartDateTime == null || sleepExpectedEndDateTime == null) return;

    final now = DateTime.now();
    final totalDuration = sleepExpectedEndDateTime!.difference(
      sleepStartDateTime!,
    );
    final remaining = sleepExpectedEndDateTime!.difference(now);

    // 디버깅을 위한 상세 로그
    // print('Timer update:');
    // print('  - Now: ${now.toString()}');
    // print('  - Sleep start: ${sleepStartDateTime.toString()}');
    // print('  - Expected end: ${sleepExpectedEndDateTime.toString()}');
    // print('  - Total duration: ${totalDuration.inMinutes} minutes');
    // print('  - Remaining: ${remaining.inMinutes} minutes');

    if (remaining.isNegative) {
      // 예상 시간이 지났으면 완료 처리
      print('  - AUTOMATIC TERMINATION: Expected time has passed');
      _sleepTimer?.cancel(); // ✅ 타이머 멈추기 추가

      setState(() {
        remainingTimeText = '00:00:00 남음';
        sleepProgress = 1.0;
      });

      _updateSleepStatus(SleepStatus.finished);
      return;
    }

    // 남은 시간을 HH:MM:SS 형식으로 표시
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;

    // 진행률 계산 (0.0 ~ 1.0): 전체 시간 중 남은 시간의 비율
    final progress = remaining.inMilliseconds / totalDuration.inMilliseconds;

    setState(() {
      remainingTimeText =
          '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')} 남음';
      sleepProgress = progress.clamp(0.0, 1.0);
    });
  }

  // 수면 종료 시간 저장
  Future<void> _saveSleepEndTime() async {
    final now = DateTime.now();
    final formattedKoreanTime = _formatTimeToKorean(now);

    setState(() {
      sleepEndTime = formattedKoreanTime;
    });

    // SharedPreferences에도 임시 저장 (mode_off에서 사용하기 위해)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sleep_end_time', now.toIso8601String());
    await prefs.setString('sleep_end_time_korean', formattedKoreanTime);

    // 수면 세션 비활성화
    await prefs.setBool('sleep_session_active', false);

    print('Sleep end time saved:');
    print('  - DateTime: ${now.toIso8601String()}');
    print('  - Korean time: $formattedKoreanTime');
    print(
      '  - Hour: ${now.hour}, Minute: ${now.minute}, Second: ${now.second}',
    );
    print('Sleep session deactivated');

    // 👉 TODO: DB에 수면 종료 시간 저장
    // await updateEndTimeDuration(now);
  }

  // // API 호출 함수: 종료시간과 duration 업데이트
  // Future<void> updateEndTimeDuration(DateTime endTime) async {
  //   final url = Uri.parse('${getBaseUrl()}/report/1/end');

  //   final response = await http.put(
  //     url,
  //     headers: {'Content-Type': 'application/json'},
  //     body: jsonEncode({
  //       "end_time": endTime.toIso8601String(),
  //     }),
  //   );

  //   if (response.statusCode == 200) {
  //     print('종료시간 업데이트 완료');
  //   } else {
  //     print('에러: ${response.body}');
  //   }
  // }

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
            // 👉🏻👉🏻👉🏻 DATA TODO: sleeping_mode + sequence 값 받아오기
            isNap ? '낮잠 2' : '밤잠 1',
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
          Text(
            remainingTimeText, // 실시간 계산된 남은 시간
            style: const TextStyle(
              fontSize: 32,
              height: 24 / 32,
              fontWeight: FontWeight.w500,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '수면 시작 ${sleepStartTime ?? '오전 9:38'}', // 저장된 시간 사용
            style: const TextStyle(
              fontSize: 14,
              height: 24 / 14,
              color: Color(0xFF606C80),
              fontWeight: FontWeight.w400,
            ),
          ),
          Text(
            '예상 완료 시각 $sleepExpectedEndTime', // DB에서 가져올 수면 완료 예상 시간
            style: const TextStyle(
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
              value: sleepProgress,
              minHeight: 8,
              backgroundColor: const Color(0xFFBEC1C1),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF2C92B4),
              ),
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

  Widget _buildModeStopBTN() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 44,
        child: ElevatedButton.icon(
          onPressed: () async {
            // 수면 종료 시간 저장 완료까지 대기
            await _saveSleepEndTime();

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
    // 자동 설정값을 서버에서 불러와서 사용
    if (_autoEnvFuture == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return FutureBuilder<Map<String, String>>(
      future: _autoEnvFuture!,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('환경 정보 로딩 실패'));
        } else {
          final envValues = snapshot.data ?? {
            'temp': '--',
            'humidity': '--',
            'brightness': '--',
            'sound': '--',
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
      },
    );
  }

  // 자동 환경값을 서버에서 불러오는 함수 (최신 낮잠/밤잠 환경값, 낮잠 우선)
  Future<Map<String, String>> _fetchAutoEnvValues() async {
  try {
    final url = Uri.parse('${getBaseUrl()}/detailed-history/1');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      // 최신 밤잠과 낮잠 값을 추출
      Map<String, dynamic>? latestDay;
      Map<String, dynamic>? latestNight;

      for (var entry in data.reversed) {
        if (latestDay == null && entry['sleep_mode'] == 'day') {
          latestDay = entry;
        }
        if (latestNight == null && entry['sleep_mode'] == 'night') {
          latestNight = entry;
        }
        if (latestDay != null && latestNight != null) break;
      }

      // 현재 모드에 따라 적절한 값을 선택
      final latest = isNap ? latestDay : latestNight;
      if (latest == null) throw Exception("No env data found for current mode");

      // Round all values and append proper units
      return {
        'temp': '${latest['temperature'].round()}°C',
        'humidity': '${latest['humidity'].round()}%',
        'brightness': '${latest['brightness'].round()}%',
        'sound': '${latest['white_noise_level'].round()}dB',
      };
    } else {
      throw Exception('Failed to load env data');
    }
  } catch (e) {
    print("Error fetching env values: $e");
    return {
      'temp': '--',
      'humidity': '--',
      'brightness': '--',
      'sound': '--',
    };
  }
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
}

class _buildGoSLDetailPage extends StatelessWidget {
  const _buildGoSLDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
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
