import 'package:eggie2/pages/sleep_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime currentDate = DateTime(2025, 6, 1);
  bool _isBadgeWidgetExpanded = false;

  // 베이비 마일스톤 데이터 (날짜별로 아이콘 할당)
  late Map<int, String> milestones;

  @override
  void initState() {
    super.initState();
    _generateRandomMilestones();
  }

  String? _getBabyAge(int month) {
    switch (month) {
      case 1:
        return null; // 1월은 null
      case 2:
        return '0개월';
      case 3:
        return '1개월';
      case 4:
        return '2개월';
      case 5:
        return '3개월';
      case 6:
        return '4개월';
      case 7:
        return '5개월';
      default:
        return null;
    }
  }

  void _generateRandomMilestones() {
    final random = Random();
    final sleepIcons = [
      'sleep_log_circle_1',
      'sleep_log_circle_2',
      'sleep_log_circle_3',
      'sleep_log_circle_4',
      'sleep_log_circle_5',
      'sleep_log_circle_6',
    ];

    milestones = {};

    // 월별로 다른 마일스톤 설정
    switch (currentDate.month) {
      case 1:
        // 1월: 모든 칸 빈칸
        break;
      case 2:
        // 2월: 1일~24일은 빈칸, 25일부터 마지막 날까지 랜덤 아이콘
        final daysInMonth = DateTime(
          currentDate.year,
          currentDate.month + 1,
          0,
        ).day;
        for (int day = 25; day <= daysInMonth; day++) {
          milestones[day] = sleepIcons[random.nextInt(sleepIcons.length)];
        }
        break;
      case 3:
      case 4:
        // 3월~4월: 모든 날짜에 랜덤 아이콘
        final daysInMonth = DateTime(
          currentDate.year,
          currentDate.month + 1,
          0,
        ).day;
        for (int day = 1; day <= daysInMonth; day++) {
          milestones[day] = sleepIcons[random.nextInt(sleepIcons.length)];
        }
        break;
      case 5:
        // 5월: 모든 날짜에 랜덤 아이콘, 16일은 baby_headup 이미지
        final daysInMonth = DateTime(
          currentDate.year,
          currentDate.month + 1,
          0,
        ).day;
        for (int day = 1; day <= daysInMonth; day++) {
          if (day == 16) {
            milestones[day] = 'baby_headup'; // 특별한 경우
          } else {
            milestones[day] = sleepIcons[random.nextInt(sleepIcons.length)];
          }
        }
        break;
      case 6:
        // 6월: 기존 설정 유지 (일부 날짜만 아이콘 + first_roll)
        milestones = {
          1: sleepIcons[random.nextInt(sleepIcons.length)],
          2: sleepIcons[random.nextInt(sleepIcons.length)],
          3: sleepIcons[random.nextInt(sleepIcons.length)],
          4: 'first_roll', // 특별한 경우
          5: sleepIcons[random.nextInt(sleepIcons.length)],
          6: sleepIcons[random.nextInt(sleepIcons.length)],
          7: sleepIcons[random.nextInt(sleepIcons.length)],
          8: sleepIcons[random.nextInt(sleepIcons.length)],
        };
        break;
      case 7:
        // 7월: 모든 칸 빈칸 (milestones 비워둠)
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDF2F4),
      appBar: _buildTopBar(context, title: '육아 캘린더'),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 16),
              _buildMonthNavigation(),
              const SizedBox(height: 24),
              _buildCalendarGrid(),
              const SizedBox(height: 16),
              // 1월이 아닐 때만 BadgeWidget 표시
              if (currentDate.month != 1) _buildBadgeWidget(),
              if (currentDate.month != 1) const SizedBox(height: 40),
              // 1월일 때는 다른 간격 적용
              if (currentDate.month == 1) const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthNavigation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () {
            // 2025년 1월보다 이전으로 갈 수 없도록 제한
            if (currentDate.year == 2025 && currentDate.month <= 1) return;

            setState(() {
              currentDate = DateTime(
                currentDate.year,
                currentDate.month - 1,
                1,
              );
              _generateRandomMilestones(); // 월 변경 시 새로운 랜덤 아이콘 생성
            });
          },
          icon: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF4A5568),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.chevron_left,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        const Spacer(),
        Column(
          children: [
            Text(
              '${currentDate.year}년 ${currentDate.month}월',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                height: 28 / 20,
                color: Color(0xFF111111),
              ),
            ),
            if (_getBabyAge(currentDate.month) != null)
              Text(
                _getBabyAge(currentDate.month)!,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF606C80),
                  height: 24 / 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
        const Spacer(),
        IconButton(
          onPressed: () {
            // 2025년 7월보다 이후로 갈 수 없도록 제한
            if (currentDate.year == 2025 && currentDate.month >= 7) return;

            setState(() {
              currentDate = DateTime(
                currentDate.year,
                currentDate.month + 1,
                1,
              );
              _generateRandomMilestones(); // 월 변경 시 새로운 랜덤 아이콘 생성
            });
          },
          icon: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF4A5568),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.chevron_right,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              _buildWeekHeader(),
              const SizedBox(height: 16),
              _buildCalendarDays(),
            ],
          ),
          // 원더윅스 바 오버레이
          _buildWonderWeeksBar(),
        ],
      ),
    );
  }

  Widget _buildWeekHeader() {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Row(
      children: weekdays
          .map(
            (day) => Expanded(
              child: Center(
                child: Text(
                  day,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF606C80),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildCalendarDays() {
    final firstDayOfMonth = DateTime(currentDate.year, currentDate.month, 1);
    final lastDayOfMonth = DateTime(currentDate.year, currentDate.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;

    // 이전 달의 마지막 며칠
    final previousMonth = DateTime(currentDate.year, currentDate.month - 1, 0);
    final daysFromPreviousMonth = firstWeekday - 1;

    List<Widget> dayWidgets = [];

    // 이전 달 날짜들
    for (int i = daysFromPreviousMonth; i > 0; i--) {
      final day = previousMonth.day - i + 1;
      dayWidgets.add(_buildDayCell(day, isCurrentMonth: false));
    }

    // 현재 달 날짜들
    for (int day = 1; day <= daysInMonth; day++) {
      dayWidgets.add(_buildDayCell(day, isCurrentMonth: true));
    }

    // 다음 달 날짜들 (6주 완성을 위해)
    final remainingCells = 42 - dayWidgets.length;
    for (int day = 1; day <= remainingCells; day++) {
      dayWidgets.add(_buildDayCell(day, isCurrentMonth: false));
    }

    // 6주로 나누기
    List<Widget> weeks = [];
    for (int i = 0; i < 6; i++) {
      weeks.add(Row(children: dayWidgets.sublist(i * 7, (i + 1) * 7)));
      if (i < 5) weeks.add(const SizedBox(height: 8));
    }

    return Column(children: weeks);
  }

  Widget _buildDayCell(int day, {required bool isCurrentMonth}) {
    final hasMilestone = isCurrentMonth && milestones.containsKey(day);
    final isFirstRoll = isCurrentMonth && milestones[day] == 'first_roll';
    final isBabyHeadUp = isCurrentMonth && milestones[day] == 'baby_headup';

    return Expanded(
      child: Container(
        height: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 날짜 텍스트 (위쪽에 배치)
            Text(
              day.toString(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isCurrentMonth
                    ? const Color(0xFF111111)
                    : const Color(0xFFBEC1C1),
              ),
            ),

            const SizedBox(height: 2),

            // 아이콘/이미지 (아래쪽에 배치)
            if (hasMilestone)
              Container(
                width: (isFirstRoll || isBabyHeadUp) ? 35 : 34,
                height: (isFirstRoll || isBabyHeadUp) ? 35 : 34,
                child: isFirstRoll
                    ? Image.asset(
                        'assets/images/baby_firstroll.png',
                        width: 35,
                        height: 35,
                        fit: BoxFit.contain,
                      )
                    : isBabyHeadUp
                    ? Image.asset(
                        'assets/images/baby_headup.png',
                        width: 35,
                        height: 35,
                        fit: BoxFit.contain,
                      )
                    : SvgPicture.asset(
                        'assets/icons/${milestones[day]}.svg',
                        width: 32,
                        height: 32,
                        fit: BoxFit.contain,
                      ),
              )
            else
              const SizedBox(height: 32), // 공간 유지를 위한 빈 공간
          ],
        ),
      ),
    );
  }

  PreferredSize _buildTopBar(BuildContext context, {required String title}) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(100),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 60, left: 8, right: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
                color: const Color(0xFF606C80),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111111),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWonderWeeksBar() {
    // 6월이 아닌 경우 원더윅스 바를 표시하지 않음
    if (currentDate.month != 6) {
      return const SizedBox.shrink();
    }

    // 16일이 포함된 주를 찾기 위한 계산
    final firstDayOfMonth = DateTime(currentDate.year, currentDate.month, 1);
    final firstWeekday = firstDayOfMonth.weekday;
    final daysFromPreviousMonth = firstWeekday - 1;

    // 16일의 위치 계산 (0-based index)
    final day16Position = daysFromPreviousMonth + 16 - 1;
    final weekRow = day16Position ~/ 7; // 몇 번째 주인지
    final dayInWeek = day16Position % 7; // 주 내에서 몇 번째 날인지

    // 위치 계산 - 주 사이의 간격 중간에 배치
    final topOffset =
        50.0 + // 헤더 높이
        16.0 + // 헤더와 캘린더 사이 간격
        (weekRow * 68.0) + // 이전 주들의 높이 (60 + 8)
        64.0 + // 현재 주의 날짜 칸 높이
        4.0; // 주 사이 간격(8px)의 중간

    final leftOffset =
        16.0 + (dayInWeek * (MediaQuery.of(context).size.width - 64) / 7);
    final barWidth =
        ((MediaQuery.of(context).size.width - 64) / 7) * 4; // 4일간 (16-19일)

    return Positioned(
      top: topOffset,
      left: leftOffset,
      child: Container(
        width: barWidth,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFF2C92B4),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Text(
            '원더윅스 예상 시기',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeWidget() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
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
                _isBadgeWidgetExpanded = !_isBadgeWidgetExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  Text(
                    '${currentDate.month >= 6 ? '4~6개월' : '0~3개월'} 발달 행동 배지',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF606C80),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isBadgeWidgetExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: Color(0xFF606C80),
                  ),
                ],
              ),
            ),
          ),
          if (_isBadgeWidgetExpanded)
            if (currentDate.month >= 6)
              _buildBadge4to6()
            else if (currentDate.month >= 2)
              _buildBadge0to3()
            else
              const SizedBox.shrink(),
        ],
      ),
    );
  }

  Padding _buildBadge4to6() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 뒤집기 배지
          Column(
            children: [
              Image.asset(
                'assets/images/baby_firstroll.png',
                width: 88,
                height: 88,
                fit: BoxFit.fill,
              ),
              GestureDetector(
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
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Color(0xFF4A57BF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '6월 4일',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      height: 18 / 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
          _buildBadgeAdd(image: 'assets/images/baby_grab.png'),
          _buildBadgeAdd(image: 'assets/images/baby_mumbling.png'),
        ],
      ),
    );
  }

  Padding _buildBadge0to3() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 머리 들기 배지
          Column(
            children: [
              Image.asset(
                'assets/images/baby_headup.png',
                width: 88,
                height: 88,
                fit: BoxFit.fill,
              ),
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Color(0xFF4A57BF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '5월 16일',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      height: 18 / 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
          _buildBadgeAdd(image: 'assets/images/baby_hand.png'),
          _buildBadgeAdd(image: 'assets/images/baby_sound.png'),
        ],
      ),
    );
  }

  Column _buildBadgeAdd({required String image}) {
    return Column(
      children: [
        Opacity(
          opacity: 0.25, // 0.0 ~ 1.0 사이 값으로 투명도 조절
          child: Image.asset(image, width: 88, height: 88, fit: BoxFit.fill),
        ),
        GestureDetector(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Color(0xFFD5DBFF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '직접 추가',
              style: TextStyle(
                color: Color(0xFF4A57BF),
                fontSize: 11,
                fontWeight: FontWeight.w500,
                height: 18 / 11,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
