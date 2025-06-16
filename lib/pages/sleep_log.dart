import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../services/api.dart';
import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter_svg/svg.dart';
import 'package:share_plus/share_plus.dart';

class TodaySleepLogPage extends StatefulWidget {
  const TodaySleepLogPage({super.key});

  @override
  State<TodaySleepLogPage> createState() => _TodaySleepLogPageState();
}

class _TodaySleepLogPageState extends State<TodaySleepLogPage> {
  // AI 피드백 확장 상태 변수
  bool _isAIFeedbackExpanded = false;

  // 선택된 수면 바 정보를 저장하는 변수
  Map<String, dynamic>? selectedSleepData;

  // 오늘의 수면 데이터 (API)
  Map<String, dynamic>? todaySleepData;
  bool isLoading = false;
  String? errorMessage;

  // 👉🏻👉🏻👉🏻 공통 수면 데이터 - TODO: 실제 DB 데이터로 교체 예정
  final List<Map<String, String>> _allActualSleepData = [
    {
      'startTime': '06:28',
      'endTime': '08:22',
      'sleepTitle': '낮잠 1',
      'wakeCounts': '1',
    },
    {
      'startTime': '12:00',
      'endTime': '12:45',
      'sleepTitle': '낮잠 2',
      'wakeCounts': '1',
    },
    {
      'startTime': '19:45',
      'endTime': '20:30',
      'sleepTitle': '낮잠 3',
      'wakeCounts': '1',
    },
    {
      'startTime': '21:30',
      'endTime': '00:00',
      'sleepTitle': '밤잠 1',
      'wakeCounts': '1',
    },
    {
      'startTime': '02:00',
      'endTime': '04:18',
      'sleepTitle': '밤잠 2',
      'wakeCounts': '1',
    },
  ];

  final List<Map<String, String>> _allExpectedSleepData = [
    {'startTime': '06:20', 'endTime': '08:20', 'sleepTitle': '낮잠 1'},
    {'startTime': '12:10', 'endTime': '12:45', 'sleepTitle': '낮잠 2'},
    {'startTime': '19:40', 'endTime': '20:20', 'sleepTitle': '낮잠 3'},
    {'startTime': '21:22', 'endTime': '00:00', 'sleepTitle': '밤잠 1'},
    {'startTime': '02:00', 'endTime': '04:10', 'sleepTitle': '밤잠 2'},
  ];

  final List<String> _allWakeTimesData = [
    '07:55', '08:12', '12:20', // 낮잠 시간대
    '22:30', '23:15', '02:05', '02:15', // 밤잠 시간대
  ];

  // 👉🏻👉🏻👉🏻 API에서 받아올 수면 요약 데이터 변수 선언
  String _totalSleepTime = '0시간 00분';
  String _napSleepTime = '0시간 0분';
  int _napSleepCount = 0;
  String _nightSleepTime = '0시간 0분';
  int _nightSleepCount = 0;

  // 선택된 날짜 (API startDt) - 테스트용 하드코딩 날짜 사용 중
  // String _selectedStartDt = '2024-09-16';
  String _selectedStartDt = '';

