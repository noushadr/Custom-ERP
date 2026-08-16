import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/date_format.dart';
import '../../../../shared/widgets/form_section.dart';
import '../../../authentication/application/auth_providers.dart';
import '../../../authentication/application/auth_state.dart';
import '../../../notices/application/notice_providers.dart';
import '../../../notices/domain/entities/notice.dart';
import '../../../notices/domain/exceptions/notice_exception.dart';

const _pageSize = 3;

/// Company-wide announcements, shown on both the Admin and User dashboards.
/// Each notice renders as its own highlighted callout card rather than a
/// plain text row, so it reads as an announcement worth noticing. Only the
/// latest 3 show by default; older ones are reachable via the pager below.
class CompanyNoticesSection extends ConsumerStatefulWidget {
  const CompanyNoticesSection({super.key});

  @override
  ConsumerState<CompanyNoticesSection> createState() =>
      _CompanyNoticesSectionState();
}

class _CompanyNoticesSectionState extends ConsumerState<CompanyNoticesSection> {
  int _page = 0;
  String? _deletingId;

  Future<void> _confirmDelete(Notice notice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete notice?'),
        content: Text(
          'This permanently removes "${notice.title}" for everyone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _deletingId = notice.id);
    try {
      await ref.read(noticeRepositoryProvider).delete(notice.id);
      ref.invalidate(noticeListProvider);
    } on NoticeException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _deletingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final noticesAsync = ref.watch(noticeListProvider);
    final authState = ref.watch(authControllerProvider);
    final canDelete =
        authState is AuthAuthenticated &&
        authState.user.hasPermission('notices.manage');

    return FormSection(
      title: 'Company Notices',
      child: noticesAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: LinearProgressIndicator(),
        ),
        error: (_, _) => const Text('Could not load company notices.'),
        data: (notices) {
          if (notices.isEmpty) {
            return Text(
              'No company notices yet.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            );
          }

          final totalPages = (notices.length / _pageSize).ceil();
          // Defends against the list shrinking (e.g. after a refetch) while a
          // later page was selected, without mutating state during build.
          final page = _page.clamp(0, totalPages - 1);
          final start = page * _pageSize;
          final pageNotices = notices.sublist(
            start,
            (start + _pageSize).clamp(0, notices.length),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < pageNotices.length; i++) ...[
                // Notices are already ordered newest-first, so only the very
                // first one overall is highlighted — older notices fade into
                // a neutral, less attention-grabbing style.
                _NoticeCard(
                  notice: pageNotices[i],
                  isLatest: start + i == 0,
                  onDelete: canDelete
                      ? () => _confirmDelete(pageNotices[i])
                      : null,
                  isDeleting: _deletingId == pageNotices[i].id,
                ),
                if (i < pageNotices.length - 1) const SizedBox(height: 10),
              ],
              if (totalPages > 1) ...[
                const SizedBox(height: 12),
                _NoticesPager(
                  page: page,
                  totalPages: totalPages,
                  onSelect: (selected) => setState(() => _page = selected),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _NoticesPager extends StatelessWidget {
  const _NoticesPager({
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

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.notice,
    required this.isLatest,
    this.onDelete,
    this.isDeleting = false,
  });

  final Notice notice;
  final bool isLatest;
  final VoidCallback? onDelete;
  final bool isDeleting;

  @override
  Widget build(BuildContext context) {
    final accent = isLatest ? AppColors.primary : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isLatest ? AppColors.primarySoft : AppColors.fieldFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isLatest
              ? AppColors.primary.withValues(alpha: 0.18)
              : AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isLatest ? 0.16 : 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.campaign_outlined, size: 18, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notice.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(notice.body, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
                Text(
                  '${notice.authorName} · ${formatDisplayDateTime(notice.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (onDelete != null)
            isDeleting
                ? const Padding(
                    padding: EdgeInsets.all(8),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    color: AppColors.error,
                    tooltip: 'Delete notice',
                    onPressed: onDelete,
                  ),
        ],
      ),
    );
  }
}
