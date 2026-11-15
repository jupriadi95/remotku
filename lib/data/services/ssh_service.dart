import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dartssh2/dartssh2.dart';

import '../../domain/entities/server_config.dart';
import '../../domain/repositories.dart';
import 'cloudflared_socket.dart';

class DartSshGateway implements SshGateway {
  SSHClient? _client;
  Completer<int?> _exitCompleter = Completer<int?>();

  @override
  bool get isConnected => _client != null && !(_client!.isClosed);

  @override
  Future<int?> get lastExitCode => _exitCompleter.future;

  @override
  Future<void> connect(ServerConfig c) async {
    await disconnect();
    final SSHSocket socket = c.useCloudflare
        ? await ProcessSshSocket.cloudflared(c.host)
        : await SSHSocket.connect(c.host, c.port,
            timeout: const Duration(seconds: 15));

    List<SSHKeyPair>? identities;
    if (c.usePublicKey) {
      final path = c.privateKeyPath;
      if (path == null || path.isEmpty) {
        throw Exception('Private key belum dipilih');
      }
      final pem = await File(path).readAsString();
      identities = SSHKeyPair.fromPem(
        pem,
        (c.passphrase == null || c.passphrase!.isEmpty) ? null : c.passphrase,
      );
    }

    final client = SSHClient(
      socket,
      username: c.username,
      identities: identities,
      onPasswordRequest: c.usePublicKey ? null : () => c.password,
    );
    await client.authenticated;
    _client = client;
  }

  @override
  Future<void> disconnect() async {
    _client?.close();
    _client = null;
  }

  /// Membungkus string menjadi single-quote shell yang aman.
  static String _quote(String s) => "'${s.replaceAll("'", r"'\''")}'";

  static String buildCommand(String command, String directory) {
    final dir = directory.trim();
    var cd = '';
    if (dir.isNotEmpty) {
      if (dir == '~') {
        cd = 'cd ~ && ';
      } else if (dir.startsWith('~/')) {
        cd = 'cd ~/${_quote(dir.substring(2))} && ';
      } else {
        cd = 'cd ${_quote(dir)} && ';
      }
    }
    return 'bash -lc ${_quote('$cd$command')}';
  }

  @override
  Stream<CommandEvent> run(String command, {String directory = ''}) {
    final client = _client;
    if (client == null) {
      throw StateError('Belum terhubung ke server');
    }
    _exitCompleter = Completer<int?>();
    final controller = StreamController<CommandEvent>();

    () async {
      try {
        final session = await client.execute(buildCommand(command, directory));
        final out = session.stdout
            .cast<List<int>>()
            .transform(const Utf8Decoder(allowMalformed: true))
            .listen((t) => controller.add(CommandEvent(t)));
        final err = session.stderr
            .cast<List<int>>()
            .transform(const Utf8Decoder(allowMalformed: true))
            .listen((t) => controller.add(CommandEvent(t, isError: true)));
        await session.done;
        await Future.wait([out.asFuture(), err.asFuture()]);
        _exitCompleter.complete(session.exitCode);
      } catch (e) {
        controller.add(CommandEvent('$e\n', isError: true));
        _exitCompleter.complete(null);
      } finally {
        await controller.close();
      }
    }();

    return controller.stream;
  }
}
