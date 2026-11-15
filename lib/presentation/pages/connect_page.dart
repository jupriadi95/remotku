import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/server_config.dart';
import '../providers/auth_connection_provider.dart';
import 'dashboard_page.dart';

class ConnectPage extends StatefulWidget {
  const ConnectPage({super.key});

  @override
  State<ConnectPage> createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> {
  final _form = GlobalKey<FormState>();
  final _host = TextEditingController();
  final _port = TextEditingController(text: '22');
  final _user = TextEditingController();
  final _pass = TextEditingController();
  final _keyPath = TextEditingController();
  final _passphrase = TextEditingController();
  bool _usePublicKey = false;
  bool _useCloudflare = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    final conn = context.read<ConnectionProvider>();
    conn.loadProfile().then((_) {
      final p = conn.savedProfile;
      if (p == null || !mounted) return;
      setState(() {
        _host.text = p.host;
        _port.text = p.port.toString();
        _user.text = p.username;
        _usePublicKey = p.usePublicKey;
        _useCloudflare = p.useCloudflare;
        _keyPath.text = p.privateKeyPath ?? '';
      });
    });
  }

  @override
  void dispose() {
    for (final c in [_host, _port, _user, _pass, _keyPath, _passphrase]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickKey() async {
    final res = await FilePicker.pickFiles();
    final path = res.isEmpty ? null : res.first.path;
    if (path != null) setState(() => _keyPath.text = path);
  }

  Future<void> _connect() async {
    if (!_form.currentState!.validate()) return;
    final conn = context.read<ConnectionProvider>();
    final ok = await conn.connect(ServerConfig(
      host: _host.text.trim(),
      port: int.parse(_port.text.trim()),
      username: _user.text.trim(),
      password: _pass.text,
      usePublicKey: _usePublicKey,
      privateKeyPath: _keyPath.text.trim(),
      passphrase: _passphrase.text,
      useCloudflare: _useCloudflare,
    ));
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const DashboardPage()),
      );
    }
  }

  Future<void> _changePasscode() async {
    final ctrl = TextEditingController();
    final newCode = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubah kode akses'),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Kode baru (min 4 digit)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (newCode != null && newCode.length >= 4 && mounted) {
      await context.read<AuthProvider>().changePasscode(newCode);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Kode berhasil diubah')));
    }
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null;

  @override
  Widget build(BuildContext context) {
    final conn = context.watch<ConnectionProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Koneksi Server'),
        actions: [
          IconButton(
            tooltip: 'Ubah kode akses',
            icon: const Icon(Icons.password),
            onPressed: _changePasscode,
          ),
          IconButton(
            tooltip: 'Kunci aplikasi',
            icon: const Icon(Icons.lock),
            onPressed: () => context.read<AuthProvider>().lock(),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _host,
                        decoration: const InputDecoration(
                            labelText: 'IP / Domain', border: OutlineInputBorder()),
                        validator: _required,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _port,
                        decoration: const InputDecoration(
                            labelText: 'Port', border: OutlineInputBorder()),
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          return (n == null || n < 1 || n > 65535) ? 'Tidak valid' : null;
                        },
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _user,
                    decoration: const InputDecoration(
                        labelText: 'Username', border: OutlineInputBorder()),
                    validator: _required,
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Lewat Cloudflare Tunnel'),
                    subtitle: const Text('Butuh cloudflared terpasang (brew install cloudflared)'),
                    value: _useCloudflare,
                    onChanged: (v) => setState(() => _useCloudflare = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Gunakan public key'),
                    value: _usePublicKey,
                    onChanged: (v) => setState(() => _usePublicKey = v),
                  ),
                  if (!_usePublicKey)
                    TextFormField(
                      controller: _pass,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                    )
                  else ...[
                    TextFormField(
                      controller: _keyPath,
                      readOnly: true,
                      onTap: _pickKey,
                      decoration: InputDecoration(
                        labelText: 'File private key',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.folder_open),
                          onPressed: _pickKey,
                        ),
                      ),
                      validator: _required,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passphrase,
                      obscureText: true,
                      decoration: const InputDecoration(
                          labelText: 'Passphrase (opsional)',
                          border: OutlineInputBorder()),
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (conn.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(conn.error!,
                          style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ),
                  FilledButton.icon(
                    onPressed: conn.connecting ? null : _connect,
                    icon: conn.connecting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.link),
                    label: Text(conn.connecting ? 'Menghubungkan...' : 'Connect'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
