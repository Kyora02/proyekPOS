class Blob {
  Blob(List<dynamic> content, String type);
}

class Url {
  static String createObjectUrlFromBlob(dynamic blob) => '';
  static void revokeObjectUrl(String url) {}
}

class window {
  static void open(String url, String target) {}
}