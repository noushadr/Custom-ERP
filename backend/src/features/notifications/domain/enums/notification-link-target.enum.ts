/** Where tapping a notification should navigate — mirrors the frontend's
 * (currently client-side-only) NotificationLinkTarget concept, extended
 * with the destinations the Automations module's reminders link to. */
export enum NotificationLinkTarget {
  CLIENTS_PROJECTS = 'clients_projects',
  TASKS = 'tasks',
  LEAVE = 'leave',
}
