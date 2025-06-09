import 'package:eggie2/pages/device_current_log.dart';
import 'package:eggie2/pages/device_page.dart';
import 'package:eggie2/pages/mode_off.dart';
import 'package:eggie2/pages/sleep_log.dart';
import 'package:eggie2/pages/useful_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../services/api.dart';
import 'dart:io'; // Ensure this import is present at the top

Future<List<Map<String, dynamic>>> fetchLatestSleepLogs() async {
  // final today = DateTime.now();
  final today = DateTime(2024, 9, 16); // ✅ 하드코딩된 날짜 (임시)
  final formatter = DateFormat('yyyy-MM-dd');
  final startDt = formatter.format(today);
  final endDt = formatter.format(today.add(const Duration(days: 1)));

  final response = await http.get(
    Uri.parse(
      '${getBaseUrl()}/sleep-mode-format?device_id=1&start_dt=$startDt&end_dt=$endDt',
    ),
  );
  print('🔍 sleep-mode-format response: ${response.body}');
  if (response.statusCode == 200) {
    return List<Map<String, dynamic>>.from(jsonDecode(response.body));
  } else {
    throw Exception('Failed to load sleep logs');
  }
}

class DeviceOff extends StatefulWidget {
  const DeviceOff({super.key});

  @override
  State<DeviceOff> createState() => _DeviceOffState();
}

