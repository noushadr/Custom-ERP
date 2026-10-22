export default () => ({
  nodeEnv: process.env.NODE_ENV,
  port: parseInt(process.env.PORT ?? '3000', 10),
  database: {
    host: process.env.DB_HOST,
    port: parseInt(process.env.DB_PORT ?? '5432', 10),
    username: process.env.DB_USERNAME,
    password: process.env.DB_PASSWORD,
    name: process.env.DB_NAME,
  },
  jwt: {
    secret: process.env.JWT_SECRET,
    expiresIn: process.env.JWT_EXPIRES_IN,
    refreshSecret: process.env.JWT_REFRESH_SECRET,
    refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN,
  },
  seed: {
    superAdminEmail: process.env.SEED_SUPER_ADMIN_EMAIL,
    superAdminPassword: process.env.SEED_SUPER_ADMIN_PASSWORD,
  },
  // AES-256-GCM key (32-byte hex) used to encrypt mailbox passwords at rest
  // for the Email feature.
  emailCredentialKey: process.env.EMAIL_CREDENTIAL_KEY,
  // Shared PIN gating the Leads and Financial Reports pages (on top of
  // their existing Super-Admin-only permission gates).
  moduleLockPin: process.env.MODULE_LOCK_PIN ?? '2803',
  // Comma-separated list of allowed frontend origins. Falls back to the
  // local Flutter-web dev server when unset — never wide open by default.
  corsOrigin: process.env.CORS_ORIGIN,
  // When true, any browser origin on localhost or a private-network address
  // (192.168.x, 10.x, 172.16-31.x) may call the API, in addition to the
  // explicit CORS_ORIGIN list — so an office LAN keeps working when the
  // server PC's DHCP address changes. Off by default (a production server
  // should list its real origin(s) only).
  corsAllowPrivateNetwork: process.env.CORS_ALLOW_PRIVATE_NETWORK === 'true',
  // Mounts every route (and /uploads) under this path segment, e.g. 'api'
  // so the app owns yourdomain.com/api/* when reverse-proxied at a
  // subdirectory (cPanel's Node.js Selector forwards the full, unstripped
  // path). Empty/unset locally — routes stay at the domain root.
  apiGlobalPrefix: process.env.API_GLOBAL_PREFIX ?? '',
});
