import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/date_format.dart';
import '../../../../shared/widgets/form_section.dart';
import '../../../employee/presentation/pages/employee_profile_page.dart';
import '../../../employee/presentation/widgets/employee_avatar.dart';
import '../../../authentication/application/auth_providers.dart';
import '../../../authentication/application/auth_state.dart';
import '../../../employee/application/employee_providers.dart';
import '../../application/performance_review_providers.dart';
import '../../domain/entities/performance_review.dart';
import '../../domain/entities/performance_review_form_fields.dart';
import '../../domain/entities/performance_review_response.dart';
import '../../domain/entities/performance_review_response_input.dart';
import '../../domain/exceptions/performance_review_exception.dart';
import '../widgets/performance_review_status_badge.dart';

/// Shows one employee's performance review for one year of service: the
/// manager/HR-filled ratings and feedback per criterion, the employee's
/// optional self-assessment, and the complete/finalize/unfinalize workflow
/// actions — gated per viewer role, resolved from who the caller actually
/// is relative to this specific review (self / their reporting manager /
/// HR-Admin), mirroring how the backend enforces the same checks
/// server-side. Unfinalize (HR/Admin only, same as Finalize) reverts a
/// finalized review back to Completed so a mistake can be fixed and it can
/// be finalized again.
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
            error: (error, _) => Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                error is PerformanceReviewException
                    ? error.message
                    : 'Could not load this review.',
              ),
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
  late Map<String, TextEditingController> _commentControllers;
  late TextEditingController _selfAssessmentController;
  String? _overallRating;
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
    _commentControllers = {
      for (final response in widget.review.responses)
        response.id: TextEditingController(text: response.commentValue),
    };
    _selfAssessmentController = TextEditingController(
      text: widget.review.employeeComments,
    );
    _overallRating = widget.review.overallRating;
  }

  @override
  void dispose() {
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    for (final controller in _commentControllers.values) {
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
          commentValue: response.hasComment
              ? _commentControllers[response.id]!.text.trim()
              : null,
        ),
    ];
  }

  PerformanceReviewFormFields _collectFields() =>
      PerformanceReviewFormFields(overallRating: _overallRating);

  Future<void> _saveDraft() async {
    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      await ref
          .read(performanceReviewRepositoryProvider)
          .saveDraft(
            widget.review.id,
            responses: _collectResponses(),
            fields: _collectFields(),
          );
      _invalidate();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Draft saved')));
      }
    } on PerformanceReviewException catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
          fields: _collectFields(),
        );
      } else {
        await repository.adminUpdateReview(
          widget.review.id,
          responses: _collectResponses(),
          fields: _collectFields(),
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
    if (_selfAssessmentController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Your feedback is required.');
      return;
    }
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

  Future<void> _unfinalize() async {
    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      await ref
          .read(performanceReviewRepositoryProvider)
          .unfinalizeReview(widget.review.id);
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
        (widget.hasOverride || (review.status == 'pending' && !widget.isSelf));
    final feedbackGiven = _selfAssessmentController.text.trim().isNotEmpty;
    final canFinalize =
        widget.hasOverride && review.status == 'completed' && feedbackGiven;
    final canUnfinalize = widget.hasOverride && isFinalized;
    // The employee writes their feedback only after management has submitted
    // the evaluation, and only until HR finalizes it.
    final canEditSelfAssessment = widget.isSelf && review.status == 'completed';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FormSection(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EmployeeAvatar(
                  fullName: review.employeeName,
                  photoUrl: review.employeePhotoUrl,
                  radius: 28,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EmployeeProfilePage(
                              employeeId: review.employeeId,
                            ),
                          ),
                        ),
                        child: Text(
                          review.employeeName,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: AppColors.primary,
                                decoration: TextDecoration.underline,
                              ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${review.title} · Due ${formatDisplayDate(review.dueDate)}',
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
          if (widget.isSelf && review.status != 'pending') ...[
            _ManagementFilledBanner(review: review),
            const SizedBox(height: 16),
          ],
          if (_errorMessage != null) ...[
            Text(
              _errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 12),
          ],
          FormSection(
            title: 'Employee Information',
            child: _EmployeeInformation(review: review),
          ),
          const SizedBox(height: 16),
          for (final group in _groupBySection(review.responses)) ...[
            FormSection(
              title: group.title,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (group.responses.any((r) => r.responseType == 'rating'))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _ratingScale,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  for (var i = 0; i < group.responses.length; i++) ...[
                    _ResponseField(
                      response: group.responses[i],
                      editable: canEditResponses,
                      rating: _ratings[group.responses[i].id],
                      onRatingChanged: (value) => setState(
                        () => _ratings[group.responses[i].id] = value,
                      ),
                      textController: _textControllers[group.responses[i].id]!,
                      commentController:
                          _commentControllers[group.responses[i].id]!,
                    ),
                    if (i < group.responses.length - 1)
                      const Divider(height: 24, color: AppColors.borderSubtle),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          FormSection(
            title: 'Overall Performance Rating',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in overallRatingLabels.entries)
                  ChoiceChip(
                    label: Text(option.value),
                    selected: _overallRating == option.key,
                    onSelected: canEditResponses
                        ? (selected) => setState(
                            () => _overallRating = selected ? option.key : null,
                          )
                        : null,
                  ),
                if (!canEditResponses && _overallRating == null)
                  Text(
                    'Not rated',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FormSection(
            title: canEditSelfAssessment
                ? 'Employee Feedback (required)'
                : 'Employee Feedback',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _selfAssessmentController,
                  enabled: canEditSelfAssessment && !_saving,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: canEditSelfAssessment
                        ? 'Required — write your own feedback on this review'
                        : null,
                    border: canEditSelfAssessment
                        ? const OutlineInputBorder()
                        : InputBorder.none,
                  ),
                ),
                if (!canEditSelfAssessment)
                  Text(
                    isFinalized
                        ? 'Not editable: this review has been finalized, so '
                              'feedback can no longer be changed.'
                        : widget.isSelf
                        ? 'Not editable yet: management is still filling in '
                              'your review. You can add your feedback once '
                              'they submit it.'
                        : review.status == 'pending'
                        ? 'Not editable: only ${review.employeeName} can write '
                              'their own feedback, from their own account. '
                              'They can see this review and add their '
                              'feedback only after you complete it, and '
                              'their feedback is required before it can be '
                              'finalized.'
                        : 'Not editable: only ${review.employeeName} can write '
                              'their own feedback, from their own account. '
                              'This review is now open to them, and their '
                              'feedback is required before it can be '
                              'finalized.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
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
          if (canEditResponses && review.status == 'pending') ...[
            Text(
              'Save Draft keeps your answers and leaves this review open. '
              'Complete Review submits it and records today as the date of '
              'evaluation.',
              textAlign: TextAlign.end,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (canEditSelfAssessment) ...[
                OutlinedButton(
                  onPressed: _saving ? null : _saveSelfAssessment,
                  child: const Text('Submit Feedback'),
                ),
                const SizedBox(width: 12),
              ],
              if (canEditResponses && review.status == 'pending') ...[
                OutlinedButton(
                  onPressed: _saving ? null : _saveDraft,
                  child: const Text('Save Draft'),
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
              if (canUnfinalize) ...[
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: _saving ? null : _unfinalize,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.warning,
                    side: const BorderSide(color: AppColors.warning),
                  ),
                  child: const Text('Unfinalize'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

const _ratingScale =
    '1 = Needs Improvement | 2 = Fair | 3 = Good | 4 = Very Good | 5 = Excellent';

class _SectionGroup {
  _SectionGroup(this.title) : responses = [];

  final String? title;
  final List<PerformanceReviewResponse> responses;
}

/// Consecutive responses that share a section render together under that
/// section's heading; ungrouped ones (no section) share one untitled card.
List<_SectionGroup> _groupBySection(List<PerformanceReviewResponse> all) {
  final groups = <_SectionGroup>[];
  for (final response in all) {
    final section = (response.section?.isNotEmpty ?? false)
        ? response.section
        : null;
    if (groups.isEmpty || groups.last.title != section) {
      groups.add(_SectionGroup(section));
    }
    groups.last.responses.add(response);
  }
  return groups;
}

class _EmployeeInformation extends StatelessWidget {
  const _EmployeeInformation({required this.review});

  final PerformanceReview review;

  @override
  Widget build(BuildContext context) {
    String orDash(String? value) =>
        (value == null || value.isEmpty) ? '—' : value;
    final evaluated = review.completedAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoRow(label: 'Name', value: review.employeeName),
        _InfoRow(label: 'Designation', value: orDash(review.designation)),
        _InfoRow(label: 'Department', value: orDash(review.department)),
        _InfoRow(
          label: 'Reporting Manager',
          value: orDash(review.reportingManagerName),
        ),
        _InfoRow(
          label: 'Review Period',
          value: review.title.replaceFirst(' Review', ''),
        ),
        // Set automatically when the review is submitted — nothing to type.
        if (evaluated != null)
          _InfoRow(
            label: 'Date of Evaluation',
            value: formatDisplayDate(evaluated.toIso8601String()),
          ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(child: Text(value)),
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
    required this.commentController,
  });

  final PerformanceReviewResponse response;
  final bool editable;
  final int? rating;
  final ValueChanged<int?> onRatingChanged;
  final TextEditingController textController;
  final TextEditingController commentController;

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
        if (response.responseType == 'rating') ...[
          Row(
            children: [
              for (var star = 1; star <= 5; star++)
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
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
          ),
          if (response.hasComment) ...[
            const SizedBox(height: 8),
            TextField(
              controller: commentController,
              enabled: editable,
              maxLines: 2,
              decoration: InputDecoration(
                border: editable
                    ? const OutlineInputBorder()
                    : InputBorder.none,
                hintText: editable ? 'Comments' : null,
                isDense: true,
              ),
            ),
          ],
        ] else
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

/// Shown to the reviewed employee: everything above their own feedback box
/// was filled in by management.
class _ManagementFilledBanner extends StatelessWidget {
  const _ManagementFilledBanner({required this.review});

  final PerformanceReview review;

  @override
  Widget build(BuildContext context) {
    final by = review.completedByName;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Everything below was filled in by management'
              '${by != null ? ' ($by)' : ''}. You can\'t change it — your '
              'feedback is required in the Employee Feedback section at the '
              'bottom.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
