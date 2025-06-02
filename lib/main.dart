import 'package:eggie2/pages/device_current_log.dart';
import 'package:eggie2/pages/device_log_detail.dart';
import 'package:eggie2/pages/device_off.dart';
import 'package:eggie2/pages/home_page.dart';
import 'package:eggie2/pages/device_page.dart';
import 'package:eggie2/pages/mode_off.dart';
import 'package:eggie2/pages/sleep_log.dart';
import 'package:eggie2/pages/useful_page.dart';
import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: 'EGGie App',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFEFF1F4),
        fontFamily: 'Pretendard',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/device': (context) => const DevicePage(),
        '/current_log': (context) => const CurrentLogPage(),
        '/today_sleep_log': (context) => const TodaySleepLogPage(),
        '/useful_function': (context) => const UsefulFunctionPage(),
        '/mode_off': (context) => const ModeOffPage(),
        '/device_log_detail': (context) => const DeviceLogDetailPage(),
        '/device_off': (context) => const DeviceOff(),
      },
    );
  }
}
