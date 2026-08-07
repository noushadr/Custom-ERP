abstract final class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  // Dev-only convenience: auto-login on startup so credentials don't need
  // retyping on every hot restart (see LoginPage). Only takes effect when
  // supplied via --dart-define on the launch command (e.g. .claude/launch.json,
  // which is machine-local and never committed) — the documented production
  // build command never passes these, so production is unaffected regardless
  // of build mode. Never set these as literals here — that would put real
  // credentials in git history, which is exactly what this replaces.
  static const String devAutoLoginEmail = String.fromEnvironment(
    'DEV_AUTO_LOGIN_EMAIL',
  );
  static const String devAutoLoginPassword = String.fromEnvironment(
    'DEV_AUTO_LOGIN_PASSWORD',
  );
}
