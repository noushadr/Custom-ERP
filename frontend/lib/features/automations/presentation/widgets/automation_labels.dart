import '../../domain/entities/automation_type.dart';

String formatAutomationTypeLabel(String type) => switch (type) {
  AutomationType.projectRenewalReminder => 'Project Renewal Reminder',
  AutomationType.taskDeadlineReminder => 'Task Deadline Reminder',
  AutomationType.annualLeaveReset => 'Annual Leave Reset',
  _ => type,
};

String formatAutomationTypeDescription(String type) => switch (type) {
  AutomationType.projectRenewalReminder =>
    'Notifies everyone who manages Clients & Projects when an active '
        "retainer's renewal date is coming up.",
  AutomationType.taskDeadlineReminder =>
    "Notifies a task's own assignee when its due date is coming up.",
  AutomationType.annualLeaveReset =>
    'Runs the annual leave balance reset automatically once a new year '
        'starts, instead of requiring a manual click, and notifies '
        'HR/Admin once it runs.',
  _ => '',
};
