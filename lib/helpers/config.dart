import 'dart:async';
import 'package:flutter/foundation.dart';

class LogManager extends ChangeNotifier {
  final List<String> _logs = [];
  final StreamController<String> _logStreamController = StreamController.broadcast();

  Stream<String> get logStream => _logStreamController.stream;

  void addLog(String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logLine = '[$timestamp] $message';
    _logs.add(logLine);
    _logStreamController.add(logLine);
    if (kDebugMode) print(logLine);
  }

  List<String> get logs => List.unmodifiable(_logs);

  @override
  void dispose() {
    _logStreamController.close();
    super.dispose();
  }
}
