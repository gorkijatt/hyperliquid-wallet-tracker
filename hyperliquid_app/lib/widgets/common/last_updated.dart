import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/utils/formatters.dart';

class LastUpdated extends StatefulWidget {
  final DateTime? time;

  const LastUpdated({super.key, this.time});

  @override
  State<LastUpdated> createState() => _LastUpdatedState();
}

class _LastUpdatedState extends State<LastUpdated> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.time == null) return const SizedBox.shrink();
    return Text(
      fmtTimeAgo(widget.time!),
      style: const TextStyle(fontSize: 10, color: AppColors.textDim),
    );
  }
}
