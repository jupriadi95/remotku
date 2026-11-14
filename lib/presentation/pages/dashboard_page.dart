import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/default_actions.dart';
import '../../domain/entities/command_action.dart';
import '../providers/auth_connection_provider.dart';
import '../providers/dashboard_provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _dir = TextEditingController(text: '~');
  final _scroll = ScrollController();
  final _custom = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<DashboardProvider>().init();
  }

  @override
  void dispose() {
    _dir.dispose();
    _scroll.dispose();
    _custom.dispose();
    super.dispose();
  }

  Future<void> _run(CommandAction a) async {
    final vm = context.read<DashboardProvider>();
    vm.setDirectory(_dir.text);
    if (a.requiresConfirmation) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(a.label),
          content: Text('Jalankan di "${_dir.text}":\n\n${a.command}'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Jalankan')),
          ],
        ),
      );
      if (ok != true) return;
    }
    await vm.runCommand(a.command, label: a.label);
  }

  Future<void> _edit([CommandAction? existing]) async {
    final label = TextEditingController(text: existing?.label ?? '');
    final cmd = TextEditingController(text: existing?.command ?? '');
    var icon = existing?.iconKey ?? 'terminal';
    var confirm = existing?.requiresConfirmation ?? false;
    final vm = context.read<DashboardProvider>();

    final result = await showDialog<CommandAction>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(existing == null ? 'Tombol baru' : 'Edit tombol'),
          content: SizedBox(
            width: 420,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: label, decoration: const InputDecoration(labelText: 'Label')),
              TextField(controller: cmd, decoration: const InputDecoration(labelText: 'Perintah')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: icon,
                decoration: const InputDecoration(labelText: 'Ikon'),
                items: [
                  for (final e in actionIcons.entries)
                    DropdownMenuItem(
                        value: e.key,
                        child: Row(children: [Icon(e.value), const SizedBox(width: 8), Text(e.key)])),
                ],
                onChanged: (v) => setS(() => icon = v ?? icon),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Minta konfirmasi'),
                value: confirm,
                onChanged: (v) => setS(() => confirm = v ?? false),
              ),
            ]),
          ),
          actions: [
            if (existing != null)
              TextButton(
                onPressed: () {
                  vm.removeAction(existing.id);
                  Navigator.pop(ctx);
                },
                child: const Text('Hapus'),
              ),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(
              onPressed: () {
                if (label.text.trim().isEmpty || cmd.text.trim().isEmpty) return;
                Navigator.pop(
                  ctx,
                  CommandAction(
                    id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
                    label: label.text.trim(),
                    command: cmd.text.trim(),
                    iconKey: icon,
                    requiresConfirmation: confirm,
                  ),
                );
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    label.dispose();
    cmd.dispose();
    if (result != null) await vm.upsertAction(result);
  }

  void _autoScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardProvider>();
    final scheme = Theme.of(context).colorScheme;
    _autoScroll();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Bersihkan console',
            icon: const Icon(Icons.delete_sweep),
            onPressed: vm.clearConsole,
          ),
          IconButton(
            tooltip: 'Disconnect',
            icon: const Icon(Icons.power_settings_new),
            onPressed: () async {
              await context.read<ConnectionProvider>().disconnect();
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _dir,
              decoration: const InputDecoration(
                labelText: 'Direktori kerja',
                hintText: '/var/www/app atau ~/project',
                prefixIcon: Icon(Icons.folder),
                border: OutlineInputBorder(),
              ),
              onChanged: vm.setDirectory,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final a in vm.actions)
                  GestureDetector(
                    onSecondaryTap: () => _edit(a),
                    onLongPress: () => _edit(a),
                    child: Tooltip(
                      message: a.command,
                      child: FilledButton.icon(
                        onPressed: vm.running ? null : () => _run(a),
                        icon: Icon(actionIcons[a.iconKey] ?? Icons.terminal),
                        label: Text(a.label),
                      ),
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: () => _edit(),
                  icon: const Icon(Icons.add),
                  label: const Text('Tombol'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Klik kanan / tekan lama pada tombol untuk edit.',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _custom,
                  enabled: !vm.running,
                  decoration: const InputDecoration(
                    labelText: 'Perintah manual (opsional)',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (v) {
                    vm.setDirectory(_dir.text);
                    vm.runCommand(v);
                    _custom.clear();
                  },
                ),
              ),
            ]),
            const SizedBox(height: 12),
            if (vm.running) ...[
              LinearProgressIndicator(minHeight: 3),
              const SizedBox(height: 4),
              Text('Menjalankan: ${vm.runningLabel}'),
              const SizedBox(height: 4),
            ],
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF111418),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: SingleChildScrollView(
                  controller: _scroll,
                  child: SizedBox(
                    width: double.infinity,
                    child: SelectableText.rich(
                      TextSpan(children: [
                        for (final l in vm.console)
                          TextSpan(
                            text: l.text,
                            style: TextStyle(
                              color: l.isError
                                  ? Colors.redAccent
                                  : l.isCommand
                                      ? Colors.cyanAccent
                                      : Colors.greenAccent.shade100,
                            ),
                          ),
                      ]),
                      style: const TextStyle(fontFamily: 'Menlo', fontSize: 13, height: 1.3),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