  // 날짜 문자열을 한국어 형식 (YYYY.MM.DD 요일요일)으로 변환
  String _formatKoreanDate(String dateStr) {
    DateTime date = DateTime.parse(dateStr);
    String weekdayKorean = ['월', '화', '수', '목', '금', '토', '일'][date.weekday - 1];
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} $weekdayKorean요일';
  }

  // 수면 시간 문자열을 분 단위로 변환하는 헬퍼 메서드
  int _parseSleepTimeToMinutes(String sleepTimeString) {
    int totalMinutes = 0;

    // "3시간 24분", "4시간", "45분" 등의 형태를 파싱
    RegExp hourRegex = RegExp(r'(\d+)시간');
    RegExp minuteRegex = RegExp(r'(\d+)분');

    var hourMatch = hourRegex.firstMatch(sleepTimeString);
    var minuteMatch = minuteRegex.firstMatch(sleepTimeString);

    if (hourMatch != null) {
      totalMinutes += int.parse(hourMatch.group(1)!) * 60;
    }

    if (minuteMatch != null) {
      totalMinutes += int.parse(minuteMatch.group(1)!);
    }

    return totalMinutes;
  }
  
  // 시간 문자열을 시와 분으로 파싱하는 헬퍼 메서드
  String _formatTime(String isoDateTimeStr) {
    DateTime dt = DateTime.parse(isoDateTimeStr);
    return DateFormat('HH:mm').format(dt);
  }

  // null 허용 버전 추가
  String _formatTimeNullable(String? isoDateTimeStr) {
    if (isoDateTimeStr == null) {
      return '';
    }
    DateTime dt = DateTime.parse(isoDateTimeStr);
    return DateFormat('HH:mm').format(dt);
  }

  // 수면 시작 시각에 따라 낮잠/밤잠 라벨을 계산하는 헬퍼 메서드
  String _computeSleepModeLabel(DateTime startTime) {
    int hour = startTime.hour;
    if (hour >= 6 && hour < 20) {
      return '낮잠';
    } else {
      return '밤잠';
    }
  }

  // 낮잠 시간에 따른 조건부 메시지 생성
  String _getNapFeedbackMessage() {
    int napMinutes = _parseSleepTimeToMinutes(_napSleepTime);
    int threeHours = 3 * 60; // 180분
    int fourHours = 4 * 60; // 240분

    if (napMinutes < threeHours) {
      return '삼희의 오늘 낮잠 시간은 $_napSleepTime으로, 권장 시간보다 적게 잤네요. 조금 늘려봐도 좋아요!';
    } else if (napMinutes <= fourHours) {
      return '삼희의 오늘 낮잠 시간은 $_napSleepTime으로, 딱 알맞게 잤어요!';
    } else {
      return '삼희의 오늘 낮잠 시간은 $_napSleepTime으로, 권장 시간보다 많이 잤네요! 조금 줄여봐도 좋아요!';
    }
  }


  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _selectedStartDt = '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    selectedSleepData = null;
    _loadTodaySleepDetailData();
  }

  // (삭제됨) _loadTodaySleepData
  
  // today-sleep-detail-data API 호출
  Future<void> _loadTodaySleepDetailData() async {
    try {
      final babyId = 6;
      final data = await SleepApiService.getTodaySleepDetailData(babyId, startDt: _selectedStartDt);

      // data is Map<String, dynamic>
      final sleepRecords = (data['sleepRecords'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      List<Map<String, String>> actualSleepData = [];
      List<Map<String, String>> expectedSleepData = [];
      List<String> wakeTimesData = [];

      for (var item in sleepRecords) {
        // item is Map<String, dynamic>
        actualSleepData.add({
          'startTime': _formatTime(item['startTime'] as String? ?? ''),
          'endTime': _formatTime(item['endTime'] as String? ?? ''),
          'sleepTitle': '${((item['sleepMode'] as String? ?? '') == 'night' ? '밤잠' : '낮잠')} ${(item['sleepModeSeq'] as int? ?? 0).toString()}',
          'sleepMode': item['sleepMode'] as String? ?? '',
          'sleepModeSeq': (item['sleepModeSeq'] as int? ?? 0).toString(),
          'actualStartTime': _formatTime(item['startTime'] as String? ?? ''),
          'wakeCounts': (item['wakeCounts'] as int? ?? 0).toString(),
        });

        if ((item['expectedStartAt'] as String?) != null && (item['expectedEndAt'] as String?) != null) {
          expectedSleepData.add({
            'startTime': _formatTimeNullable(item['expectedStartAt'] as String?),
            'endTime': _formatTimeNullable(item['expectedEndAt'] as String?),
            'sleepTitle': '${((item['sleepMode'] as String? ?? '') == 'night' ? '밤잠' : '낮잠')} ${(item['sleepModeSeq'] as int? ?? 0).toString()}',
            'sleepMode': item['sleepMode'] as String? ?? '',
            'sleepModeSeq': (item['sleepModeSeq'] as int? ?? 0).toString(),
            'actualStartTime': _formatTime(item['startTime'] as String? ?? ''),
          });
        }

        int wakeCount = item['wakeCounts'] as int? ?? 0;
        if (wakeCount > 0) {
          wakeTimesData.add(_formatTime(item['endTime'] as String? ?? ''));
        }
      }

      setState(() {
        _allActualSleepData.clear();
        _allActualSleepData.addAll(actualSleepData);

        _allExpectedSleepData.clear();
        _allExpectedSleepData.addAll(expectedSleepData);

        _allWakeTimesData.clear();
        _allWakeTimesData.addAll(wakeTimesData);

        // Update summary data from API response
        _totalSleepTime = data['totalSleepDuration'] ?? '0시간 0분';
        _napSleepTime = data['napDuration'] ?? '0시간 0분';
        _napSleepCount = data['napCount'] ?? 0;
        _nightSleepTime = data['nightDuration'] ?? '0시간 0분';
        _nightSleepCount = data['nightCount'] ?? 0;
      });
    } catch (e) {
      print('Error loading today sleep detail data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDF2F4),
      appBar: _buildTopBar(
        context,
        title: _formatKoreanDate(_selectedStartDt),
      ), // 👉🏻👉🏻👉🏻 지정한 날짜 or 오늘 날짜로 교체 완료
        

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            // Center(
            //   child: Image.asset(
            //     "assets/images/baby_firstroll.png",
            //     width: 180,
            //     height: 180,
            //   ),
            // ),
            const SizedBox(height: 24),
            _buildWidgetTitle(text: '오늘 수면 요약'),
            const SizedBox(height: 8),
            _buildSleepSummaryWidget(),
            const SizedBox(height: 8),
            _buildAIFeedbackWidget(),
            const SizedBox(height: 24),
            _buildWidgetTitle(text: '타임라인'),
            const SizedBox(height: 8),
            // 타임라인 카드
            _buildTimelineCard(),
            const SizedBox(height: 16),
            // 선택된 수면 바가 있을 때만 세부 카드 표시
            if (selectedSleepData != null)
              _buildTimelineDetailCard(
                selectedSleepData!['sleepTitle'],
                selectedSleepData!['actualStartTime'],
                selectedSleepData!['actualEndTime'],
                selectedSleepData!['expectedStartTime'],
                selectedSleepData!['expectedEndTime'],
                selectedSleepData!['wakeCounts'],
              ),
            if (selectedSleepData != null) const SizedBox(height: 24),
            _buildWidgetTitle(text: '일기'),
            const SizedBox(height: 8),
            _buildDiaryCard(),
            const SizedBox(height: 70),
          ],
        ),
      ),
    );
  }

  Container _buildTimelineCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFF1F4)),
      ),
      child: Column(
        children: [
          // 낮잠 타임라인 Top Bar 영역
          _buildTimelineTopBar(
            image: 'assets/images/eggie_day_sleep.png',
            text: '낮잠',
            colorchip_real: Color(0xFFFF8827),
            colorchip_expected: Color(0xFFFFD1AC),
          ),
          const SizedBox(height: 16),
          // 낮잠 타임라인 가로 스크롤 영역
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                // 낮잠 타임라인 (오전 6시 ~ 오후 8시)
                _buildNapTimeline(),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildDevider(),
          ),
          const SizedBox(height: 16),

          // 밤잠 타임라인 Top Bar 영역
          _buildTimelineTopBar(
            image: 'assets/images/eggie_night_sleep.png',
            text: '밤잠',
            colorchip_real: Color(0xFF5D73D9),
            colorchip_expected: Color(0xFFB8C4F0),
          ),
          const SizedBox(height: 16),
          // 밤잠 타임라인 가로 스크롤 영역
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                // 밤잠 타임라인 (오후 8시 ~ 오전 6시)
                _buildNightTimeline(),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Container _buildTimelineTopBar({
    required String image,
    required String text,
    required Color colorchip_real,
    required Color colorchip_expected,
  }) {
    return Container(
      padding: const EdgeInsets.only(top: 16, left: 16, right: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(image, width: 40, height: 40),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xFF606C80),
            ),
          ),
          const Spacer(),
          _buildColorChip(colorchip: colorchip_real),
          const SizedBox(width: 8),
          Text(
            '실제',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF606C80),
            ),
          ),
          const SizedBox(width: 16),
          _buildColorChip(colorchip: colorchip_expected),
          const SizedBox(width: 8),
          Text(
            '예상',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF606C80),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepSummaryWidget() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (errorMessage != null) {
      return Center(child: Text(errorMessage!));
    }
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
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                const Text(
                  '전체 수면 시간',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF111111),
                    height: 24 / 16,
                  ),
                ),
                const Spacer(),
                Text(
                  _totalSleepTime,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF111111),
                    height: 24 / 16,
                  ),
                ),
              ],
            ),
          ),
          _buildDevider(),
          _buildSleepSummaryItem(
            icon: 'assets/images/eggie_day_sleep.png',
            text: '낮잠',
            value_time: _napSleepTime,
            value_counts: _napSleepCount.toString(),
          ),
          _buildDevider(),
          _buildSleepSummaryItem(
            icon: 'assets/images/eggie_night_sleep.png',
            text: '밤잠',
            value_time: _nightSleepTime,
            value_counts: _nightSleepCount.toString(),
          ),
        ],
      ),
    );
  }

  Container _buildDiaryCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFF1F4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            height: 126,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/images/homecam.png',
                    width: double.infinity,
                    height: 126,
                    fit: BoxFit.cover,
                  ),
                ),
                SvgPicture.asset(
                  'assets/icons/video_play.svg',
                  width: 40,
                  height: 40,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: const Text(
              '울아가 오늘 수유량이 넘 적고 낮잠은 많았다. 드디어 낮잠 중에 뒤집기를 성공했다! 울아가 첫 뒤집기 축하해애~ 천재인가봐~',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                height: 24 / 16,
                color: Color(0xFF111111),
              ),
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
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
                  '사진 추가',
                  style: TextStyle(
                    color: Color(0xFF4A57BF),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    height: 18 / 11,
                  ),
                ),
              ),
              SizedBox(width: 8),
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
                  '홈캠 영상 추가',
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
        ],
      ),
    );
  }

  Padding _buildWidgetTitle({required String text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF606C80),
          fontWeight: FontWeight.w400,
          height: 24 / 12,
        ),
      ),
    );
  }

  // 낮잠 타임라인 구현 (오전 6시 ~ 오후 8시)
  Widget _buildNapTimeline() {
    return SizedBox(
      height: 120, // 타임라인 전체 높이
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 14 * 80.0, // 14시간 * 80px = 1120px
          child: Stack(
            children: [
              // 레이어 1: 시간 텍스트 + 점선
              _buildTimeLabelsAndLines(),
              // 레이어 2: 실제/예상 수면 시간 색상 컴포넌트
              _buildSleepBars(),
              // 레이어 3: 수면 중 깬 시각을 표시하는 흰색 선
              _buildWakeMarkers(),
            ],
          ),
        ),
      ),
    );
  }

  // 시간 텍스트와 점선 구현
  Widget _buildTimeLabelsAndLines() {
    return Column(
      children: [
        // 시간 텍스트 영역
        SizedBox(
          height: 40,
          child: Stack(
            children: [
              // 1시간 간격 시간 텍스트
              ...List.generate(15, (index) {
                int hour = 6 + index;
                String timeLabel = hour <= 12
                    ? '오전 ${hour}시'
                    : hour == 24
                    ? '오전 12시'
                    : '오후 ${hour - 12}시';

                return Positioned(
                  left: index * 80.0 - 5.0,
                  top: 0,
                  child: SizedBox(
                    width: 60,
                    child: Text(
                      timeLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF606C80),
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        // 점선 영역
        Expanded(
          child: Stack(
            children: [
              // 30분 간격 점선
              ...List.generate(28, (index) {
                double left = index * 40.0;
                bool isHourLine = index % 2 == 0;

                return Positioned(
                  left: left,
                  top: 0,
                  bottom: 0,
                  child: DottedBorder(
                    padding: EdgeInsets.zero,
                    strokeWidth: 1,
                    dashPattern: isHourLine ? [1, 0] : [4, 4], // 실선 또는 점선
                    color: const Color(0xFFEFF1F4),
                    customPath: (size) => Path()
                      ..moveTo(0, 0)
                      ..lineTo(0, size.height),
                    child: SizedBox(
                      width: 1,
                      height: double.infinity, // 중요: 선이 길게 보이게 만듦
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  // 수면 시간 막대 구현 (실제/예상) - 2열 구조
  Widget _buildSleepBars() {
    return Positioned(
      top: 46,
      left: 0,
      right: 0,
      height: 98,
      child: Stack(
        children: [
          // 상단 행: 실제 수면 시간 (진한 오렌지)
          ..._buildActualNapBars(),

          // 하단 행: 예상 수면 시간 (연한 오렌지)
          ..._buildExpectedNapBars(),
        ],
      ),
    );
  }

  // 예상 낮잠 수면 시간 막대들 (하단 행)
  List<Widget> _buildExpectedNapBars() {
    var splitData = _splitSleepRecords(_allExpectedSleepData);
    List<Map<String, dynamic>> expectedNapData = splitData['nap']!;

    return expectedNapData.map((data) {
      var startTime = _parseTime(data['startTime']!);
      var endTime = _parseTime(data['endTime']!);

      double left = _timeToPixel(
        startTime['hour']!,
        startTime['minute']!,
        6,
      ); // 오전 6시 기준
      double width =
          _timeToPixel(endTime['hour']!, endTime['minute']!, 6) - left;

      return _buildSleepBar(
        left: left,
        width: width,
        color: const Color(0xFFFFD1AC),
        height: 32, // 2열 구조를 위해 높이 조정
        top: 36, // 하단 행
        isStartTruncated: data['isStartTruncated'] as bool,
        isEndTruncated: data['isEndTruncated'] as bool,
      );
    }).toList();
  }

  // 실제 낮잠 수면 시간 막대들 (상단 행)
  // 수면 데이터 적용된 영역
  List<Widget> _buildActualNapBars() {
    var splitData = _splitSleepRecords(_allActualSleepData);
  List<Map<String, dynamic>> actualNapData = splitData['nap'] ?? [];

    return actualNapData.asMap().entries.map((entry) {
      int index = entry.key;
      Map<String, dynamic> data = entry.value;

      var startTime = _parseTime(data['startTime']!);
      var endTime = _parseTime(data['endTime']!);

      double left = _timeToPixel(
        startTime['hour']!,
        startTime['minute']!,
        6,
      ); // 오전 6시 기준
      double width =
          _timeToPixel(endTime['hour']!, endTime['minute']!, 6) - left;

      // sleepTitle은 이미 data에 포함되어 있음
      String sleepTitle = data['sleepTitle'] ?? '';

      // 매칭되는 예상 데이터 찾기
      String expectedStartTime = '';
      String expectedEndTime = '';
      for (var expectedData in _allExpectedSleepData) {
        if (expectedData['sleepTitle'] == sleepTitle &&
            expectedData['actualStartTime'] == data['startTime']) {
          expectedStartTime = expectedData['startTime']!;
          expectedEndTime = expectedData['endTime']!;
          break;
        }
      }

      return _buildClickableSleepBar(
        left: left,
        width: width,
        color: const Color(0xFFFF8827),
        height: 32,
        top: 0, // 상단 행
        isStartTruncated: data['isStartTruncated'] as bool,
        isEndTruncated: data['isEndTruncated'] as bool,
        sleepData: {
          'sleepTitle': sleepTitle,
          'actualStartTime': data['startTime']!,
          'actualEndTime': data['endTime']!,
          'expectedStartTime': expectedStartTime,
          'expectedEndTime': expectedEndTime,
          'wakeCounts': data['wakeCounts'] ?? '',
          'sleepMode': data['sleepMode'],
        },
      );
    }).toList();
  }

  // 개별 수면 막대 위젯
  Widget _buildSleepBar({
    required double left,
    required double width,
    required Color color,
    required double height,
    required double top,
    required bool isStartTruncated,
    required bool isEndTruncated,
  }) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isStartTruncated ? 0 : 20),
            bottomLeft: Radius.circular(isStartTruncated ? 0 : 20),
            topRight: Radius.circular(isEndTruncated ? 0 : 20),
            bottomRight: Radius.circular(isEndTruncated ? 0 : 20),
          ),
        ),
      ),
    );
  }

  // 클릭 가능한 수면 막대 위젯
  Widget _buildClickableSleepBar({
    required double left,
    required double width,
    required Color color,
    required double height,
    required double top,
    required bool isStartTruncated,
    required bool isEndTruncated,
    required Map<String, String> sleepData,
  }) {
    bool isSelected =
        selectedSleepData != null &&
        selectedSleepData!['sleepTitle'] == sleepData['sleepTitle'] &&
        selectedSleepData!['actualStartTime'] == sleepData['actualStartTime'];

    return Positioned(
      left: left,
      top: top,
      child: Stack(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  selectedSleepData = null; // 이미 선택된 경우 선택 해제
                } else {
                  selectedSleepData = sleepData; // 새로운 수면 바 선택
                }
              });
            },
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isStartTruncated ? 0 : 20),
                  bottomLeft: Radius.circular(isStartTruncated ? 0 : 20),
                  topRight: Radius.circular(isEndTruncated ? 0 : 20),
                  bottomRight: Radius.circular(isEndTruncated ? 0 : 20),
                ),
              ),
            ),
          ),
          // 선택된 수면 바에 아이콘 표시
          if (isSelected)
            Positioned(
              left: 14,
              top: height / 2 - 8, // 아이콘을 수면 바 중앙에 배치
              child: SvgPicture.asset(
                sleepData['sleepMode'] == 'night'
                    ? 'assets/icons/bar_clicked_night.svg'
                    : 'assets/icons/bar_clicked_day.svg',
                width: 16,
                height: 16,
              ),
            ),
        ],
      ),
    );
  }

  // 수면 중 깬 시각 표시 (흰색 선) - 낮잠용
  Widget _buildWakeMarkers() {
    var splitWakeTimes = _splitWakeTimes(_allWakeTimesData);
    List<String> napWakeTimesData = splitWakeTimes['nap']!;

    return Stack(
      children: napWakeTimesData.map((timeString) {
        var time = _parseTime(timeString);
        double left = _timeToPixel(time['hour']!, time['minute']!, 6);
        return _buildWakeMarker(left: left);
      }).toList(),
    );
  }

  // 개별 깬 시각 마커
  Widget _buildWakeMarker({required double left}) {
    return Positioned(
      left: left,
      top: 46,
      child: Container(width: 1, height: 32, color: const Color(0xFFEDF2F4)),
    );
  }

  // 밤잠 타임라인 구현 (오후 8시 ~ 오전 6시)
  Widget _buildNightTimeline() {
    return SizedBox(
      height: 120, // 타임라인 전체 높이
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 10 * 80.0, // 10시간 * 80px = 800px (20시~다음날 6시)
          child: Stack(
            children: [
              // 레이어 1: 시간 텍스트 + 점선
              _buildNightTimeLabelsAndLines(),
              // 레이어 2: 실제/예상 수면 시간 색상 컴포넌트
              _buildNightSleepBars(),
              // 레이어 3: 수면 중 깬 시각을 표시하는 흰색 선
              _buildNightWakeMarkers(),
            ],
          ),
        ),
      ),
    );
  }

  // 밤잠 시간 텍스트와 점선 구현
  Widget _buildNightTimeLabelsAndLines() {
    return Column(
      children: [
        // 시간 텍스트 영역
        SizedBox(
          height: 40,
          child: Stack(
            children: [
              // 1시간 간격 시간 텍스트 (오후 8시 ~ 오전 6시)
              ...List.generate(11, (index) {
                int hour = 20 + index; // 20시(오후 8시)부터 시작
                String timeLabel;

                if (hour < 24) {
                  timeLabel = '오후 ${hour - 12}시';
                } else {
                  int nextDayHour = hour - 24;
                  if (nextDayHour == 0) {
                    timeLabel = '오전 12시';
                  } else {
                    timeLabel = '오전 ${nextDayHour}시';
                  }
                }

                return Positioned(
                  left: index * 80.0 - 5.0,
                  top: 0,
                  child: SizedBox(
                    width: 60,
                    child: Text(
                      timeLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF606C80),
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        // 점선 영역
        Expanded(
          child: Stack(
            children: [
              // 30분 간격 점선
              ...List.generate(20, (index) {
                // 10시간 * 2 = 20개
                double left = index * 40.0;
                bool isHourLine = index % 2 == 0;

                return Positioned(
                  left: left,
                  top: 0,
                  bottom: 0,
                  child: DottedBorder(
                    padding: EdgeInsets.zero,
                    strokeWidth: 1,
                    dashPattern: isHourLine ? [1, 0] : [4, 4], // 실선 또는 점선
                    color: const Color(0xFFEFF1F4),
                    customPath: (size) => Path()
                      ..moveTo(0, 0)
                      ..lineTo(0, size.height),
                    child: SizedBox(
                      width: 1,
                      height: double.infinity, // 중요: 선이 길게 보이게 만듦
                    ),
                  ),
                );
              }),
              // "Today" 텍스트 (오전 12시 왼쪽에 배치)
              Positioned(
                left: 4 * 80.0, // 원하는 위치
                top: 32,
                child: Transform.rotate(
                  angle: -1.5708, // -90도 (라디안 단위: -π/2)
                  child: Text(
                    'Today',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFFD8DADC),
                      fontWeight: FontWeight.w400,
                      height: 18 / 13,
                    ),
                  ),
                ),
              ),
              // 오전 12시 선 끝의 작은 동그라미
              Positioned(
                left:
                    8 * 40.0 -
                    3.0, // 오전 12시 선 위치 (index 8 * 40px)에서 중앙 정렬을 위해 -3px
                top: 0,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF1F4),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                left:
                    8 * 40.0 -
                    3.0, // 오전 12시 선 위치 (index 8 * 40px)에서 중앙 정렬을 위해 -3px
                bottom: 0,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF1F4),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 밤잠 수면 시간 막대 구현 (실제/예상) - 2열 구조
  Widget _buildNightSleepBars() {
    return Positioned(
      top: 46,
      left: 0,
      right: 0,
      height: 98,
      child: Stack(
        children: [
          // 상단 행: 실제 수면 시간 (진한 파란색)
          ..._buildActualNightBars(),

          // 하단 행: 예상 수면 시간 (연한 파란색)
          ..._buildExpectedNightBars(),
        ],
      ),
    );
  }

  // 예상 밤잠 수면 시간 막대들 (하단 행)
  List<Widget> _buildExpectedNightBars() {
    var splitData = _splitSleepRecords(_allExpectedSleepData);
    List<Map<String, dynamic>> expectedNightData = splitData['night']!;

    return expectedNightData.map((data) {
      var startTime = _parseTime(data['startTime']!);
      var endTime = _parseTime(data['endTime']!);

      double left = _timeToPixel(
        startTime['hour']!,
        startTime['minute']!,
        20,
      ); // 오후 8시(20시) 기준
      double width =
          _timeToPixel(endTime['hour']!, endTime['minute']!, 20) - left;

      return _buildSleepBar(
        left: left,
        width: width,
        color: const Color(0xFFB8C4F0),
        height: 32, // 2열 구조를 위해 높이 조정
        top: 36, // 하단 행
        isStartTruncated: data['isStartTruncated'] as bool,
        isEndTruncated: data['isEndTruncated'] as bool,
      );
    }).toList();
  }

  // 실제 밤잠 수면 시간 막대들 (상단 행)
  // 수면 데이터 적용된 영역
  List<Widget> _buildActualNightBars() {
    var splitData = _splitSleepRecords(_allActualSleepData);
    List<Map<String, dynamic>> actualNightData = splitData['night'] ?? [];

    
    return actualNightData.asMap().entries.map((entry) {
      int index = entry.key;
      Map<String, dynamic> data = entry.value;

      var startTime = _parseTime(data['startTime']!);
      var endTime = _parseTime(data['endTime']!);

      double left = _timeToPixel(
        startTime['hour']!,
        startTime['minute']!,
        20,
      ); // 오후 8시(20시) 기준
      double width =
          _timeToPixel(endTime['hour']!, endTime['minute']!, 20) - left;

      // sleepTitle은 이미 data에 포함되어 있음
      String sleepTitle = data['sleepTitle'] ?? '';

      // 매칭되는 예상 데이터 찾기
      String expectedStartTime = '';
      String expectedEndTime = '';
      for (var expectedData in _allExpectedSleepData) {
        if (expectedData['sleepTitle'] == sleepTitle &&
            expectedData['actualStartTime'] == data['startTime']) {
          expectedStartTime = expectedData['startTime']!;
          expectedEndTime = expectedData['endTime']!;
          break;
        }
      }

      return _buildClickableSleepBar(
        left: left,
        width: width,
        color: const Color(0xFF5D73D9),
        height: 32,
        top: 0, // 상단 행
        isStartTruncated: data['isStartTruncated'] as bool,
        isEndTruncated: data['isEndTruncated'] as bool,
        sleepData: {
          'sleepTitle': sleepTitle,
          'actualStartTime': data['startTime']!,
          'actualEndTime': data['endTime']!,
          'expectedStartTime': expectedStartTime,
          'expectedEndTime': expectedEndTime,
          'wakeCounts': data['wakeCounts'] ?? '',
          'sleepMode': data['sleepMode'],
        },
      );
    }).toList();
  }

  // 밤잠 수면 중 깬 시각 표시 (흰색 선)
  Widget _buildNightWakeMarkers() {
    var splitWakeTimes = _splitWakeTimes(_allWakeTimesData);
    List<String> nightWakeTimesData = splitWakeTimes['night']!;

    return Stack(
      children: nightWakeTimesData.map((timeString) {
        var time = _parseTime(timeString);
        double left = _timeToPixel(
          time['hour']!,
          time['minute']!,
          20,
        ); // 오후 8시(20시) 기준
        return _buildWakeMarker(left: left);
      }).toList(),
    );
  }

  // 시간을 픽셀 위치로 변환하는 헬퍼 함수 (1시간 = 80px)
  double _timeToPixel(int hour, int minute, int baseHour) {
    int totalMinutes = (hour - baseHour) * 60 + minute;
    if (hour < baseHour) {
      // 다음날로 넘어간 경우 (밤잠에서 사용)
      totalMinutes = (24 - baseHour + hour) * 60 + minute;
    }
    // 1시간 = 80px, 1분 = 80/60 = 1.33px
    return totalMinutes * (80.0 / 60.0);
  }

  // 시간 문자열을 시간과 분으로 파싱하는 헬퍼 함수 (안전하게 처리)
  Map<String, int> _parseTime(String timeString) {
    if (timeString.isEmpty) {
      // 기본값: 00:00 으로 처리
      return {'hour': 0, 'minute': 0};
    }

    List<String> parts = timeString.split(':');
    return {
      'hour': int.parse(parts[0]),
      'minute': int.parse(parts[1]),
    };
  }

  // 타임라인 경계를 넘나드는 수면 기록을 분할하는 헬퍼 함수
  Map<String, List<Map<String, dynamic>>> _splitSleepRecords(
    List<Map<String, String>> sleepData,
  ) {
    List<Map<String, dynamic>> napPortion = [];
    List<Map<String, dynamic>> nightPortion = [];

    for (var record in sleepData) {
      var startTimeStr = record['startTime'] ?? '';
      var endTimeStr = record['endTime'] ?? '';

      // 빈 값일 경우 skip
      if (startTimeStr.isEmpty || endTimeStr.isEmpty) {
        continue;
      }

      var startTime = _parseTime(startTimeStr);
      var endTime = _parseTime(endTimeStr);

      int startHour = startTime['hour']!;
      int endHour = endTime['hour']!;

      // 낮잠 시간대: 6시~20시 (오전 6시~오후 8시)
      // 밤잠 시간대: 20시~다음날 6시 (오후 8시~오전 6시)

      bool startInNap = startHour >= 6 && startHour < 20;
      bool endInNap = endHour >= 6 && endHour < 20;

      // 다음날로 넘어가는 경우 처리
      bool isOvernight = endHour < startHour;

      // Logic for sleepTitle
      final sleepMode = record['sleepMode'];
      final sleepModeSeq = record['sleepModeSeq'];
      final sleepTitle = (sleepMode == 'day' ? '낮잠' : '밤잠') + ' ' + (sleepModeSeq ?? '');

      if (isOvernight) {
        // 밤잠에서 시작해서 다음날 낮잠으로 넘어가는 경우 (예: 04:30 ~ 07:00)
        if (startHour >= 20 || startHour < 6) {
          // 시작이 밤잠 시간대
          if (endHour < 6) {
            // 완전히 밤잠 시간대 (예: 22:00 ~ 05:00)
            nightPortion.add({
              'startTime': record['startTime'] ?? '',
              'endTime': record['endTime'] ?? '',
              'originalStartTime': record['startTime'] ?? '',
              'sleepTitle': record['sleepTitle'] ?? '알 수 없음',
              'sleepMode': record['sleepMode'] ?? 'unknown',
              'sleepModeSeq': record['sleepModeSeq'] ?? '',
              'actualStartTime': record['startTime'] ?? '',
              'wakeCounts': record['wakeCounts'] ?? '',
              'isStartTruncated': false,
              'isEndTruncated': false,
            });
          } else {
            // 밤잠에서 낮잠으로 넘어감 (예: 04:30 ~ 07:00)
            nightPortion.add({
              'startTime': record['startTime'] ?? '',
              'endTime': '06:00',
              'originalStartTime': record['startTime'] ?? '',
              'sleepTitle': record['sleepTitle'] ?? '알 수 없음',
              'sleepMode': record['sleepMode'] ?? 'unknown',
              'sleepModeSeq': record['sleepModeSeq'] ?? '',
              'actualStartTime': record['startTime'] ?? '',
              'isStartTruncated': false,
              'isEndTruncated': true,
            });
            napPortion.add({
              'startTime': '06:00',
              'endTime': record['endTime'] ?? '',
              'originalStartTime': record['startTime'] ?? '',
              'sleepTitle': record['sleepTitle'] ?? '알 수 없음',
              'sleepMode': record['sleepMode'] ?? 'unknown',
              'sleepModeSeq': record['sleepModeSeq'] ?? '',
              'actualStartTime': record['startTime'] ?? '',
              'wakeCounts': record['wakeCounts'] ?? '',
              'isStartTruncated': true,
              'isEndTruncated': false,
            });
          }
        }
      } else {
        // 같은 날 내에서의 수면
        if (startInNap && endInNap) {
          // 완전히 낮잠 시간대 (예: 06:28 ~ 08:22)
          napPortion.add({
            'startTime': record['startTime'] ?? '',
            'endTime': record['endTime'] ?? '',
            'originalStartTime': record['startTime'] ?? '',
            'sleepTitle': record['sleepTitle'] ?? '알 수 없음',
            'sleepMode': record['sleepMode'] ?? 'unknown',
            'sleepModeSeq': record['sleepModeSeq'] ?? '',
            'actualStartTime': record['startTime'] ?? '',
            'wakeCounts': record['wakeCounts'] ?? '',
            'isStartTruncated': false,
            'isEndTruncated': false,
          });
        } else if (!startInNap && !endInNap) {
          // 완전히 밤잠 시간대 (예: 21:30 ~ 23:00)
          nightPortion.add({
            'startTime': record['startTime'] ?? '',
            'endTime': record['endTime'] ?? '',
            'originalStartTime': record['startTime'] ?? '',
            'sleepTitle': record['sleepTitle'] ?? '알 수 없음',
            'sleepMode': record['sleepMode'] ?? 'unknown',
            'sleepModeSeq': record['sleepModeSeq'] ?? '',
            'actualStartTime': record['startTime'] ?? '',
            'wakeCounts': record['wakeCounts'] ?? '',
            'isStartTruncated': false,
            'isEndTruncated': false,
          });
        } else if (startInNap && !endInNap) {
          // 낮잠에서 밤잠으로 넘어감 (예: 19:45 ~ 20:30)
          napPortion.add({
            'startTime': record['startTime'] ?? '',
            'endTime': '20:00',
            'originalStartTime': record['startTime'] ?? '',
            'sleepTitle': record['sleepTitle'] ?? '알 수 없음',
            'sleepMode': record['sleepMode'] ?? 'unknown',
            'sleepModeSeq': record['sleepModeSeq'] ?? '',
            'actualStartTime': record['startTime'] ?? '',
            'isStartTruncated': false,
            'isEndTruncated': true,
          });
          nightPortion.add({
            'startTime': '20:00',
            'endTime': record['endTime'] ?? '',
            'originalStartTime': record['startTime'] ?? '',
            'sleepTitle': record['sleepTitle'] ?? '알 수 없음',
            'sleepMode': record['sleepMode'] ?? 'unknown',
            'sleepModeSeq': record['sleepModeSeq'] ?? '',
            'actualStartTime': record['startTime'] ?? '',
            'wakeCounts': record['wakeCounts'] ?? '',
            'isStartTruncated': true,
            'isEndTruncated': false,
          });
        } else if (!startInNap && endInNap) {
          // 밤잠에서 낮잠으로 넘어감 (같은 날, 거의 없는 케이스)
          nightPortion.add({
            'startTime': record['startTime'] ?? '',
            'endTime': '06:00',
            'originalStartTime': record['startTime'] ?? '',
            'sleepTitle': record['sleepTitle'] ?? '알 수 없음',
            'sleepMode': record['sleepMode'] ?? 'unknown',
            'sleepModeSeq': record['sleepModeSeq'] ?? '',
            'actualStartTime': record['startTime'] ?? '',
            'wakeCounts': record['wakeCounts'] ?? '',
            'isStartTruncated': false,
            'isEndTruncated': true,
          });
          napPortion.add({
            'startTime': '06:00',
            'endTime': record['endTime'] ?? '',
            'originalStartTime': record['startTime'] ?? '',
            'sleepTitle': record['sleepTitle'] ?? '알 수 없음',
            'sleepMode': record['sleepMode'] ?? 'unknown',
            'sleepModeSeq': record['sleepModeSeq'] ?? '',
            'actualStartTime': record['startTime'] ?? '',
            'wakeCounts': record['wakeCounts'] ?? '',
            'isStartTruncated': true,
            'isEndTruncated': false,
          });
        }
      }
    }

    return {'nap': napPortion, 'night': nightPortion};
  }

  // 깬 시간도 타임라인별로 분할하는 헬퍼 함수
  Map<String, List<String>> _splitWakeTimes(List<String> wakeTimes) {
    List<String> napWakeTimes = [];
    List<String> nightWakeTimes = [];

    for (var timeString in wakeTimes) {
      var time = _parseTime(timeString);
      int hour = time['hour']!;

      if (hour >= 6 && hour < 20) {
        // 낮잠 시간대 (6시~20시)
        napWakeTimes.add(timeString);
      } else {
        // 밤잠 시간대 (20시~다음날 6시)
        nightWakeTimes.add(timeString);
      }
    }

    return {'nap': napWakeTimes, 'night': nightWakeTimes};
  }

  // 네이티브 공유 위젯 호출 함수
  void _shareWithNativeWidget() {
    // 수면 상세 리스트 생성
    // 👉🏻👉🏻👉🏻 TODO: 추후 수면 상세 데이터 점검 + Title에 있는 기록 날짜도 불러와야함
    StringBuffer sleepDetails = StringBuffer();
    for (var sleep in _allActualSleepData) {
      String formattedTitle = sleep['sleepTitle']!.padRight(6);
      sleepDetails.writeln(
        '• $formattedTitle: ${sleep['startTime']} - ${sleep['endTime']} (깬 횟수: ${sleep['wakeCounts']}회)',
      );
    }

    String formattedShareDate = _formatKoreanDate(_selectedStartDt);

    String shareText =
        '''
🍼 $formattedShareDate 수면 기록

📊 전체 수면 시간: $_totalSleepTime

🌞 낮잠: $_napSleepTime ($_napSleepCount회)
🌙 밤잠: $_nightSleepTime ($_nightSleepCount회)

📋 수면 상세:
${sleepDetails.toString().trim()}

👉 MADE BY LG EGGie

#육아 #수면기록 #에기
        '''
            .trim();

    Share.share(shareText);
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
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: _shareWithNativeWidget,
                color: const Color(0xFF606C80),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _buildTimelineDetailCard(
    String sleep_log_title,
    String actual_sleep_start_time,
    String actual_sleep_end_time,
    String expected_sleep_start_time,
    String expected_sleep_end_time,
    String wake_counts,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFF1F4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sleep_log_title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF606C80),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              children: [
                const Text(
                  '실제 수면 시간',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF111111),
                    height: 24 / 16,
                  ),
                ),
                const Spacer(),
                Text(
                  '$actual_sleep_start_time - $actual_sleep_end_time',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF111111),
                    height: 24 / 16,
                  ),
                ),
              ],
            ),
          ),
          _buildDevider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              children: [
                const Text(
                  '예상 수면 시간',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF111111),
                    height: 24 / 16,
                  ),
                ),
                const Spacer(),
                Text(
                  '$expected_sleep_start_time - $expected_sleep_end_time',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF111111),
                    height: 24 / 16,
                  ),
                ),
              ],
            ),
          ),
          _buildDevider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              children: [
                const Text(
                  '깬 횟수',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF111111),
                    height: 24 / 16,
                  ),
                ),
                const Spacer(),
                Text(
                  '$wake_counts회',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF111111),
                    height: 24 / 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '메모',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF606C80),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '목욕하고 막수 170ml 먹였다.\n쪽쪽이 물리고 재우기 성공.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xFF111111),
            ),
          ),
        ],
      ),
    );
  }

  Container _buildAIFeedbackWidget() {
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
                _isAIFeedbackExpanded = !_isAIFeedbackExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  const Text(
                    'AI 수면 피드백',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF606C80),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isAIFeedbackExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: Color(0xFF606C80),
                  ),
                ],
              ),
            ),
          ),
          if (_isAIFeedbackExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                '16주 아기에게 적절한 낮잠 시간은 3-4시간이에요. 점점 밤잠이 길어지는 기간입니다.\n\n${_getNapFeedbackMessage()}\n\n조만간 원더윅스 기간이 시작되니, 수면 패턴이 변동되어도 불안해하지 마세요 ☺️',
                style: TextStyle(
                  fontSize: 16,
                  height: 24 / 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF111111),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _buildColorChip extends StatelessWidget {
  const _buildColorChip({super.key, required this.colorchip});
  final Color colorchip;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: colorchip,
        borderRadius: BorderRadius.circular(2),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0D4B5574), // 0D = 5% 투명도
            offset: const Offset(0, 0),
            blurRadius: 80,
          ),
          BoxShadow(
            color: const Color(0x33FFFFFF), // 33 = 20% 투명도
            offset: const Offset(-31, -31),
            blurRadius: 80,
          ),
          BoxShadow(
            color: const Color(0x33FFFFFF), // 33 = 20% 투명도
            offset: const Offset(4, 4),
            blurRadius: 20,
          ),
        ],
      ),
    );
  }
}

