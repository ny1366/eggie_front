import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:eggie2/services/api.dart';

/// A page that displays detailed device log information for a specific recorded time.
class DeviceLogDetailPage extends StatefulWidget {
  final DateTime recordedAt;
  const DeviceLogDetailPage({super.key, required this.recordedAt});

  @override
  State<DeviceLogDetailPage> createState() => _DeviceLogDetailPageState();
}

class _DeviceLogDetailPageState extends State<DeviceLogDetailPage> {
  /// Checks if two DateTime objects represent the same minute.
  bool isSameMinute(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day &&
        a.hour == b.hour &&
        a.minute == b.minute;
  }

  Future<List<dynamic>>? _detailedHistoryFuture;

  @override
  void initState() {
    super.initState();
    _detailedHistoryFuture = fetchDetailedHistory();
  }

  Future<List<dynamic>> fetchDetailedHistory() async {
    final url = Uri.parse('${getBaseUrl()}/detailed-history/1');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load detailed history');
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedTitle = DateFormat("yyyy.M.d. a h:mm", 'ko_KR').format(widget.recordedAt);

    return Scaffold(
      backgroundColor: const Color(0xFFEDF2F4),
      appBar: _buildTopBar(context, title: formattedTitle),
      body: FutureBuilder<List<dynamic>>(
        future: _detailedHistoryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('에러: ${snapshot.error}'));
          } else {
            final data = snapshot.data!;
            final matchedItem = data.firstWhere((item) {
              final parsed = HttpDate.parse(item['recorded_at']).toLocal();
              return isSameMinute(parsed, widget.recordedAt);
            }, orElse: () => null);

            if (matchedItem == null) {
              return const Center(child: Text('기록 없음'));
            }
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  _buildWidgetTitle(text: '에너지 사용량'),
                  const SizedBox(height: 8),
                  const _buildEnergyUsageWidget(),
                  const SizedBox(height: 24),
                  _buildWidgetTitle(text: '환경 정보'),
                  const SizedBox(height: 8),
                  _buildEnvInfoWidget(matchedItem),
                  const SizedBox(height: 24),
                  _buildWidgetTitle(text: '코스 옵션'),
                  const SizedBox(height: 2),
                  _buildWidgetTitle(text: '자동 코스의 경우, 평균 설정값으로 노출됩니다.'),
                  const SizedBox(height: 8),
                  _buildCourseOptionWidget(matchedItem),
                  const SizedBox(height: 120),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  /// Builds the environment information section showing temperature, humidity, brightness, and noise level.
  Container _buildEnvInfoWidget(Map<String, dynamic> data) {
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
          _buildEnvInfoItem(text: '평균 온도', value: '${data['temperature']}°C'),
          _buildDevider(),
          _buildEnvInfoItem(text: '평균 습도', value: '${data['humidity']}%'),
          _buildDevider(),
          _buildEnvInfoItem(text: '밝기', value: '${data['brightness']}%'),
          _buildDevider(),
          _buildEnvInfoItem(text: '백색 소음', value: '${data['white_noise_level']}dB'),
        ],
      ),
    );
  }

  /// Builds the course option section showing preset options and some environment data.
  Container _buildCourseOptionWidget(Map<String, dynamic> data) {
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
          _buildEnvInfoItem(text: '바람 세기', value: '약풍'),
          _buildDevider(),
          _buildEnvInfoItem(text: '가습 세기', value: '낮음'),
          _buildDevider(),
          _buildEnvInfoItem(text: '제습 세기', value: 'OFF'),
          _buildDevider(),
          _buildEnvInfoItem(text: '밝기', value: '${data['brightness']}%'),
          _buildDevider(),
          _buildEnvInfoItem(text: '백색 소음', value: '${data['white_noise_level']}dB'),
        ],
      ),
    );
  }

  Widget _buildDevider() {
    return const Divider(height: 1, color: Color(0xFFEFF1F4));
  }

  Padding _buildWidgetTitle({required String text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: Color(0xFF606C80)),
        textAlign: TextAlign.left,
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
}

class _buildEnergyUsageWidget extends StatelessWidget {
  const _buildEnergyUsageWidget({super.key});

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                const Text(
                  '전력 사용량',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF111111),
                  ),
                ),
                const Spacer(),
                const Text(
                  '647kWh',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF111111),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _buildEnvInfoItem extends StatelessWidget {
  const _buildEnvInfoItem({super.key, required this.text, required this.value});
  final String text;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 12, color: Color(0xFF606C80)),
          ),
        ],
      ),
    );
  }
}
