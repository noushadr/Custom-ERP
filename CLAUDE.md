# Zera Creative ERP — Project Reference

## Role
Lead Software Architect / Senior Full-Stack Engineer building Zera Creative's internal ERP platform. Long-term production system, not a prototype. Every decision favors scalability, maintainability, security, performance, and clean code over convenience. When multiple approaches are viable, pick the one common in mature enterprise software.

## Vision
Primary internal operating system for Zera Creative, gradually replacing internal tools while staying modular for future expansion. Feels like Linear/Notion/Slack/ClickUp (modern SaaS), functions like Odoo (ERP-style). Visual design: modern SaaS, not traditional ERP chrome.

## Core Principles
Clean Architecture, modular design, SOLID, maintainability, scalability, security, performance, readability, reusability, testability, strong DX. No unnecessary technical debt.

## Tech Stack

### Frontend — Flutter (single shared codebase)
- Platforms: Web, Android, iOS, Windows, macOS, Linux
- Material Design 3
- Responsive nav: Desktop = sidebar, Tablet = collapsible sidebar, Mobile = bottom nav
- Fonts: Poppins for all headings/titles/section titles/table headers/dialog titles/nav headings (heading font only). Inter (or similar) for body text.

### Backend
- REST API, PostgreSQL, JWT auth, RBAC, Docker, env-based config
- Repository Pattern, Dependency Injection
- Framework/language: **not yet decided — confirm with user before scaffolding**

### Project Structure (feature-modules, avoid circular deps; shared code in `shared/core`)
```
features/
  authentication/
  employee/
  departments/
  knowledge_base/
  assets/
  leave/
  requests/
  feedback/
  notifications/
  settings/
shared/
core/
```
Each feature: presentation / application / domain / data layers.

## Branding
- Company: Zera Creative
- Colors (updated to a modern-SaaS palette, see `frontend/lib/core/theme/app_colors.dart`): background white `#FFFFFF`, canvas/fields softly lavender-tinted `#F5F4FB`/`#F1F0F9`, primary/brand violet `#6C5DD3` with a soft tint `#EDEBFC`, secondary blue `#4F8EF7` and the original Zera cyan `#00D5EE` kept as a tertiary accent — used together across stat tiles, charts, and progress indicators rather than a single flat accent. Near-black `#181425` for high-contrast tiles and the active nav pill. Text dark gray/near-black, cards white with soft shadows (not just borders), plus standard success/warning/error status colors (each with a soft tint for pill badges/tiles).
- Shape language: generous rounded corners (cards ~18px, buttons/inputs ~12px, pills fully rounded), soft drop shadows instead of flat borders on cards, colorful soft-tinted stat tiles (`MetricCard`) rather than plain white-with-colored-number tiles.
- Logo: official Zera Creative logo (not yet supplied in repo) goes in `assets/branding/`; used on login, sidebar, header, splash, app icon, favicon. Never recreate/modify it.
- Feel: modern SaaS dashboard — clean and spacious, but colorful/lively rather than monochrome-minimal.

## Authentication
- Company-email-only registration (`firstname.lastname@zeracreative.com`), no public registration
- Super Admin / HR invite employees
- Email verification, password reset/change, session management, login history, device history, optional 2FA

## RBAC
Flexible/configurable, not hardcoded. Default roles: Super Admin, HR/Manager, Team Lead, Employee. Must support custom roles without app-logic changes.

## Feature Modules (V1)
Role-specific dashboards (Employee/Team Lead/HR-Manager/Super Admin), Employee Management (full profile fields incl. profile completion %), Departments (no separate Teams concept — departments cover team groupings), Company Notices (targeting + read receipts + comments), Knowledge Base (Super Admin/HR-Manager/Team Lead author rich-text articles in-app; visibility targeting — Everyone/Specific roles/Specific departments/Roles+departments, union semantics; version history with editor + timestamp per revision; read in-app only, no downloads, uploads, search, tags, or favorites), Asset Management (QR/barcode, lifecycle, statuses: Available/Assigned/Repair/Lost/Retired), Employee Requests (Submitted → Manager Approval → HR Approval → Completed), Leave Management (approved by the employee's department head, then HR/Admin), Employee Onboarding/Offboarding Checklists (configurable step templates, auto-created on invite/status-change), Performance Reviews (one current review auto-created per employee at their most recent work-anniversary year — never backfills older missed years; configurable rating/text criteria; the employee's reporting manager or HR/Admin rates and completes it, employee adds an optional self-assessment, HR/Admin finalizes; year-by-year history per employee), Tasks Management (Super Admin/HR-Manager assign to any employee; a department head — the Team Lead role's authority, since there's no separate Teams concept — assigns only within their own department; single assignee per task with title/description/priority/due date/status — To Do/In Progress/Pending/Completed/Cancelled — freely self-updated by the assignee; comment thread; full change history; My Tasks/Assigned Tasks/Team Tasks views; no file attachments in v1), Feedback (incl. anonymous), Employee Directory, Notifications (in-app/email/push), Global Search, Admin Panel.

