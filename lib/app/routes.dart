import '../data/models/keepsake.dart';

/// Where tapping a keepsake goes: drafts open in the editor, your published
/// ones open their detail page (link, QR, replies), and anything received
/// opens to read.
String keepsakeRoute(Keepsake k) {
  if (k.isDraft) return '/editor/${k.id}';
  if (!k.isReceived && k.shareToken != null) return '/published/${k.id}';
  return '/preview/${k.id}';
}
