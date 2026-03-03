import 'dart:io';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../helpers/config.dart';
import '../helpers/managers/log_manager.dart';
import '../helpers/managers/progress_manager.dart';
import '../helpers/managers/queue_manager.dart';
import '../helpers/utils/file_utils.dart';
import '../helpers/utils/erome_utils.dart';
import '../models/download_task.dart';
import 'erome_service.dart';

class DownloadManager extends ChangeNotifier {
  final ProgressManager progressManager;
  final LogManager logManager;
  final QueueManager queueManager;
  final Dio _dio;
  final Map<String, CancelToken> _cancelTokens = {};
  int _activeDownloads = 0;

  DownloadManager(this.progressManager, this.logManager, this.queueManager)
      : _dio = Dio(
          BaseOptions(
            connectTimeout: Duration(seconds: Config.connectionTimeoutSeconds),
            headers: {'User-Agent': Config.userAgent},
          ),
        ) {
    _initForegroundService();
    _processNextFromQueue();
  }

  void _initForegroundService() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'download_channel',
        channelName: 'Download Service',
        channelDescription: 'Used for downloading albums in background',
        priority: NotificationPriority.HIGH,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        interval: 5000,
        isOnceEvent: false,
        autoRunOnBoot: false,
        allowWakeLock: true,
      ),
    );
  }

  Future<void> startDownload(String albumUrl) async {
    if (!EromeUtils.isValidAlbumUrl(albumUrl)) {
      logManager.addLog('Invalid album URL: $albumUrl');
      return;
    }

    try {
      final albumId = EromeUtils.extractAlbumId(albumUrl)!;
      final service = EromeService(logManager);
      final mediaUrls = await service.fetchMediaUrls(albumUrl);

      if (mediaUrls.isEmpty) {
        logManager.addLog('No media found in album.');
        return;
      }

      final tempDir = await FileUtils.getAppTempDir();

      for (int i = 0; i < mediaUrls.length; i++) {
        final url = mediaUrls[i];
        final fileName = FileUtils.generateFileName(url, albumId, i + 1);
        final tempPath = '${tempDir.path}/$fileName';
        final taskId = '$albumId-$i';

        final task = DownloadTask(
          id: taskId,
          albumUrl: url, // store the actual media URL
          fileName: fileName,
          tempPath: tempPath,
        );
        progressManager.addTask(task);
        queueManager.addToQueue(task);
      }

      _processNextFromQueue();
    } catch (e, stack) {
      logManager.addLog('Download preparation error: $e');
    }
  }

  void _processNextFromQueue() {
    if (_activeDownloads >= Config.maxConcurrentDownloads) return;
    if (queueManager.queue.isEmpty) return;

    final nextTask = queueManager.queue.firstWhere(
      (t) => t.status == DownloadStatus.pending,
      orElse: () => null as DownloadTask,
    );
    if (nextTask == null) return;

    _activeDownloads++;
    nextTask.status = DownloadStatus.downloading;
    progressManager.notifyListeners();
    queueManager.removeFromQueue(nextTask);

    _performDownload(nextTask);
  }

  Future<void> _performDownload(DownloadTask task) async {
    final cancelToken = CancelToken();
    _cancelTokens[task.id] = cancelToken;

    File file = File(task.tempPath);
    int startBytes = 0;
    if (await file.exists()) {
      startBytes = await file.length();
    }

    try {
      final headResponse = await _dio.head(
        task.albumUrl,
        options: Options(responseType: ResponseType.plain),
      );
      final total = int.tryParse(headResponse.headers.value('content-length') ?? '0') ?? 0;
      task.totalBytes = total;

      final options = Options(
        headers: {'Range': 'bytes=$startBytes-'},
        responseType: ResponseType.stream,
      );

      await _dio.download(
        task.albumUrl,
        task.tempPath,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          progressManager.updateProgress(task.id, startBytes + received, startBytes + total);
          _updateForegroundNotification(task);
        },
      );

      _onDownloadComplete(task);
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        logManager.addLog('Download cancelled: ${task.id}');
        progressManager.removeTask(task.id);
      } else {
        logManager.addLog('Download failed: ${task.id} - $e');
        task.status = DownloadStatus.failed;
        task.error = e.toString();
        progressManager.notifyListeners();
      }
    } finally {
      _cancelTokens.remove(task.id);
      _activeDownloads--;
      _processNextFromQueue();
    }
  }

  void _onDownloadComplete(DownloadTask task) async {
    task.status = DownloadStatus.completed;
    progressManager.markCompleted(task.id);
    logManager.addLog('Download completed: ${task.fileName}');

    try {
      await FileUtils.saveToGallery(task.tempPath);
      logManager.addLog('Saved to gallery: ${task.fileName}');
    } catch (e) {
      logManager.addLog('Failed to save to gallery: $e');
    }

    final file = File(task.tempPath);
    if (await file.exists()) await file.delete();
  }

  void _updateForegroundNotification(DownloadTask task) {
    if (!FlutterForegroundTask.isRunningService) return;
    FlutterForegroundTask.updateService(
      notificationTitle: 'Downloading ${task.fileName}',
      notificationText: '${(task.progress * 100).toStringAsFixed(1)}%',
    );
  }

  void cancelDownload(String taskId) {
    _cancelTokens[taskId]?.cancel();
    progressManager.removeTask(taskId);
    logManager.addLog('Cancelled task $taskId');
  }

  void pauseDownload(String taskId) {
    _cancelTokens[taskId]?.cancel();
    final task = progressManager.tasks.firstWhere((t) => t.id == taskId);
    task.status = DownloadStatus.paused;
    progressManager.notifyListeners();
    queueManager.addToQueue(task);
    logManager.addLog('Paused task $taskId');
  }

  @override
  void dispose() {
    FlutterForegroundTask.stopService();
    super.dispose();
  }
}
