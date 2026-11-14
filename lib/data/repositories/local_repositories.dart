import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/default_actions.dart';
import '../../domain/entities/command_action.dart';
import '../../domain/entities/server_config.dart';
import '../../domain/repositories.dart';

class LocalPasscodeRepository implements PasscodeRepository {
  static const _key = 'passcode_hash';
  static const defaultCode = '123456';

  final SharedPreferences _prefs;
  LocalPasscodeRepository(this._prefs);

  String _hash(String v) => sha256.convert(utf8.encode(v)).toString();

  @override
  Future<bool> verify(String code) async {
    final stored = _prefs.getString(_key) ?? _hash(defaultCode);
    return stored == _hash(code);
  }

  @override
  Future<void> change(String newCode) async {
    await _prefs.setString(_key, _hash(newCode));
  }
}

class LocalServerProfileRepository implements ServerProfileRepository {
  static const _key = 'server_profile';
  final SharedPreferences _prefs;
  LocalServerProfileRepository(this._prefs);

  @override
  Future<ServerConfig?> load() async {
    final raw = _prefs.getString(_key);
    if (raw == null) return null;
    return ServerConfig.fromStorageJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> save(ServerConfig config) =>
      _prefs.setString(_key, jsonEncode(config.toStorageJson()));
}

class LocalActionRepository implements ActionRepository {
  static const _key = 'actions';
  final SharedPreferences _prefs;
  LocalActionRepository(this._prefs);

  @override
  Future<List<CommandAction>> load() async {
    final raw = _prefs.getString(_key);
    if (raw == null) return defaultActions;
    return (jsonDecode(raw) as List)
        .map((e) => CommandAction.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> save(List<CommandAction> actions) => _prefs.setString(
      _key, jsonEncode(actions.map((e) => e.toJson()).toList()));
}
