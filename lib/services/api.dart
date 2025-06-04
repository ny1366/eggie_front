import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

String getBaseUrl() {
  if (kIsWeb) {
    return 'http://192.168.0.188:5050'; // ✅ 브라우저에서는 이 주소 사용
  }

  // ❗ 반드시 kIsWeb 다음에 Platform 써야 함. 순서 바꾸면 에러남
  if (Platform.isAndroid) {
    return 'http://10.0.2.2:5050'; // ✅ Android 에뮬레이터에서는 이 주소
  }

  return 'http://192.168.0.188:5050'; // ✅ iOS 시뮬레이터 등
}