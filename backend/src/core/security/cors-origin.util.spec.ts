import { isAllowedOrigin, isPrivateNetworkOrigin } from './cors-origin.util';

describe('isPrivateNetworkOrigin', () => {
  it.each([
    'http://localhost:5050',
    'http://127.0.0.1:5050',
    'http://192.168.100.76:5050',
    'http://192.168.0.5',
    'http://10.0.3.7:8080',
    'http://172.16.0.1:5050',
    'http://172.31.255.254:5050',
    'https://192.168.1.10:5050',
  ])('accepts %s', (origin) => {
    expect(isPrivateNetworkOrigin(origin)).toBe(true);
  });

  it.each([
    'http://example.com',
    'https://192.168.100.76.evil.com',
    'http://evil.com/192.168.1.1',
    'http://172.32.0.1:5050',
    'http://172.15.0.1:5050',
    'http://8.8.8.8:5050',
    'http://192.168.100.76:5050/path',
    'http://localhost.evil.com',
    'ftp://192.168.1.1',
  ])('rejects %s', (origin) => {
    expect(isPrivateNetworkOrigin(origin)).toBe(false);
  });
});

describe('isAllowedOrigin', () => {
  const base = { allowedOrigins: ['https://erp.example.com'], allowPrivateNetwork: false };

  it('always allows requests with no Origin header', () => {
    expect(isAllowedOrigin(undefined, base)).toBe(true);
  });

  it('allows an explicitly listed origin', () => {
    expect(isAllowedOrigin('https://erp.example.com', base)).toBe(true);
  });

  it('rejects an unlisted LAN origin unless private-network access is on', () => {
    expect(isAllowedOrigin('http://192.168.100.76:5050', base)).toBe(false);
    expect(
      isAllowedOrigin('http://192.168.100.76:5050', { ...base, allowPrivateNetwork: true }),
    ).toBe(true);
  });

  it('still rejects a public origin when private-network access is on', () => {
    expect(
      isAllowedOrigin('https://evil.com', { ...base, allowPrivateNetwork: true }),
    ).toBe(false);
  });
});
