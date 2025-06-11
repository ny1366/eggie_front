import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:eggie2/services/api.dart';
import 'package:eggie2/pages/device_log_detail.dart' show DeviceLogDetailPage;
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:eggie2/utils/time_formatter.dart';

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
                  rawDate: log['rawDate']!,
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
      // Parsing 'recorded_at' field instead of 'start_time' from API response
      return data.map<Map<String, String>>((item) {
        final formattedDate = formatKoreanDateTime(item["recorded_at"]);

        return {
          "date": formattedDate,
          "rawDate": item["recorded_at"],
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
    required String rawDate,
  }) {
    return GestureDetector(
      onTap: () {
        try {
          final parsedDate = DateTime.parse(rawDate).toLocal();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DeviceLogDetailPage(recordedAt: parsedDate),
            ),
          );
        } catch (e) {
          debugPrint('❗ 날짜 파싱 실패: $rawDate');
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatKoreanDateTimeFromISO(rawDate),
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
