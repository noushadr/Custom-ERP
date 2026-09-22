import 'package:flutter/material.dart';

/// A filter chip toggling between a page's normal (non-archived) list and
/// its archived one — shared shape between the Employee Directory (resigned/
/// terminated employees) and Clients & Projects' Projects tab (On Hold/
/// Completed/Cancelled projects), both of which hide their "inactive" rows
/// by default and only surface them once this is selected.
class ArchivedToggle extends StatelessWidget {
  const ArchivedToggle({
    super.key,
    required this.showArchived,
    required this.onChanged,
  });

  final bool showArchived;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      avatar: const Icon(Icons.archive_outlined, size: 18),
      label: const Text('Archived'),
      selected: showArchived,
      onSelected: onChanged,
    );
  }
}
