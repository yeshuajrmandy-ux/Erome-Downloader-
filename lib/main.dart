import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'helpers/managers/log_manager.dart';
import 'helpers/managers/progress_manager.dart';
import 'helpers/managers/queue_manager.dart';
import 'services/download_manager.dart';
import 'screens/home_screen.dart';

void main() {
  final logManager = LogManager();
  final progressManager = ProgressManager();
  final queueManager = QueueManager();
  final downloadManager = DownloadManager(progressManager, logManager, queueManager);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => logManager),
        ChangeNotifierProvider(create: (_) => progressManager),
        ChangeNotifierProvider(create: (_) => queueManager),
        ChangeNotifierProvider(create: (_) => downloadManager),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Erome Downloader',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.green,
        colorScheme: const ColorScheme.dark(primary: Colors.green),
      ),
      home: const HomeScreen(),
    );
  }
}
