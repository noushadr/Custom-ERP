import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/date_format.dart';
import '../../../../shared/widgets/form_section.dart';
import '../../../authentication/application/auth_providers.dart';
import '../../../authentication/application/auth_state.dart';
import '../../../employee/application/employee_providers.dart';
import '../../application/performance_review_providers.dart';
import '../../domain/entities/performance_review.dart';
import '../../domain/entities/performance_review_response.dart';
import '../../domain/entities/performance_review_response_input.dart';
import '../../domain/exceptions/performance_review_exception.dart';
import '../widgets/performance_review_status_badge.dart';

/// Shows one employee's performance review for one year of service: the
/// manager/HR-filled ratings and feedback per criterion, the employee's
/// optional self-assessment, and the complete/finalize workflow actions —
/// gated per viewer role, resolved from who the caller actually is relative
/// to this specific review (self / their reporting manager / HR-Admin),
/// mirroring how the backend enforces the same checks server-side.
class PerformanceReviewDetailPage extends ConsumerWidget {
  const PerformanceReviewDetailPage({super.key, required this.reviewId});

  final String reviewId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewAsync = ref.watch(performanceReviewProvider(reviewId));
    final authState = ref.watch(authControllerProvider);
    final authUser = authState is AuthAuthenticated ? authState.user : null;
    final hasOverride = authUser?.hasPermission('performance.manage') ?? false;

