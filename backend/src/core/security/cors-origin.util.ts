/** Matches an `http(s)://host[:port]` origin whose host is `localhost` or a
 * private-network address (10.x, 172.16-31.x, 192.168.x, 127.x) — i.e. a
 * browser on the office LAN. Used so the app keeps working when the server
 * PC's DHCP address changes, instead of CORS silently rejecting the new
 * origin because an old IP was hard-coded in CORS_ORIGIN. */
const PRIVATE_NETWORK_ORIGIN =
  /^https?:\/\/(localhost|127(\.\d{1,3}){3}|10(\.\d{1,3}){3}|192\.168(\.\d{1,3}){2}|172\.(1[6-9]|2\d|3[01])(\.\d{1,3}){2})(:\d{1,5})?$/i;

export function isPrivateNetworkOrigin(origin: string): boolean {
  return PRIVATE_NETWORK_ORIGIN.test(origin);
}

/** Decides whether a browser request's `Origin` may call the API. A request
 * with no Origin (curl, server-to-server, same-origin) is always allowed —
 * CORS only governs browsers. */
export function isAllowedOrigin(
  origin: string | undefined,
  options: { allowedOrigins: string[]; allowPrivateNetwork: boolean },
): boolean {
  if (!origin) return true;
  if (options.allowedOrigins.includes(origin)) return true;
  return options.allowPrivateNetwork && isPrivateNetworkOrigin(origin);
}
