import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/core/config/app_config.dart';

void main() {
  test('the API is assumed to be on port 3000 of the host that served the page', () {
    expect(
      AppConfig.sameHostApiUrlFor(Uri.parse('http://192.168.100.76:5050/')),
      'http://192.168.100.76:3000',
    );
    // A different LAN IP (what a DHCP change produces) just works.
    expect(
      AppConfig.sameHostApiUrlFor(Uri.parse('http://192.168.100.200:5050/#/x')),
      'http://192.168.100.200:3000',
    );
    expect(
      AppConfig.sameHostApiUrlFor(Uri.parse('http://localhost:5050/')),
      'http://localhost:3000',
    );
    expect(
      AppConfig.sameHostApiUrlFor(Uri.parse('https://erp.example.com/app')),
      'https://erp.example.com:3000',
    );
  });

  test('an IPv6 host keeps its brackets', () {
    expect(
      AppConfig.sameHostApiUrlFor(Uri.parse('http://[::1]:5050/')),
      'http://[::1]:3000',
    );
  });

  test('outside a browser (file: URI, no host) it falls back to localhost', () {
    expect(
      AppConfig.sameHostApiUrlFor(Uri.parse('file:///D:/project/')),
      'http://localhost:3000',
    );
  });
}