Widget _buildDevider() {
  return const Divider(height: 1, color: Color(0xFFEFF1F4));
}

class _buildSleepSummaryItem extends StatelessWidget {
  const _buildSleepSummaryItem({
    super.key,
    required this.icon,
    required this.text,
    required this.value_time,
    required this.value_counts,
  });
  final String icon;
  final String text;
  final String value_time;
  final String value_counts;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Image.asset(icon, width: 40, height: 40),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xFF111111),
            ),
          ),
          const Spacer(),
          Text(
            value_time,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '$value_counts회',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xFF606C80),
            ),
          ),
        ],
      ),
    );
  }
}

// 오늘 수면 데이터 API 서비스
class SleepApiService {

  // 오늘 수면 상세 데이터 API 서비스
  static Future<Map<String, dynamic>> getTodaySleepDetailData(int babyId, {String? startDt}) async {
    try {
      String url = '${getBaseUrl()}/today-sleep-detail-test?baby_id=$babyId';
      if (startDt != null) {
        url += '&start_dt=$startDt';
      }
      final uri = Uri.parse(url);
      final response = await http.get(uri);

      print('✅ Raw response data: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        print('✅ Raw decoded data type: ${decoded.runtimeType}');

        if (decoded is List) {
          if (decoded.isNotEmpty && decoded.first is Map<String, dynamic>) {
            return decoded.first as Map<String, dynamic>;
          } else {
            throw Exception('Unexpected response structure: List is empty or elements are not Map<String, dynamic>');
          }
        } else if (decoded is Map<String, dynamic>) {
          return decoded;
        } else {
          throw Exception('Unexpected response type: ${decoded.runtimeType}');
        }
      } else {
        throw Exception('Failed to load today sleep detail data (${response.statusCode})');
      }
    } catch (e) {
      print('❗ Error fetching today sleep detail data: $e');
      rethrow;
    }
  }
}