## Explicitly Excluded from V1
AI Assistant/Chat/Suggestions/Automation/generated content. Storage usage dashboard/quotas/analytics/monitoring. Keep architecture extensible for these later.

## Future Modules (design for, don't build yet)
CRM, Client Portal, Project Management, Attendance, Payroll, Recruitment, OKRs, Internal Chat, Time Tracking, Expense Claims, Finance, SEO Dashboard, Automation Engine, Company Calendar, Training Portal, Rewards & Recognition, Company Wiki.

## Admin Business Management (Super Admin only)
A separate section of five modules (originally six — see module 5 below), gated stricter than every other admin-tier feature: Employees, Team Leads, and HR/Manager must not view, access, or modify any of them — Super Admin only. Enforced via a dedicated permission per module (e.g. `clients.manage`) that is granted to no role's explicit array and only reaches a user through Super Admin's implicit "every known permission" grant — never a hardcoded role check, so a custom role could still be granted it later without code changes. Frontend nav visibility additionally checks `role == 'Super Admin'` directly (`_isSuperAdmin` in `main.dart`), since HR/Manager must not even see the nav entry.

**Built one at a time, in this order** (per explicit instruction — do not start the next until the current one meets the Definition of Done):

1. **Clients & Projects** — done. `backend/src/features/clients/`, `frontend/lib/features/clients/`. Client (company + contact info, archivable) and Service (admin-managed catalog, archivable, modeled on `LeaveType`) and Project (client + type One-time/Retainer + status Active/On Hold/Completed/Cancelled + dates + pricing + assigned employees/departments/services). Pricing: `originalClientPrice`, a single combined `deductionRate` % (default 20%, override per project), `cost` — `netPrice` and `profit` are computed in the mapper on every read, never stored. "Teams" on a project means Departments (no separate Teams concept, per this file's RBAC/Departments rule) — a distinct, coarser concept from the project's individually assigned employees. Tasks link to a project via `Task.projectId` (nullable) — reuses the existing Tasks module rather than a parallel task system; a linked task's own assignee visibility/authorization is unchanged. `Settings > Services` manages the service catalog. Nav entry "Clients & Projects", with a "Health" tab (see module 2 below).
2. **Client Health** — done, folded into the Clients & Projects module rather than a separate one (same controller/permission surface). `Client` gained `healthStatus` (Healthy/Attention Required/At Risk, default Healthy), `healthFactors` (a fixed 6-item checklist — payment/performance/delays/complaints/communication/renewal — toggled per update, not individually rated), and `healthNotes` — all set only via an explicit `POST /clients/:id/health`, never inferred/computed. Each update also writes an immutable `ClientHealthHistory` row (previous/new status, factors, notes, actor snapshot via the existing `resolveActorName` util) — same convention as `TaskAuditLog`. `GET /clients/health-summary` gives counts by status for the dashboard. Frontend: a "Health" FormSection + history list on `ClientDetailPage` with an "Update Health" dialog, a health badge on every client row, and a third "Health" tab on `ClientsProjectsPage` (stat tiles + a worst-first At Risk/Attention Required list, Healthy clients excluded). All gated by the existing `clients.manage` permission — no new permission needed.
3. **Agency Reporting** — done. `backend/src/features/agency-reporting/`, `frontend/lib/features/agency_reporting/`. A new, distinct `reports.view` permission (following "a dedicated permission per module" rather than reusing `clients.manage`, since this is a standalone module with its own nav entry, unlike Client Health). A single `GET /agency-reporting/report?from=&to=` endpoint (`AgencyReportingService` calls the existing `ClientsService.getClients`/`getProjects` rather than touching repositories directly — no new persisted entities). Every figure is scoped to projects whose `startDate` falls in `[from, to]`, except `activeMonthlyRecurringRevenue` which is a live snapshot of current active retainers regardless of range. "Outstanding payments" and per-employee costs are deliberately excluded — no invoice/payment ledger or time-allocation data exists yet (that's the Finances module, below); only the existing manual `Project.cost` field is totaled. `Client` gained `archivedAt` (stamped/cleared alongside `isArchived`) so "clients lost" in a range can be counted — `isArchived` alone is a snapshot flag with no history. Frontend: date-range presets (This Month/Last Month/This Year/Last Year/Custom via `showDateRangePicker`) plus a "Compare to previous period" toggle (fetches the immediately-preceding equal-length range and shows a delta badge per stat tile) and a manual refresh button — needed because this app's per-section `IndexedStack` keeps every nav destination mounted, so the report's `autoDispose` provider never actually disposes/refetches on its own when data changes elsewhere; revisit this pattern if other report-style pages hit the same staleness. Nav entry "Agency Reporting".
4. **Finances** — done. `backend/src/features/finances/`, `frontend/lib/features/finances/`. A new, distinct `finances.manage` permission (same "dedicated permission per module" convention as Agency Reporting's `reports.view`). Two things live here: a company-wide `GET /finances/summary?from=&to=` P&L (`FinancesService` calls the existing `ClientsService.getProjects` and `EmployeesService.getPayrollSummary` rather than duplicating their data — `grossRevenue`/`deductions`/`projectCosts` are range-scoped from in-range projects' `netPrice`/`originalClientPrice - netPrice`/`cost`; `currentMonthlyPayroll` and `outstandingInvoicesTotal`/`outstandingInvoicesCount` are live snapshots — deliberately excluded from `netProfit`, which stays purely range-scoped, mirroring Agency Reporting's MRR precedent), and a new standalone `Expense` entity (`category` — Rent & Utilities/Software & Tools/Marketing/Vendor Payment/Taxes/Commissions/Other, deliberately excluding Payroll since that's already tracked — `amount`, `date`, optional `payeeName`/`notes`) with its own `GET/POST /expenses`, `PATCH /expenses/:id`. Outstanding invoices reuse `Project` gaining `paymentStatus` (Unpaid/Partial/Paid) and `amountPaid` — a single flag+amount rather than a full invoice ledger, updated via `ProjectDetailPage`'s dedicated "Update Payment" dialog (same pattern as Client Health's "Update Health"), never inferred. Frontend: same date-range preset/refresh pattern as Agency Reporting, stat tiles, an expenses-by-category breakdown, and an Expenses list with Add/Edit dialogs. Nav entry "Finances".
5. **Automations** — built, then removed 2026-08-22 per explicit instruction ("remove automations feature and automations.. make sure everyone is notified for important stuff"). It originally shipped as a **fixed catalog** of 3 admin-toggleable automation types (Project Renewal Reminder, Task Deadline Reminder, Annual Leave Reset) plus an `AutomationExecutionHistory` audit table — see git history (`backend/src/features/automations/`, `frontend/lib/features/automations/`, migration `1788100000000-AddAutomations`) for the original design if ever needed again. It introduced the app's **first persisted `Notification` entity** (`backend/src/features/notifications/`, a core module, not gated by any Admin Business Management permission — every route only ever touches the caller's own notifications), which survives the removal and is now populated directly by each feature module instead of through a generic admin-toggleable layer:
   - **Tasks** (`TasksService.handleDailyDeadlineReminderCheck`, `@Cron(EVERY_DAY_AT_2AM)`): notifies a task's own assignee unconditionally when its `dueDate` is 7 days out. Idempotent via `Task.lastDeadlineReminderSentFor`.
   - **Leave** (`LeaveService.handleDailyAnnualResetCheck`, `@Cron(EVERY_DAY_AT_3AM)`): runs the annual reset automatically once due (idempotent via the pre-existing `getResetStatus`), then notifies **every active employee** directly that their balance was reset, plus every `leave.manage` holder with the run's summary count — a broader audience than the original admin-only notice, since the reset affects every employee personally.
   - **Payroll** (`PayrollService.payRun`): notifies every employee with a line item in the run when it's marked Paid — no link, since there's no employee-facing payslip view (see module 6 below).
   - **Performance Reviews** (`PerformanceReviewsService.runDueCheck`, existing `@Cron(EVERY_DAY_AT_1AM)`): notifies the employee directly ("your review has been created") and whoever needs to act on it — their reporting manager, or every `performance.manage` holder if they have none set.
   - **Project Renewal Reminder has no replacement** — it only ever notified `clients.manage` holders (not "everyone"), so it didn't fit the replacement goal; `ClientsService.getProjectsNeedingRenewalReminder`/`markRenewalReminderSent` and `Project.lastRenewalReminderSentFor` were deleted along with it (migration `1788300000000-RemoveAutomations`). `renewalDate` itself is kept — it's still a legitimate project field, just no longer watched by anything.
   - Frontend: `NotificationBell`'s existing "Reminders" section (`GET /notifications?unreadOnly=true`) is unchanged and keeps working since it's agnostic to which module created a given notification; a `PERFORMANCE_REVIEWS` `NotificationLinkTarget` value was added (migration `1788400000000-AddPerformanceReviewNotificationLinkTarget`) for the new review notifications' deep-link. No nav entry, no settings page, no permission — this is no longer a Super Admin module at all.
