# Custom ERP Flutter

Internal custom-made Flutter ERP platform. See [CLAUDE.md](./CLAUDE.md) for the full project specification and architecture reference.

## Structure

```
frontend/   Flutter app (web, Android, iOS, Windows, macOS, Linux)
backend/    NestJS REST API (PostgreSQL, JWT, RBAC)
```

## Getting Started

### Backend
```bash
cd backend
cp .env.example .env
docker compose up -d      # starts PostgreSQL
npm install
npm run seed              # creates default roles + bootstrap Super Admin (registration is invite-only)
npm run start:dev
```

The seed script reads `SEED_SUPER_ADMIN_EMAIL`/`SEED_SUPER_ADMIN_PASSWORD` from `.env` and is safe to re-run (it won't duplicate roles or overwrite an existing user).

### Frontend
```bash
cd frontend
flutter pub get
flutter run
```
