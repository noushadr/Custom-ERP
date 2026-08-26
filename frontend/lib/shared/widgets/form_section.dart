import 'package:flutter/material.dart';

/// A titled card used to group related fields on edit/profile forms.
class FormSection extends StatelessWidget {
  const FormSection({
    super.key,
    this.title,
    this.trailing,
    required this.child,
  });

  final String? title;

  /// An optional action shown at the end of the title row (e.g. a button)
  /// — ignored when [title] is null.
  final Widget? trailing;
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
              const SizedBox(height: 12),
            ],
            child,
          ],
        ),
      ),
    );
  }
}
