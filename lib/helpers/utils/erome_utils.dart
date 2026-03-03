class EromeUtils {
  static bool isValidAlbumUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    return uri.host == 'www.erome.com' && uri.path.startsWith('/a/');
  }

  static String? extractAlbumId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !isValidAlbumUrl(url)) return null;
    return uri.pathSegments.last;
  }

  static String sanitizeFilename(String filename) {
    return filename.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }
}
