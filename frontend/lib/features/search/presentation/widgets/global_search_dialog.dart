import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../application/search_providers.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/exceptions/search_exception.dart';

/// Opened from the top bar's search icon — a single dialog searching
/// Employees/Tasks/Projects/Clients/Knowledge Base articles/Leads at once,
/// each category only populated when the viewer's own permissions already
/// allow seeing that module (mirrors the backend's own per-category gating,
/// see `SearchService`). Tapping a result closes the dialog and hands the
/// tapped item to whichever `onOpenX` callback matches its type — the
/// caller (the app shell) owns actual cross-section navigation, same
/// division of responsibility as `NotificationBell`'s own `onOpenX` props.
class GlobalSearchDialog extends StatefulWidget {
  const GlobalSearchDialog({
    super.key,
    required this.onOpenEmployee,
    required this.onOpenTask,
    required this.onOpenProject,
    required this.onOpenClient,
    required this.onOpenArticle,
    required this.onOpenLead,
  });

  final ValueChanged<String> onOpenEmployee;
  final ValueChanged<String> onOpenTask;
  final ValueChanged<String> onOpenProject;
  final ValueChanged<String> onOpenClient;
  final ValueChanged<String> onOpenArticle;
  final ValueChanged<String> onOpenLead;

  @override
  State<GlobalSearchDialog> createState() => _GlobalSearchDialogState();
}

class _GlobalSearchDialogState extends State<GlobalSearchDialog> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => setState(() => _query = value),
    );
  }

  void _openResult(SearchResultItem item) {
    Navigator.of(context).pop();
    switch (item.type) {
      case SearchResultType.employee:
        widget.onOpenEmployee(item.id);
      case SearchResultType.task:
        widget.onOpenTask(item.id);
      case SearchResultType.project:
        widget.onOpenProject(item.id);
      case SearchResultType.client:
        widget.onOpenClient(item.id);
      case SearchResultType.article:
        widget.onOpenArticle(item.id);
      case SearchResultType.lead:
        widget.onOpenLead(item.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(top: 80, left: 20, right: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 520),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _controller,
                autofocus: true,
                onChanged: _onChanged,
                decoration: InputDecoration(
                  hintText: 'Search employees, tasks, projects, articles…',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _controller.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            _controller.clear();
                            setState(() => _query = '');
                          },
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: _Results(query: _query, onTap: _openResult),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results({required this.query, required this.onTap});

  final String query;
  final ValueChanged<SearchResultItem> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (query.trim().length < 2) {
      return const _Hint('Type at least 2 characters to search.');
    }

    final resultsAsync = ref.watch(searchResultsProvider(query));

    return resultsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) =>
          _Hint(error is SearchException ? error.message : 'Could not search.'),
      data: (results) {
        if (results.isEmpty) {
          return const _Hint('No results found.');
        }
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _ResultSection(
                label: 'Employees',
                icon: Icons.badge_outlined,
                items: results.employees,
                onTap: onTap,
              ),
              _ResultSection(
                label: 'Tasks',
                icon: Icons.checklist_outlined,
                items: results.tasks,
                onTap: onTap,
              ),
              _ResultSection(
                label: 'Projects',
                icon: Icons.work_outline,
                items: results.projects,
                onTap: onTap,
              ),
              _ResultSection(
                label: 'Clients',
                icon: Icons.apartment_outlined,
                items: results.clients,
                onTap: onTap,
              ),
              _ResultSection(
                label: 'Knowledge Base',
                icon: Icons.menu_book_outlined,
                items: results.articles,
                onTap: onTap,
              ),
              _ResultSection(
                label: 'Leads',
                icon: Icons.person_add_alt_outlined,
                items: results.leads,
                onTap: onTap,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          message,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _ResultSection extends StatelessWidget {
  const _ResultSection({
    required this.label,
    required this.icon,
    required this.items,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final List<SearchResultItem> items;
  final ValueChanged<SearchResultItem> onTap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          for (final item in items)
            InkWell(
              onTap: () => onTap(item),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Row(
                  children: [
                    Icon(icon, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          if (item.subtitle != null)
                            Text(
                              item.subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
