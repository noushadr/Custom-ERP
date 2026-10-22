import 'package:flutter/material.dart';
import '../../domain/entities/notice_display_duration.dart';

/// Picks how long a notice stays visible: 1 day, 3 days, 1 week, 2 weeks,
/// 1 month, or always. Used by both the Post and the Edit dialogs.
///
/// When [keepCurrentLabel] is given the field gains a leading "leave it as it
/// is" choice whose value is null (the Edit dialog, where picking a preset
/// restarts the window from now but doing nothing keeps the current end
/// date). Without it a duration is always selected (the Post dialog).
class NoticeDurationField extends StatelessWidget {
  const NoticeDurationField({
    super.key,
    required this.value,
    required this.onChanged,
    this.labelText = 'Show for',
    this.keepCurrentLabel,
    this.helperText,
    this.enabled = true,
  });

  final NoticeDisplayDuration? value;
  final ValueChanged<NoticeDisplayDuration?> onChanged;
  final String labelText;
  final String? keepCurrentLabel;
  final String? helperText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<NoticeDisplayDuration?>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: labelText, helperText: helperText),
      items: [
        if (keepCurrentLabel != null)
          DropdownMenuItem<NoticeDisplayDuration?>(
            value: null,
            child: Text(keepCurrentLabel!),
          ),
        for (final duration in NoticeDisplayDuration.values)
          DropdownMenuItem<NoticeDisplayDuration?>(
            value: duration,
            child: Text(duration.label),
          ),
      ],
      onChanged: enabled ? onChanged : null,
    );
  }
}
