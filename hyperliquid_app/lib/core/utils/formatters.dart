import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme.dart';

String fmtPrice(dynamic value, [int decimals = 2]) {
  final n = double.tryParse(value.toString());
  if (n == null) return '\u2014';
  return NumberFormat.currency(
    symbol: '',
    decimalDigits: decimals,
  ).format(n).trim();
}

String fmtUsd(dynamic value, [int decimals = 2]) {
  final n = double.tryParse(value.toString());
  if (n == null) return '\u2014';
  return '\$${fmtPrice(n, decimals)}';
}

String fmtPnl(dynamic value, [int decimals = 2]) {
  final n = double.tryParse(value.toString());
  if (n == null) return '\u2014';
  final prefix = n >= 0 ? '+' : '';
  return '$prefix\$${fmtPrice(n, decimals)}';
}

int autoPriceDecimals(double price) {
  if (price > 100) return 2;
  return 4;
}

Color pnlColor(dynamic value) {
  final n = double.tryParse(value.toString());
  if (n == null || n == 0) return AppColors.text;
  return n > 0 ? AppColors.green : AppColors.red;
}

String shortAddress(String address) {
  if (address.length < 10) return address;
  return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
}

String fmtTimeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 5) return 'just now';
  if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  return '${diff.inHours}h ago';
}

String fmtTime(dynamic time) {
  DateTime dt;
  if (time is int) {
    dt = DateTime.fromMillisecondsSinceEpoch(time);
  } else if (time is String) {
    dt =
        DateTime.tryParse(time) ??
        DateTime.fromMillisecondsSinceEpoch(int.tryParse(time) ?? 0);
  } else {
    return '\u2014';
  }
  return DateFormat('MM/dd HH:mm').format(dt.toLocal());
}
