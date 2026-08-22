/// Raw values matching the backend's AutomationType enum — a fixed catalog,
/// not user-creatable.
class AutomationType {
  static const projectRenewalReminder = 'project_renewal_reminder';
  static const taskDeadlineReminder = 'task_deadline_reminder';
  static const annualLeaveReset = 'annual_leave_reset';

  static const values = [
    projectRenewalReminder,
    taskDeadlineReminder,
    annualLeaveReset,
  ];
}
