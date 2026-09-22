import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// A row of numbered page buttons + prev/next chevrons — the same pager
/// shape Company Notices originally built for itself, extracted here so any
/// other client-side-paginated list (e.g. an employee's Change History) can
/// reuse it instead of re-implementing the same widget privately.
class SimplePager extends StatelessWidget {
  const SimplePager({
    super.key,
    required this.page,
    required this.totalPages,
    required this.onSelect,
  });

  /// Zero-based current page.
  final int page;
  final int totalPages;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, size: 20),
          tooltip: 'Previous page',
          onPressed: page > 0 ? () => onSelect(page - 1) : null,
        ),
        for (var p = 0; p < totalPages; p++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: _PageNumberButton(
              pageNumber: p + 1,
              isSelected: p == page,
              onTap: () => onSelect(p),
            ),
          ),
        IconButton(
          icon: const Icon(Icons.chevron_right, size: 20),
          tooltip: 'Next page',
          onPressed: page < totalPages - 1 ? () => onSelect(page + 1) : null,
        ),
      ],
    );
  }
}

class _PageNumberButton extends StatelessWidget {
  const _PageNumberButton({
    required this.pageNumber,
    required this.isSelected,
    required this.onTap,
  });

  final int pageNumber;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: isSelected ? null : onTap,
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '$pageNumber',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
