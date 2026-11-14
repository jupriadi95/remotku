import 'entities/command_action.dart';
import 'entities/server_config.dart';

abstract class PasscodeRepository {
  Future<bool> verify(String code);
  Future<void> change(String newCode);
}

abstract class ServerProfileRepository {
  Future<ServerConfig?> load();
  Future<void> save(ServerConfig config);
}

abstract class ActionRepository {
  Future<List<CommandAction>> load();
  Future<void> save(List<CommandAction> actions);
}

/// Hasil streaming dari eksekusi perintah.
class CommandEvent {
  final String text;
  final bool isError;
  const CommandEvent(this.text, {this.isError = false});
}

abstract class SshGateway {
  bool get isConnected;
  Future<void> connect(ServerConfig config);
  Future<void> disconnect();

  /// Menjalankan [command] di dalam [directory], stream output,
  /// lalu menyelesaikan dengan exit code.
  Stream<CommandEvent> run(String command, {String directory = ''});
  Future<int?> get lastExitCode;
}
