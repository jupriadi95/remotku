/// Tombol GUI yang mewakili satu perintah terminal.
class CommandAction {
  final String id;
  final String label;
  final String command;
  final String iconKey;
  final bool requiresConfirmation;

  const CommandAction({
    required this.id,
    required this.label,
    required this.command,
    this.iconKey = 'terminal',
    this.requiresConfirmation = false,
  });

  CommandAction copyWith({
    String? label,
    String? command,
    String? iconKey,
    bool? requiresConfirmation,
  }) =>
      CommandAction(
        id: id,
        label: label ?? this.label,
        command: command ?? this.command,
        iconKey: iconKey ?? this.iconKey,
        requiresConfirmation: requiresConfirmation ?? this.requiresConfirmation,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'command': command,
        'iconKey': iconKey,
        'requiresConfirmation': requiresConfirmation,
      };

  factory CommandAction.fromJson(Map<String, dynamic> json) => CommandAction(
        id: json['id'] as String,
        label: json['label'] as String,
        command: json['command'] as String,
        iconKey: json['iconKey'] as String? ?? 'terminal',
        requiresConfirmation: json['requiresConfirmation'] as bool? ?? false,
      );
}
