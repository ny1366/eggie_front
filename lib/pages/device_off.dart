import 'package:eggie2/pages/device_current_log.dart';
import 'package:eggie2/pages/device_page.dart';
import 'package:eggie2/pages/mode_off.dart';
import 'package:eggie2/pages/sleep_log.dart';
import 'package:eggie2/pages/useful_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

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

          if (_isTodayLogExpanded) ...[
            // 낮잠 1
            _buildTodayLogItem(
              title: '낮잠 1',
              timeRange: '오전 9:30  -  오전 10:40',
            ),

            _buildDevider(),

            // 낮잠 2
            _buildTodayLogItem(title: '낮잠 2', timeRange: '오후 1:32  -  오후 3:00'),
          ],
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
          // 낮잠 이력
          // 👉🏻 여기도 데이터 반영 필요해요
          _buildDeviceLogItem(
            image: 'assets/images/eggie_day_sleep.png',
            title: '낮잠',
            date: '2025.05.23 오전 11:12',
          ),
          _buildDevider(),
          // 👉🏻 여기도 데이터 반영 필요해요
          _buildDeviceLogItem(
            image: 'assets/images/eggie_night_sleep.png',
            title: '밤잠',
            date: '2025.05.22 오후 9:08',
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
          MaterialPageRoute(builder: (context) => const CurrentLogPage()),
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

class _buildDeviceStatus extends StatelessWidget {
  const _buildDeviceStatus({super.key});

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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ModeOffPage()),
              );
            },
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
