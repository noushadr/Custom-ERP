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