    final myProfileAsync = ref.watch(myProfileProvider);
    final myEmployeeId = switch (myProfileAsync) {
      AsyncData(:final value) => value.id,
      _ => null,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Performance Review')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: reviewAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Could not load this review.'),
            ),
            data: (review) => _ReviewForm(
              review: review,
              hasOverride: hasOverride,
              isSelf: myEmployeeId != null && myEmployeeId == review.employeeId,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewForm extends ConsumerStatefulWidget {
  const _ReviewForm({
    required this.review,
    required this.hasOverride,
    required this.isSelf,
  });

  final PerformanceReview review;
  final bool hasOverride;
  final bool isSelf;

  @override
  ConsumerState<_ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends ConsumerState<_ReviewForm> {
  late Map<String, int?> _ratings;
  late Map<String, TextEditingController> _textControllers;
  late TextEditingController _selfAssessmentController;
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _ratings = {
      for (final response in widget.review.responses)
        response.id: response.ratingValue,
    };
    _textControllers = {
      for (final response in widget.review.responses)
        response.id: TextEditingController(text: response.textValue),
    };
    _selfAssessmentController = TextEditingController(
      text: widget.review.employeeComments,
    );
  }

  @override
  void dispose() {
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    _selfAssessmentController.dispose();
    super.dispose();
  }

  void _invalidate() {
    ref.invalidate(performanceReviewProvider(widget.review.id));
    ref.invalidate(myPerformanceReviewsProvider);
    ref.invalidate(pendingManagerActionReviewsProvider);
    ref.invalidate(pendingHrFinalizationReviewsProvider);
  }

  List<PerformanceReviewResponseInput> _collectResponses() {
    return [
      for (final response in widget.review.responses)
        PerformanceReviewResponseInput(
          responseId: response.id,
          ratingValue: response.responseType == 'rating'
              ? _ratings[response.id]
              : null,
          textValue: response.responseType == 'text'
              ? _textControllers[response.id]!.text.trim()
              : null,
        ),
    ];
  }

  Future<void> _saveResponses() async {
    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      final repository = ref.read(performanceReviewRepositoryProvider);
      if (widget.review.status == 'pending') {
        await repository.completeReview(
          widget.review.id,
          responses: _collectResponses(),
        );
      } else {
        await repository.adminUpdateReview(
          widget.review.id,
          responses: _collectResponses(),
        );
      }
      _invalidate();
    } on PerformanceReviewException catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveSelfAssessment() async {
    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      await ref
          .read(performanceReviewRepositoryProvider)
          .setSelfAssessment(
            widget.review.id,
            _selfAssessmentController.text.trim(),
          );
      _invalidate();
    } on PerformanceReviewException catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _finalize() async {
    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      await ref
          .read(performanceReviewRepositoryProvider)
          .finalizeReview(widget.review.id);
      _invalidate();
    } on PerformanceReviewException catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final review = widget.review;
    final isFinalized = review.status == 'finalized';
    // The frontend doesn't know the review employee's reportingManagerId, so
    // "not self" stands in for "must be the manager" here — every path that
    // reaches this page for someone else's review (the "Awaiting My Action"
    // queue, the profile section gated by performance.manage) already
    // filtered to reviews this viewer is actually allowed to act on. The
    // backend re-checks the real identity regardless, so a mistaken frontend
    // guess here is only ever a UX gap, never a security one.
    final canEditResponses =
        !isFinalized &&
        (widget.hasOverride ||
            (review.status == 'pending' && !widget.isSelf));
    final canFinalize = widget.hasOverride && review.status == 'completed';
    final canEditSelfAssessment = widget.isSelf && !isFinalized;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FormSection(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.employeeName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Year ${review.reviewYear} Review · Due ${formatDisplayDate(review.dueDate)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                PerformanceReviewStatusBadge(status: review.status),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_errorMessage != null) ...[
            Text(
              _errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 12),
          ],
          FormSection(
            title: 'Review Areas',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < review.responses.length; i++) ...[
                  _ResponseField(
                    response: review.responses[i],
                    editable: canEditResponses,
                    rating: _ratings[review.responses[i].id],
                    onRatingChanged: (value) => setState(
                      () => _ratings[review.responses[i].id] = value,
                    ),
                    textController: _textControllers[review.responses[i].id]!,
                  ),
                  if (i < review.responses.length - 1)
                    const Divider(height: 24, color: AppColors.borderSubtle),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          FormSection(
            title: 'Employee Self-Assessment',
            child: TextField(
              controller: _selfAssessmentController,
              enabled: canEditSelfAssessment && !_saving,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: canEditSelfAssessment
                    ? 'Optional — add your own comments about this review period'
                    : null,
                border: canEditSelfAssessment
                    ? const OutlineInputBorder()
                    : InputBorder.none,
              ),
            ),
          ),
          if (review.completedByName != null) ...[
            const SizedBox(height: 8),
            Text(
              'Completed by ${review.completedByName}'
              '${review.completedAt != null ? ' · ${formatDisplayDateTime(review.completedAt!)}' : ''}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
          if (review.finalizedByName != null) ...[
            const SizedBox(height: 4),
            Text(
              'Finalized by ${review.finalizedByName}'
              '${review.finalizedAt != null ? ' · ${formatDisplayDateTime(review.finalizedAt!)}' : ''}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (canEditSelfAssessment) ...[
                OutlinedButton(
                  onPressed: _saving ? null : _saveSelfAssessment,
                  child: const Text('Save Comments'),
                ),
                const SizedBox(width: 12),
              ],
              if (canEditResponses) ...[
                FilledButton(
                  onPressed: _saving ? null : _saveResponses,
                  child: _saving
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          review.status == 'pending'
                              ? 'Complete Review'
                              : 'Save Changes',
                        ),
                ),
              ],
              if (canFinalize) ...[
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _saving ? null : _finalize,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success,
                  ),
                  child: const Text('Finalize'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ResponseField extends StatelessWidget {
  const _ResponseField({
    required this.response,
    required this.editable,
    required this.rating,
    required this.onRatingChanged,
    required this.textController,
  });

  final PerformanceReviewResponse response;
  final bool editable;
  final int? rating;
  final ValueChanged<int?> onRatingChanged;
  final TextEditingController textController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          response.criterionName,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (response.responseType == 'rating')
          Row(
            children: [
              for (var star = 1; star <= 5; star++)
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: Icon(
                    rating != null && star <= rating!
                        ? Icons.star
                        : Icons.star_border,
                    color: AppColors.warning,
                  ),
                  onPressed: editable
                      ? () => onRatingChanged(star == rating ? null : star)
                      : null,
                ),
              if (!editable && rating == null)
                Text(
                  'Not rated',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          )
        else
          TextField(
            controller: textController,
            enabled: editable,
            maxLines: 3,
            decoration: InputDecoration(
              border: editable ? const OutlineInputBorder() : InputBorder.none,
              hintText: editable ? 'Add feedback' : null,
              isDense: true,
            ),
          ),
      ],
    );
  }
}