class _DeviceOffState extends State<DeviceOff> {
  bool _isTodayLogExpanded = false;
  bool _isEstimatedLogExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDF2F4),
      appBar: _buildEggieTopBar(context),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),

            Center(child: Image.asset('assets/images/device_on_eggie.png')),

            const SizedBox(height: 24),

            _buildDeviceStatus(),

            const SizedBox(height: 14),

            _buildDeviceLogWidget(),

            const SizedBox(height: 16),

            _buildTodayLogWidget(),

            const SizedBox(height: 16),

            _buildTodayEstimatedLogWidget(),

            const SizedBox(height: 16),

            _buildGoSLDetailPage(),
          ],
        ),
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

  Container _buildTodayEstimatedLogWidget() {
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
                _isEstimatedLogExpanded = !_isEstimatedLogExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  const Text(
                    '오늘 예상 수면 스케줄',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF606C80),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isEstimatedLogExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: Color(0xFF606C80),
                  ),
                ],
              ),
            ),
          ),

          if (_isEstimatedLogExpanded) ...[
            // 낮잠 3
            _buildTodayLogItem(
              title: '낮잠 3',
              timeRange: '오전 9:30  -  오전 10:40',
            ),
            _buildDevider(),

            // 밤잠 1
            _buildTodayLogItem(title: '밤잠 1', timeRange: '오후 1:32  -  오후 3:00'),
            _buildDevider(),

            // 밤잠 2
            _buildTodayLogItem(title: '밤잠 2', timeRange: '오후 1:32  -  오후 3:00'),
          ],
        ],
      ),
    );
  }

  Container _buildTodayLogWidget() {
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
                _isTodayLogExpanded = !_isTodayLogExpanded;
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
                    _isTodayLogExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: Color(0xFF606C80),
                  ),
                ],
              ),
            ),
          ),

          if (_isTodayLogExpanded)
            FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchLatestSleepLogs(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                } else if (snapshot.hasError) {
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('에러 발생'),
                  );
                } else {
                  final data = snapshot.data ?? [];

                  String formatKoreanTime(String? raw) {
                    if (raw == null) return '시간 없음';
                    try {
                      final dt = HttpDate.parse(raw).toLocal();
                      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
                      final period = dt.hour < 12 ? '오전' : '오후';
                      final minute = dt.minute.toString().padLeft(2, '0');
                      return '$period $hour:$minute';
                    } catch (e) {
                      return '시간 오류';
                    }
                  }

                  final grouped = data.map((log) {
                    final title = log['sleep_mode'] ?? '기타';

                    final rawStart = log['recorded_at'];
                    final rawEnd = log['end_time'];

                    final start = rawStart != null
                        ? formatKoreanTime(rawStart)
                        : '시간 없음';
                    final end = rawEnd != null
                        ? formatKoreanTime(rawEnd)
                        : '시간 없음';

                    return _buildTodayLogItem(
                      title: title,
                      timeRange: '$start  -  $end',
                    );
                  }).toList();

                  return Column(
                    children: List.generate(grouped.length * 2 - 1, (i) {
                      if (i.isEven) return grouped[i ~/ 2];
                      return const _buildDevider();
                    }),
                  );
                }
              },
            ),
        ],
      ),
    );
  }

  Padding _buildTodayLogItem({
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

class _buildDeviceLogWidget extends StatelessWidget {
  const _buildDeviceLogWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFF1F4)),
      ),
      child: Column(
        children: [
          // 최근 사용 코스
          _buildDeviceLog(),
          _buildDevider(),
          // 낮잠/밤잠 이력 (API 연동)
          FutureBuilder<List<Map<String, dynamic>>>(
            future: fetchLatestSleepLogs(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return const Text('에러 발생');
              } else {
                final data = snapshot.data ?? [];
                final latestDay = data
                    .where((d) => d['sleep_mode'].toString().contains('낮잠'))
                    .toList()
                    .reversed
                    .firstWhere((_) => true, orElse: () => {});
                final latestNight = data
                    .where((d) => d['sleep_mode'].toString().contains('밤잠'))
                    .toList()
                    .reversed
                    .firstWhere((_) => true, orElse: () => {});

                String formatKoreanTime(String? raw) {
                  if (raw == null) return '시간 없음';
                  try {
                    final dt = HttpDate.parse(
                      raw,
                    ).toLocal(); // Convert RFC 1123 to DateTime
                    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
                    final period = dt.hour < 12 ? '오전' : '오후';
                    final minute = dt.minute.toString().padLeft(2, '0');
                    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')} $period $hour:$minute';
                  } catch (e) {
                    return '날짜 오류';
                  }
                }

                return Column(
                  children: [
                    _buildDeviceLogItem(
                      image: 'assets/images/eggie_day_sleep.png',
                      title: '낮잠',
                      date: latestDay.isNotEmpty
                          ? formatKoreanTime(latestDay['recorded_at'])
                          : '기록 없음',
                    ),
                    const _buildDevider(),
                    _buildDeviceLogItem(
                      image: 'assets/images/eggie_night_sleep.png',
                      title: '밤잠',
                      date: latestNight.isNotEmpty
                          ? formatKoreanTime(latestNight['recorded_at'])
                          : '기록 없음',
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _buildDevider extends StatelessWidget {
  const _buildDevider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, color: Color(0xFFEFF1F4));
  }
}

class _buildDeviceLog extends StatelessWidget {
  const _buildDeviceLog({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const CurrentLogPage(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            const Text(
              '최근 사용 코스',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
            ),
            const Spacer(),
            SvgPicture.asset(
              'assets/icons/arrowsmall_right.svg',
              width: 20,
              height: 20,
              color: Color(0xFF606C80),
            ),
          ],
        ),
      ),
    );
  }
}

class _buildDeviceStatus extends StatefulWidget {
  const _buildDeviceStatus({super.key});

  @override
  State<_buildDeviceStatus> createState() => _buildDeviceStatusState();
}

class _buildDeviceStatusState extends State<_buildDeviceStatus> {
  // 디바이스를 켤 때 상태 저장
  Future<void> _turnOnDevice() async {
    final prefs = await SharedPreferences.getInstance();

    // 디바이스 켜짐 상태 저장
    await prefs.setBool('device_on', true);

    // 이전 수면 데이터 초기화 (새로운 세션 시작)
    await prefs.remove('sleep_end_time');
    await prefs.remove('sleep_end_time_korean');

    print('Device turned on and previous sleep data cleared');

    // mode_off 페이지로 이동
    if (mounted) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const ModeOffPage(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '전원 꺼짐',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          IconButton(
            icon: SvgPicture.asset(
              'assets/icons/power_solid.svg',
              width: 48,
              height: 48,
            ),
            onPressed: _turnOnDevice, // 상태 저장 후 페이지 이동
          ),
        ],
      ),
    );
  }
}

class _buildDeviceLogItem extends StatelessWidget {
  final String image;
  final String title;
  final String date;

  const _buildDeviceLogItem({
    super.key,
    required this.image,
    required this.title,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Image.asset(image, height: 40, width: 40),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF606C80),
                  ),
                ),
              ],
            ),
            const Spacer(),
            SvgPicture.asset(
              'assets/icons/arrowsmall_right.svg',
              width: 20,
              height: 20,
              color: Color(0xFF606C80),
            ),
          ],
        ),
      ),
    );
  }
}

PreferredSizeWidget _buildEggieTopBar(BuildContext context) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(100), // 높이 조정 가능
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