6. **Payroll** — done, completing this section's roadmap. `backend/src/features/payroll/`, `frontend/lib/features/payroll/`. A new, distinct `payroll.manage` permission. Reuses the pre-existing `SalaryRecord` entity (base salary + effective-dated history, already built for the employee profile's Salary History screen) rather than duplicating it — Payroll's own new pieces are a **formal, idempotent Payroll Run** (`PayrollRun`: month/year with a `UQ_payroll_runs_month_year` uniqueness constraint, status Draft → Finalized → Paid) and one `PayrollLineItem` per active employee per run (`baseSalary` snapshotted at generation time via a new `EmployeesService.getSalaryAsOf(employeeId, asOfIsoDate)` — the latest `SalaryRecord` whose `effectiveDate` is on or before the run's month-end, plain string comparison since dates are already 'YYYY-MM-DD' — plus one-off `bonuses`/`allowances`/`overtime`/`deductions`/`advances`/`tax`, all editable only while the run is Draft; `netPay` computed in the mapper, matching `Project.netPrice`'s "never stored" convention). Deliberately **no recurring-item concept** (every adjustment is entered fresh per run) and **no formal loan ledger for advances** (a one-time entry, no balance/repayment automation) — both scoped down from the roadmap's original wording after confirming with the user, mirroring Automations' "fixed catalog over generic engine" restraint. `POST /payroll/runs` explicitly 409s on a duplicate month/year (an admin-triggered action, so a loud conflict beats silent dedup) rather than the daily-cron idempotency pattern used elsewhere. A Finalized/Paid run's line items are locked — the "permanent payment history" the roadmap named. No employee-facing payslip view — like every other Admin Business Management module, this stays Super-Admin-only with no self-service surface in V1. Frontend: `PayrollPage` (run list + "Generate Payroll" month/year dialog) and `PayrollRunDetailPage` (run summary, Finalize/Mark Paid actions gated by status, a `DataTable` of line items — tapping a row while Draft opens an edit dialog for that employee's six adjustment figures). Nav entry "Payroll" — coincides in name with the pre-existing Admin Dashboard's own "Payroll" stats section heading (`_SectionHeader('Payroll')`, unrelated), which is fine on-screen but meant two existing widget tests had to stop asserting on bare `find.text('Payroll')` in favor of the already-present, still-unique `'Monthly Payroll'` label.

This completed the Admin Business Management roadmap at 6/6; the section now stands at **5 modules** (Clients & Projects, Client Health, Agency Reporting, Finances, Payroll) since Automations (module 5) was removed 2026-08-22 and is no longer Super-Admin-gated at all — see module 5's entry above. Any further Payroll work (e.g. per-employee payslip PDFs, email delivery, recurring items, an advance/loan ledger) is a deliberate future enhancement, not a gap in what was scoped here.

## Development Workflow
1. Understand the requirement.
2. Design the architecture.
3. Create/update the implementation plan.
4. Implement one feature/module at a time.
5. Keep the app compiling after every change.
6. Refactor when necessary.
7. Add tests where appropriate.
8. Update docs after each completed feature.

Never generate the whole app at once. Never break existing functionality when adding new features.

## Definition of Done
Compiles; follows project architecture; respects RBAC; validation implemented; loading states; empty states; error handling; responsive layouts; docs updated; no unnecessary duplication. Repository stays clean and production-ready after every change.
