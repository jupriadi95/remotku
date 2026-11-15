import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';

/// SSHSocket yang memakai stdin/stdout sebuah proses (setara `ProxyCommand`).
class ProcessSshSocket implements SSHSocket {
  final Process _process;
  final _done = Completer<void>();
  late final StreamController<Uint8List> _out;
  late final StreamController<List<int>> _in;

  ProcessSshSocket._(this._process) {
    _out = StreamController<Uint8List>();
    _process.stdout
        .map((d) => Uint8List.fromList(d))
        .listen(_out.add, onDone: _finish, onError: _out.addError);

    _in = StreamController<List<int>>();
    _in.stream.listen(
      (d) {
        try {
          _process.stdin.add(d);
        } catch (_) {}
      },
      onDone: () => _process.stdin.close().catchError((_) {}),
    );
  }

  void _finish() {
    if (!_out.isClosed) _out.close();
    if (!_done.isCompleted) _done.complete();
  }

  @override
  Stream<Uint8List> get stream => _out.stream;

  @override
  StreamSink<List<int>> get sink => _in.sink;

  @override
  Future<void> get done => _done.future;

  @override
  Future<void> close() async {
    destroy();
    await _done.future;
  }

  @override
  void destroy() {
    _process.kill();
    _finish();
  }

  @override
  Future<void> flush() async {}

  /// Menjalankan `cloudflared access ssh --hostname <host>`.
  static Future<ProcessSshSocket> cloudflared(String host,
      {String? executable}) async {
    final bin = executable != null && executable.isNotEmpty
        ? executable
        : _findCloudflared();
    if (bin == null) {
      throw Exception(
          'cloudflared tidak ditemukan. Pasang dengan: brew install cloudflared');
    }
    final process = await Process.start(
      bin,
      ['access', 'ssh', '--hostname', host],
    );
    // Tampilkan error cloudflared bila proses langsung berhenti.
    final err = StringBuffer();
    process.stderr
        .transform(const SystemEncoding().decoder)
        .listen(err.write);

    final socket = ProcessSshSocket._(process);
    final early = await Future.any<int?>([
      process.exitCode,
      Future<int?>.delayed(const Duration(milliseconds: 800), () => null),
    ]);
    if (early != null) {
      throw Exception('cloudflared berhenti (exit $early): ${err.toString().trim()}');
    }
    return socket;
  }

  static String? _findCloudflared() {
    final candidates = Platform.isWindows
        ? [
            r'C:\Program Files (x86)\cloudflared\cloudflared.exe',
            r'C:\Program Files\cloudflared\cloudflared.exe',
          ]
        : [
            '/usr/local/bin/cloudflared',
            '/opt/homebrew/bin/cloudflared',
            '/usr/bin/cloudflared',
          ];
    for (final p in candidates) {
      if (File(p).existsSync()) return p;
    }
    return null;
  }
}
