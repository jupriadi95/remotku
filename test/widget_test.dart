import 'package:flutter_test/flutter_test.dart';
import 'package:remote_ku/data/services/ssh_service.dart';

void main() {
  test('buildCommand quotes directory and wraps in login shell', () {
    expect(DartSshGateway.buildCommand('ls', '/var/www'),
        "bash -lc 'cd '\\''/var/www'\\'' && ls'");
    expect(DartSshGateway.buildCommand('ls', ''), "bash -lc 'ls'");
  });
}
