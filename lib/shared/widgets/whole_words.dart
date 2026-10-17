import 'package:flutter/material.dart';

/// A heading that never breaks a word in half. Text wraps between words as
/// usual; a single word too wide for the line (a long name with large text
/// turned on) shrinks to fit instead of splitting into "Maximilian / a".
///
/// Built from a [Wrap] rather than a LayoutBuilder so it still works inside
/// [FillScroll], which measures intrinsic height.
class WholeWords extends StatelessWidget {
  const WholeWords(
    this.text, {
    super.key,
    required this.style,
    this.textAlign = TextAlign.start,
  });

  final String text;
  final TextStyle style;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final words = text.trim().split(RegExp(r'\s+'));
    final painter = TextPainter(
      text: TextSpan(text: ' ', style: style),
      textScaler: MediaQuery.textScalerOf(context),
      textDirection: Directionality.of(context),
    )..layout();
    final space = painter.width;
    painter.dispose();

    return Semantics(
      label: text,
      header: true,
      child: ExcludeSemantics(
        child: Wrap(
          alignment: switch (textAlign) {
            TextAlign.center => WrapAlignment.center,
            TextAlign.end || TextAlign.right => WrapAlignment.end,
            _ => WrapAlignment.start,
          },
          spacing: space,
          children: [
            for (final w in words)
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(w, style: style, maxLines: 1, softWrap: false),
              ),
          ],
        ),
      ),
    );
  }
}
