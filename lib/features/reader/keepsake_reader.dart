import 'package:flutter/material.dart';

import '../../data/models/keepsake.dart';
import 'gift_cover.dart';
import 'keepsake_content_view.dart';

/// The recipient experience: a restrained sealed cover that opens into the
/// content. Shared by Preview and (later) the live recipient route so the
/// creator sees exactly what will be received.
class KeepsakeReader extends StatefulWidget {
  const KeepsakeReader({super.key, required this.keepsake});

  final Keepsake keepsake;

  @override
  State<KeepsakeReader> createState() => _KeepsakeReaderState();
}

class _KeepsakeReaderState extends State<KeepsakeReader> {
  bool _opened = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      child: _opened
          ? KeyedSubtree(
              key: const ValueKey('content'),
              child: KeepsakeContentView(keepsake: widget.keepsake),
            )
          : GiftCover(
              key: const ValueKey('cover'),
              occasion: widget.keepsake.occasion.label,
              recipientName: widget.keepsake.recipientName,
              title: widget.keepsake.title,
              coverNote: widget.keepsake.coverNote,
              senderName: widget.keepsake.senderName,
              onOpen: () => setState(() => _opened = true),
            ),
    );
  }
}
