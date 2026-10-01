/** One value per distinct *kind* of notification this app creates —
 * deliberately NOT the same thing as `NotificationLinkTarget`, which only
 * says where tapping a notification navigates. Several semantically
 * different notifications share one `linkTarget` (e.g. "your task is due
 * soon" and "someone updated progress on a task you assigned" are both
 * `TASKS`), so muting had to be keyed on something more granular — this
 * enum has exactly one value per `NotificationsService.create` call site in
 * the app, so a user can mute precisely the kind they don't want. */
export enum NotificationCategory {
  TASK_PROGRESS_UPDATE = 'task_progress_update',
  TASK_DEADLINE_REMINDER = 'task_deadline_reminder',
  REQUEST_AWAITING_APPROVAL = 'request_awaiting_approval',
  EMPLOYEE_OF_MONTH = 'employee_of_month',
  PERFORMANCE_REVIEW_CREATED = 'performance_review_created',
  PERFORMANCE_REVIEW_ACTION_NEEDED = 'performance_review_action_needed',
  LEAVE_APPLIED_FOR_YOU = 'leave_applied_for_you',
  LEAVE_BALANCE_RESET = 'leave_balance_reset',
  LEAVE_RESET_ADMIN_SUMMARY = 'leave_reset_admin_summary',
  PAYROLL_PAID = 'payroll_paid',
}

export const NOTIFICATION_CATEGORY_LABELS: Record<
  NotificationCategory,
  string
> = {
  [NotificationCategory.TASK_PROGRESS_UPDATE]:
    'Task progress updates (on tasks you assigned)',
  [NotificationCategory.TASK_DEADLINE_REMINDER]:
    'Task deadline reminders (on tasks assigned to you)',
  [NotificationCategory.REQUEST_AWAITING_APPROVAL]:
    'Requests awaiting your approval',
  [NotificationCategory.EMPLOYEE_OF_MONTH]: 'Employee of the Month',
  [NotificationCategory.PERFORMANCE_REVIEW_CREATED]:
    'A performance review was created for you',
  [NotificationCategory.PERFORMANCE_REVIEW_ACTION_NEEDED]:
    'A performance review needs your action',
  [NotificationCategory.LEAVE_APPLIED_FOR_YOU]: 'Leave applied on your behalf',
  [NotificationCategory.LEAVE_BALANCE_RESET]: 'Your leave balance was reset',
  [NotificationCategory.LEAVE_RESET_ADMIN_SUMMARY]:
    'Annual leave reset summary (HR/Admin)',
  [NotificationCategory.PAYROLL_PAID]: 'Payroll paid',
};
