import 'dart:html' as html;
import 'dart:typed_data';

String? createBlobUrl(Uint8List bytes) {
  final blob = html.Blob([bytes]);
  return html.Url.createObjectUrlFromBlob(blob);
}
