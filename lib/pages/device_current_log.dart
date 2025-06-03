import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:eggie2/services/api.dart';
import 'package:eggie2/pages/device_log_detail.dart' show DeviceLogDetailPage;
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class CurrentLogPage extends StatelessWidget {
  const CurrentLogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDF2F4),
      appBar: _buildTopBar(context, title: '사용 이력'),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            _buildDeviceLogWidget(context),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.only(left: 24, right: 24, top: 0, bottom: 70),
              child: Text(
                '최근 3개월의 사용 이력을 확인할 수 있어요.',
                style: TextStyle(fontSize: 14, color: Color(0xFF606C80)),
                textAlign: TextAlign.left,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceLogWidget(BuildContext context) {
    return FutureBuilder<List<Map<String, String>>>(
      future: fetchSleepLogs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("에러: ${snapshot.error}"));
        } else {
          final logs = snapshot.data!;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEFF1F4)),
            ),
            child: Column(
              children: List.generate(logs.length * 2 - 1, (index) {
                if (index.isOdd) return _buildDevider();
                final log = logs[index ~/ 2];
                return _buildDeviceLogItem(
                  context,
                  modeIndex: log['modeIndex']!,
                  date: log['date']!,
                );
              }),
            ),
          );
        }
      },
    );
  }

  Future<List<Map<String, String>>> fetchSleepLogs() async {
    final url = Uri.parse('${getBaseUrl()}/sleep-mode-format/1');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map<Map<String, String>>((item) {
        final rawDate = DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'", 'en_US').parse(item["start_time"]);
        final formattedDate = "${rawDate.year}.${rawDate.month.toString().padLeft(2, '0')}.${rawDate.day.toString().padLeft(2, '0')} "
          "${rawDate.hour < 12 ? '오전' : '오후'} ${rawDate.hour % 12 == 0 ? 12 : rawDate.hour % 12}:${rawDate.minute.toString().padLeft(2, '0')}";

        return {
          "date": formattedDate,
          "modeIndex": item["sleep_mode"]
        };
      }).toList();
    } else {
      throw Exception("데이터 로딩 실패");
    }
  }

  Widget _buildDevider() {
    return const Divider(height: 1, color: Color(0xFFEFF1F4));
  }

  Widget _buildDeviceLogItem(
    BuildContext context, {
    required String modeIndex,
    required String date,
  }) {
    return GestureDetector(
      onTap: () {
        final rawDate = DateFormat("yyyy.MM.dd a h:mm", 'ko_KR').parse(date);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeviceLogDetailPage(recordedAt: rawDate),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  modeIndex,
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
