import 'package:flutter/foundation.dart';

import '../../domain/entities/command_action.dart';
import '../../domain/repositories.dart';

class ConsoleLine {
  final String text;
  final bool isError;
  final bool isCommand;
  const ConsoleLine(this.text, {this.isError = false, this.isCommand = false});
}

class DashboardProvider extends ChangeNotifier {
  final SshGateway _ssh;
  final ActionRepository _actionsRepo;
  DashboardProvider(this._ssh, this._actionsRepo);

  String directory = '~';
  List<CommandAction> actions = [];
  final List<ConsoleLine> console = [];
  bool running = false;
  String? runningLabel;

  Future<void> init() async {
    actions = await _actionsRepo.load();
    notifyListeners();
  }

  void setDirectory(String v) => directory = v.trim();

  void clearConsole() {
    console.clear();
    notifyListeners();
  }

  Future<void> runCommand(String command, {String? label}) async {
    if (running || command.trim().isEmpty) return;
    running = true;
    runningLabel = label ?? command;
    console.add(ConsoleLine('\$ [$directory] $command\n', isCommand: true));
    notifyListeners();

    try {
      await for (final e in _ssh.run(command, directory: directory)) {
        console.add(ConsoleLine(e.text, isError: e.isError));
        notifyListeners();
      }
      final code = await _ssh.lastExitCode;
      console.add(ConsoleLine(
        code == 0 ? '✔ Selesai (exit 0)\n\n' : '✖ Gagal (exit ${code ?? '?'})\n\n',
        isError: code != 0,
        isCommand: true,
      ));
    } catch (e) {
      console.add(ConsoleLine('$e\n', isError: true));
    } finally {
      running = false;
      runningLabel = null;
      notifyListeners();
    }
  }

  Future<void> upsertAction(CommandAction a) async {
    final i = actions.indexWhere((x) => x.id == a.id);
    if (i >= 0) {
      actions[i] = a;
    } else {
      actions.add(a);
    }
    await _actionsRepo.save(actions);
    notifyListeners();
  }

  Future<void> removeAction(String id) async {
    actions.removeWhere((x) => x.id == id);
    await _actionsRepo.save(actions);
    notifyListeners();
  }
}
