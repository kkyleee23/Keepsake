import 'package:flutter/gestures.dart';

/// A pan that claims the drag the moment a finger lands, so a scrolling
/// sheet underneath doesn't take it (stickers, the signature pad).
class EagerPan extends PanGestureRecognizer {
  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }
}
