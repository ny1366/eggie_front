// lib/utils/time_formatter.dart
import 'dart:io';

/// RFC 1123 형식의 시간 문자열을 한국 시간으로 변환한 뒤, "오전 9:00" 형식으로 리턴
String formatKoreanTime(String? raw) {
  if (raw == null) return '시간 없음';
  try {
    final dt = HttpDate.parse(raw).toLocal(); // 로컬 타임존 (한국 시간)
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final period = dt.hour < 12 ? '오전' : '오후';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$period $hour:$minute';
  } catch (e) {
    return '시간 오류';
  }
}

/// 날짜까지 포함된 포맷 (예: "2024.09.16 오전 9:00")
String formatKoreanDateTime(String? raw) {
  if (raw == null) return '시간 없음';
  try {
    final dt = HttpDate.parse(raw).toLocal();
    final year = dt.year.toString();
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final period = dt.hour < 12 ? '오전' : '오후';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$year.$month.$day $period $hour:$minute';
  } catch (e) {
    return '날짜 오류';
  }
}