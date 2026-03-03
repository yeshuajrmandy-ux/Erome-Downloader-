import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../helpers/managers/progress_manager.dart';
import '../models/download_task.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProgressManager>(
      builder: (context, progressManager, child) {
        final tasks = progressManager.tasks;
        if (tasks.isEmpty) {
          return const Center(child: Text('No downloads yet'));
        }
        return ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                title: Text(task.fileName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status: ${task.status.name}'),
                    if (task.status == DownloadStatus.downloading)
                      LinearProgressIndicator(value: task.progress),
                    if (task.error != null)
                      Text('Error: ${task.error!}', style: const TextStyle(color: Colors.red)),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.cancel),
                  onPressed: () {
                    // You can later connect this to DownloadManager.cancelDownload
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
