enum DownloadStatus { pending, downloading, paused, completed, failed }

class DownloadTask {
  final String id;
  final String albumUrl;
  final String fileName;
  final String tempPath;
  String? finalPath;
  int receivedBytes;
  int totalBytes;
  DownloadStatus status;
  String? error;

  DownloadTask({
    required this.id,
    required this.albumUrl,
    required this.fileName,
    required this.tempPath,
    this.finalPath,
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.status = DownloadStatus.pending,
    this.error,
  });

  double get progress => totalBytes > 0 ? receivedBytes / totalBytes : 0.0;

  Map<String, dynamic> toJson() => {
    'id': id,
    'albumUrl': albumUrl,
    'fileName': fileName,
    'tempPath': tempPath,
    'finalPath': finalPath,
    'receivedBytes': receivedBytes,
    'totalBytes': totalBytes,
    'status': status.index,
    'error': error,
  };

  factory DownloadTask.fromJson(Map<String, dynamic> json) => DownloadTask(
    id: json['id'],
    albumUrl: json['albumUrl'],
    fileName: json['fileName'],
    tempPath: json['tempPath'],
    finalPath: json['finalPath'],
    receivedBytes: json['receivedBytes'] ?? 0,
    totalBytes: json['totalBytes'] ?? 0,
    status: DownloadStatus.values[json['status'] ?? 0],
    error: json['error'],
  );
}
