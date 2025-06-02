import 'package:eggie2/pages/device_log_detail.dart';
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
          _buildDeviceLogItem(
            context,
            modeIndex: '낮잠1',
            date: '2025.05.23 오전 11:12',
          ),
          _buildDevider(),
          _buildDeviceLogItem(
            context,
            modeIndex: '밤잠2',
            date: '2025.05.23 오후 11:12',
          ),
          _buildDevider(),
          _buildDeviceLogItem(
            context,
            modeIndex: '밤잠1',
            date: '2025.05.23 오후 11:12',
          ),
          _buildDevider(),
          _buildDeviceLogItem(
            context,
            modeIndex: '낮잠3',
            date: '2025.05.23 오전 11:12',
          ),
          _buildDevider(),
          _buildDeviceLogItem(
            context,
            modeIndex: '낮잠2',
            date: '2025.05.23 오전 11:12',
          ),
          _buildDevider(),
          _buildDeviceLogItem(
            context,
            modeIndex: '낮잠1',
            date: '2025.05.23 오전 11:12',
          ),
        ],
      ),
    );
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
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DeviceLogDetailPage()),
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
