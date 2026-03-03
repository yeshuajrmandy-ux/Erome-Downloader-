import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/download_task.dart';

class QueueManager extends ChangeNotifier {
  static const String _queueKey = 'download_queue';
  List<DownloadTask> _queue = [];

  List<DownloadTask> get queue => List.unmodifiable(_queue);

  QueueManager() {
    _loadQueue();
  }

  Future<void> _loadQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_queueKey);
    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      _queue = jsonList.map((e) => DownloadTask.fromJson(e)).toList();
      notifyListeners();
    }
  }

  Future<void> _saveQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _queue.map((e) => e.toJson()).toList();
    await prefs.setString(_queueKey, jsonEncode(jsonList));
  }

  void addToQueue(DownloadTask task) {
    _queue.add(task);
    _saveQueue();
    notifyListeners();
  }

  void removeFromQueue(DownloadTask task) {
    _queue.remove(task);
    _saveQueue();
    notifyListeners();
  }

  void clearQueue() {
    _queue.clear();
    _saveQueue();
    notifyListeners();
  }
}
