import 'package:flutter/material.dart';

import '../domain/entities/command_action.dart';

const defaultActions = <CommandAction>[
  CommandAction(
    id: 'deploy',
    label: 'Deploy',
    command: 'git pull',
    iconKey: 'rocket',
  ),
  CommandAction(
    id: 'install_deploy',
    label: 'Install & Deploy',
    command: 'git pull && npm install && npm run build',
    iconKey: 'install',
    requiresConfirmation: true,
  ),
  CommandAction(
    id: 'git_status',
    label: 'Git Status',
    command: 'git status',
    iconKey: 'git',
  ),
  CommandAction(
    id: 'ls',
    label: 'List Files',
    command: 'ls -la',
    iconKey: 'folder',
  ),
  CommandAction(
    id: 'disk',
    label: 'Disk Usage',
    command: 'df -h',
    iconKey: 'storage',
  ),
  CommandAction(
    id: 'docker_ps',
    label: 'Docker PS',
    command: 'docker ps',
    iconKey: 'terminal',
  ),
];

const actionIcons = <String, IconData>{
  'terminal': Icons.terminal,
  'rocket': Icons.rocket_launch,
  'install': Icons.download,
  'git': Icons.merge_type,
  'folder': Icons.folder_open,
  'storage': Icons.storage,
  'restart': Icons.restart_alt,
  'build': Icons.build,
};
