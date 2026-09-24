import 'package:flutter/material.dart';

/// A titled card used to group related fields on edit/profile forms.
class FormSection extends StatelessWidget {
  const FormSection({
    super.key,
    this.title,
    this.trailing,
    this.titleSpacing = 12,
    required this.child,
  });

  final String? title;

  /// An optional action shown at the end of the title row (e.g. a button)
  /// — ignored when [title] is null.
  final Widget? trailing;

  /// Gap between the title row and [child] — defaults to 12, matching every
  /// existing call site; a section whose content sits tight against its
  /// title (e.g. a one-line empty state) can pass something smaller.
  final double titleSpacing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title!,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  ?trailing,
                ],
              ),
              SizedBox(height: titleSpacing),
            ],
            child,
          ],
        ),
      ),
    );
  }
}
