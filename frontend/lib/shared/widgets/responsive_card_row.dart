import 'package:flutter/material.dart';

/// Lays [children] out in full-width rows instead of `Wrap`'s fixed-size
/// tiles — each row's items stretch (via `Expanded`) to fill the available
/// width evenly, so a wide screen never leaves a dead gap on the right where
/// a fixed-width `Wrap` would have simply run out of items. Column count per
/// row is however many [minItemWidth]-plus-[spacing] slots fit the current
/// width, recomputed on every layout via `LayoutBuilder` — the same
/// fits-then-wraps idea the Tasks board's own column layout uses.
class ResponsiveCardRow extends StatelessWidget {
  const ResponsiveCardRow({
    super.key,
    required this.children,
    this.minItemWidth = 240,
    this.spacing = 12,
    this.runSpacing = 12,
  });

  final List<Widget> children;
  final double minItemWidth;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        var columns =
            ((constraints.maxWidth + spacing) / (minItemWidth + spacing))
                .floor();
        if (columns < 1) columns = 1;
        if (columns > children.length) columns = children.length;

        final rows = <Widget>[];
        for (var i = 0; i < children.length; i += columns) {
          final end = i + columns > children.length
              ? children.length
              : i + columns;
          final rowItems = children.sublist(i, end);
          if (rows.isNotEmpty) rows.add(SizedBox(height: runSpacing));
          rows.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var j = 0; j < rowItems.length; j++) ...[
                  if (j > 0) SizedBox(width: spacing),
                  Expanded(child: rowItems[j]),
                ],
              ],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rows,
        );
      },
    );
  }
}
