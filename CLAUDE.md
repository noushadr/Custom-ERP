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
  teams/
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
- Colors: background white `#FFFFFF`, primary/brand `#00D5EE`, text dark gray/near-black, cards white, borders light gray, plus standard success/warning/error status colors. Use the brand accent consistently for primary buttons, links, active nav, icons, progress, selected/focus states, interactive components — avoid extra accent colors.
- Logo: official Zera Creative logo (not yet supplied in repo) goes in `assets/branding/`; used on login, sidebar, header, splash, app icon, favicon. Never recreate/modify it.
- Feel: clean, minimal, spacious, premium.

## Authentication
- Company-email-only registration (`firstname.lastname@zeracreative.com`), no public registration
- Super Admin / HR invite employees
- Email verification, password reset/change, session management, login history, device history, optional 2FA

## RBAC
Flexible/configurable, not hardcoded. Default roles: Super Admin, HR/Manager, Team Lead, Employee. Must support custom roles without app-logic changes.

## Feature Modules (V1)
Role-specific dashboards (Employee/Team Lead/HR-Manager/Super Admin), Employee Management (full profile fields incl. profile completion %), Departments, Teams, Company Notices (targeting + read receipts + comments), Knowledge Base (Team Lead+ upload, versioning, search, favorites, tags), Asset Management (QR/barcode, lifecycle, statuses: Available/Assigned/Repair/Lost/Retired), Employee Requests (Submitted → Manager Approval → HR Approval → Completed), Leave Management, Feedback (incl. anonymous), Employee Directory, Notifications (in-app/email/push), Global Search, Admin Panel.

## Explicitly Excluded from V1
AI Assistant/Chat/Suggestions/Automation/generated content. Storage usage dashboard/quotas/analytics/monitoring. Keep architecture extensible for these later.

## Future Modules (design for, don't build yet)
CRM, Client Portal, Project Management, Attendance, Payroll, Recruitment, Performance Reviews, OKRs, Internal Chat, Time Tracking, Expense Claims, Finance, SEO Dashboard, Automation Engine, Company Calendar, Training Portal, Rewards & Recognition, Company Wiki.

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
