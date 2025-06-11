import 'package:eggie2/pages/calendar_page.dart';
import 'package:eggie2/pages/device_off.dart';
import 'package:eggie2/pages/device_page.dart';
import 'package:eggie2/pages/mode_off.dart';
import 'package:eggie2/pages/mode_on.dart';
import 'package:eggie2/pages/sleep_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:eggie2/services/api.dart';

// 수면 데이터 모델
class TodaySleepData {
  final int napCount; // 낮잠 총 횟수
  final String napDuration; // 낮잠 총 시간 (예: "3시간 30분")
  final int nightCount; // 밤잠 총 횟수
  final String nightDuration; // 밤잠 총 시간 (예: "7시간 20분")

  TodaySleepData({
    required this.napCount,
    required this.napDuration,
    required this.nightCount,
    required this.nightDuration,
  });

  // API 응답을 모델로 변환하는 팩토리 생성자
  factory TodaySleepData.fromJson(Map<String, dynamic> json) {
    return TodaySleepData(
      napCount: json['napCount'] ?? 0,
      napDuration: json['napDuration'] ?? '0시간 0분',
      nightCount: json['nightCount'] ?? 0,
      nightDuration: json['nightDuration'] ?? '0시간 0분',
    );
  }
}

// API 서비스 클래스
class SleepApiService {
  // Now backed by the today-sleep-detail API (not today-sleep-summary)
  static Future<TodaySleepData> getTodaySleepData(int babyId, {String? startDt}) async {
    try {
      String url = '${getBaseUrl()}/today-sleep-detail?baby_id=$babyId';
      if (startDt != null) {
        url += '&start_dt=$startDt';
      }
      final uri = Uri.parse(url);
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // napCount, napDuration, nightCount, nightDuration are at the top level of response (not inside sleepRecords)
        return TodaySleepData.fromJson(data);
      } else {
        throw Exception('Failed to load today sleep data (${response.statusCode})');
      }
    } catch (e) {
      print('❗ Error fetching today sleep data: $e');
      rethrow;
    }
  }
}

class UsefulFunctionPage extends StatefulWidget {
  const UsefulFunctionPage({super.key});

  @override
  State<UsefulFunctionPage> createState() => _UsefulFunctionPageState();
}

