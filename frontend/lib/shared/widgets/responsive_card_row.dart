import 'package:flutter/material.dart';

/// Lays [children] out in evenly-sized rows instead of `Wrap`'s fixed-size
/// tiles — every item gets the same computed width (never just whichever
/// row it lands in), so a short trailing row can't stretch its one leftover
/// item to fill the whole row's width the way an `Expanded`-per-row layout
/// would. Column count per row is however many [minItemWidth]-plus-[spacing]
/// slots fit the current width, recomputed on every layout via
/// `LayoutBuilder` — the same fits-then-wraps idea the Tasks board's own
/// column layout uses. Each item is additionally capped at [maxWidthFraction]
/// of the available width, so a row with few items (e.g. a trailing row of
/// one) still can't grow a single card past a sane share of a very wide
/// screen.
///
/// With no [maxWidthFraction] (the default) the row instead *fills* its width:
/// the items are split into as few, evenly-balanced rows as the width allows
/// (e.g. five cards that only fit four across become 3 + 2, not 4 + 1), and
/// each row's items share that row's full width — no empty gap on the right.
class ResponsiveCardRow extends StatelessWidget {
  const ResponsiveCardRow({
    super.key,
    required this.children,
    this.minItemWidth = 240,
    this.spacing = 12,
    this.runSpacing = 12,
    this.maxWidthFraction,
  });

  final List<Widget> children;
  final double minItemWidth;
  final double spacing;
  final double runSpacing;

  /// No single item may exceed this fraction of the row's total width —
  /// e.g. 0.3 caps every card at 30%, regardless of how few items share its
  /// row.
  final double? maxWidthFraction;

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

        final fraction = maxWidthFraction;
        if (fraction == null) {
          // Balanced rows: as few as fit, each as even as possible.
          final rowCount = (children.length / columns).ceil();
          final base = children.length ~/ rowCount;
          final extra = children.length % rowCount;
          var index = 0;
          final rows = <Widget>[];
          for (var r = 0; r < rowCount; r++) {
            final count = base + (r < extra ? 1 : 0);
            final rowItems = children.sublist(index, index + count);
            index += count;
            rows.add(
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < rowItems.length; i++) ...[
                    if (i > 0) SizedBox(width: spacing),
                    Expanded(child: rowItems[i]),
                  ],
                ],
              ),
            );
          }
          return Column(
            children: [
              for (var r = 0; r < rows.length; r++) ...[
                if (r > 0) SizedBox(height: runSpacing),
                rows[r],
              ],
            ],
          );
        }

        // The cap only ever prevents a card from growing *past* a sane
        // share of a wide row — it must never pull an item below
        // [minItemWidth] itself, which would defeat the whole "at least
        // this wide" premise the column count above was already computed
        // from (e.g. on a narrower screen where 30% of the width happens to
        // be less than minItemWidth).
        final cap = constraints.maxWidth * fraction < minItemWidth
            ? minItemWidth
            : constraints.maxWidth * fraction;
        final itemWidth =
            ((constraints.maxWidth - spacing * (columns - 1)) / columns)
                .clamp(0, cap)
                .toDouble();

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}
