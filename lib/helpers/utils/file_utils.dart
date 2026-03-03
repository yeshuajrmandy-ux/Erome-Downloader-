import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'erome_utils.dart';

class FileUtils {
  static Future<Directory> getAppTempDir() async {
    final dir = await getTemporaryDirectory();
    final tempDir = Directory('${dir.path}/EromeTemp');
    if (!await tempDir.exists()) {
      await tempDir.create(recursive: true);
    }
    return tempDir;
  }

  static Future<void> saveToGallery(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return;

    if (filePath.endsWith('.mp4') || filePath.endsWith('.mov')) {
      await GallerySaver.saveVideo(filePath, albumName: 'Erome');
    } else {
      await GallerySaver.saveImage(filePath, albumName: 'Erome');
    }
  }

  static String generateFileName(String url, String albumId, int index) {
    final uri = Uri.parse(url);
    final extension = uri.path.split('.').last;
    return '${EromeUtils.sanitizeFilename(albumId)}_$index.$extension';
  }
}