class _UsefulFunctionPageState extends State<UsefulFunctionPage> {
  TodaySleepData? todaySleepData;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTodaySleepData();
  }

  // 오늘 수면 데이터 로드
  Future<void> _loadTodaySleepData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final prefs = await SharedPreferences.getInstance();
      final babyId = prefs.getInt('baby_id') ?? 1;

      // Temporary hardcoded date for testing
      final startDt = '2024-09-16';

      // To use today dynamically in the future, use this:
      // final today = DateTime.now();
      // final startDt = '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final data = await SleepApiService.getTodaySleepData(babyId, startDt: startDt);

      setState(() {
        todaySleepData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = '수면 데이터를 불러오는데 실패했습니다.';
        isLoading = false;
      });
      print('Error loading sleep data: $e');
    }
  }

  // EGGie 디바이스 상태에 따른 페이지 이동 (HomePage와 동일한 로직)
  Future<void> _navigateToDevicePage() async {
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

    final isDeviceOn = deviceOn || hasSleepStartTime; // 수면 시작했으면 디바이스 켜진 것으로 간주
    final isSleeping = isDeviceOn ? isSleepSessionActive : false;

    print('Useful page device status:');
    print('  - Device on: $isDeviceOn');
    print('  - Sleep session active: $isSleepSessionActive');
    print('  - Is sleeping: $isSleeping');

    if (!context.mounted) return;

    if (!isDeviceOn) {
      // 디바이스가 꺼져있으면 device_off 페이지로
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const DeviceOff(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    } else if (isSleeping) {
      // 디바이스가 켜져있고 수면 중이면 mode_on 페이지로
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const ModeOnPage(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    } else {
      // 디바이스가 켜져있고 수면 완료 상태면 mode_off 페이지로
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
    return Scaffold(
      backgroundColor: const Color(0xFFEDF2F4),
      appBar: _buildEggieTopBar(context),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),

            //에너지 모니터링 카드
            _buildEnergyCard(),
            const SizedBox(height: 16),

            // 수면 일지 카드
            _buildSleepingCard(),
            const SizedBox(height: 16),

            // 함깨 구매하면 좋은 상품
            _buildProductCard(),
            const SizedBox(height: 16),

            // 가전세척 서비스 신청하기
            _buildCleaningService(),
            const SizedBox(height: 70),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomToggleBar(context),
    );
  }

  Widget _buildEnergyCard() {
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
          _buildIconTextItem(
            icon: 'assets/images/energy_monitor.png',
            text: '에너지 모니터링',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('다음 업데이트에서 만나요!'),
                  duration: Duration(milliseconds: 1500), // 1.5초로 단축
                ),
              );
            },
          ),
          _buildEnergyDetail(),
          const SizedBox(height: 16),
          _buildDevider(),
          const SizedBox(height: 6),
          _buildIconTextItem(
            icon: 'assets/images/energy_log.png',
            text: '사용 이력',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('다음 업데이트에서 만나요!'),
                  duration: Duration(milliseconds: 1500), // 1.5초로 단축
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  _buildSleepingCard() {
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
          _buildIconTextItem(
            icon: '',
            text: '오늘 수면 일지',
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
          ),
          _buildTodaySleepDetail(),
          const SizedBox(height: 16),
          _buildDevider(),
          const SizedBox(height: 6),
          _buildIconTextItem(
            icon: 'assets/images/calendar.png',
            text: '육아 캘린더',
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const CalendarPage(),
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

  _buildProductCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFF1F4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset('assets/images/product.png', width: 40, height: 40),
              const SizedBox(width: 8),
              Text(
                '함깨 구매하면 좋은 상품',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF111111),
                ),
              ),
            ],
          ),
          Text(
            '16주차 우리 아이에게 필요한 상품을 확인해보세요.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFF606C80),
              height: 24 / 12,
            ),
          ),
          const SizedBox(height: 8),

          // 상품 리스트
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildProdectItem(
                  image: 'assets/images/bottlewasher.png',
                  title: '4in1 젖병 세척기',
                  subTitle: '오르테',
                  price: '558,000원',
                  originalPrice: '599,999원',
                  discount: '7%',
                ),
                const SizedBox(width: 8),
                _buildProdectItem(
                  image: 'assets/images/feeding_sheet.png',
                  title: '수유시트(오가닉..)',
                  subTitle: '알프레미오',
                  price: '28,500원',
                  originalPrice: '30,000원',
                  discount: '5%',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProdectItem({
    required String image,
    required String title,
    required String subTitle,
    required String price,
    required String originalPrice,
    required String discount,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFEFF1F4)),
      ),
      width: 292,
      child: Row(
        children: [
          // 상품 이미지
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(image, width: 80, height: 80, fit: BoxFit.cover),
          ),
          const SizedBox(width: 16),

          // 상품 텍스트 정보
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111111),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  subTitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF606C80),
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      discount,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE03131),
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111111),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2),
                Text(
                  originalPrice,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    decoration: TextDecoration.lineThrough,
                    color: Color(0xFFADB5BD),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCleaningService() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFF1F4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIconTextItem(
            icon: 'assets/images/cleaning_service.png',
            text: '가전세척 서비스 신청하기',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('다음 업데이트에서 만나요!'),
                  duration: Duration(milliseconds: 1500), // 1.5초로 단축
                ),
              );
            },
          ),
          Text(
            'LG전자의 전문적인 가전세척 서비스를 신청할 수 있어요.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFF606C80),
              height: 24 / 12,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildIconTextItem({
    required String icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            if (icon.isNotEmpty) // <- 조건부 렌더링
              Image.asset(icon, width: 40, height: 40),
            if (icon.isNotEmpty) const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Color(0xFF111111),
              ),
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

  _buildTodaySleepDetail() {
    if (isLoading) {
      return SizedBox(
        height: 88,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF4A57BF)),
        ),
      );
    }

    if (errorMessage != null) {
      return SizedBox(
        height: 88,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                errorMessage!,
                style: TextStyle(fontSize: 14, color: Color(0xFF606C80)),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _loadTodaySleepData,
                child: Text(
                  '다시 시도',
                  style: TextStyle(fontSize: 14, color: Color(0xFF4A57BF)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 88,
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Image.asset(
              'assets/images/baby_firstroll.png',
              width: 80,
              height: 80,
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            width: 1,
            height: 88,
            color: const Color(0xFFEFF1F4),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '낮잠',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF606C80),
                  height: 24 / 12,
                ),
              ),
              Text(
                '${todaySleepData?.napCount ?? 0}회',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF111111),
                  height: 24 / 16,
                ),
              ),
              Text(
                '${todaySleepData?.napDuration ?? '0시간 0분'}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF111111),
                  height: 24 / 16,
                ),
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            width: 1,
            height: 88,
            color: const Color(0xFFEFF1F4),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '밤잠',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF606C80),
                  height: 24 / 12,
                ),
              ),
              Text(
                '${todaySleepData?.nightCount ?? 0}회',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF111111),
                  height: 24 / 16,
                ),
              ),
              Text(
                '${todaySleepData?.nightDuration ?? '0시간 0분'}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF111111),
                  height: 24 / 16,
                ),
              ),
            ],
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
                  // '제품' 탭 (비선택된 상태)
                  Expanded(
                    child: GestureDetector(
                      onTap: _navigateToDevicePage,
                      child: const Center(
                        child: Text(
                          '제품',
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

                  // '유용한 기능' 탭 (선택 상태)
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF3F4D63),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: const Center(
                        child: Text(
                          '유용한 기능',
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _buildEnergyDetail extends StatelessWidget {
  const _buildEnergyDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            children: [
              Text(
                '이번달',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF606C80),
                  height: 24 / 12,
                ),
              ),
              Text(
                '1.12 kWh',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF111111),
                  height: 24 / 16,
                ),
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            width: 1,
            height: 48,
            color: const Color(0xFFEFF1F4),
          ),
          Column(
            children: [
              Text(
                '지난달',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF606C80),
                  height: 24 / 12,
                ),
              ),
              Text(
                '296 kWh',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF111111),
                  height: 24 / 16,
                ),
              ),
            ],
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
