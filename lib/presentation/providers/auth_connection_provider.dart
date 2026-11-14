import 'package:flutter/foundation.dart';

import '../../domain/entities/server_config.dart';
import '../../domain/repositories.dart';

enum AuthStage { locked, unlocked }

class AuthProvider extends ChangeNotifier {
  final PasscodeRepository _repo;
  AuthProvider(this._repo);

  AuthStage stage = AuthStage.locked;
  String? error;

  Future<void> unlock(String code) async {
    if (await _repo.verify(code)) {
      stage = AuthStage.unlocked;
      error = null;
    } else {
      error = 'Kode salah';
    }
    notifyListeners();
  }

  void lock() {
    stage = AuthStage.locked;
    notifyListeners();
  }

  Future<void> changePasscode(String newCode) => _repo.change(newCode);
}

class ConnectionProvider extends ChangeNotifier {
  final SshGateway _ssh;
  final ServerProfileRepository _profiles;
  ConnectionProvider(this._ssh, this._profiles);

  ServerConfig? savedProfile;
  bool connecting = false;
  bool get connected => _ssh.isConnected;
  String? error;

  Future<void> loadProfile() async {
    savedProfile = await _profiles.load();
    notifyListeners();
  }

  Future<bool> connect(ServerConfig config) async {
    connecting = true;
    error = null;
    notifyListeners();
    try {
      await _ssh.connect(config);
      await _profiles.save(config);
      savedProfile = config;
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      connecting = false;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    await _ssh.disconnect();
    notifyListeners();
  }
}
