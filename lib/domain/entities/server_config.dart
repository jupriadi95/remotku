/// Parameter koneksi SSH. Password & passphrase tidak pernah disimpan.
class ServerConfig {
  final String host;
  final int port;
  final String username;
  final String password;
  final bool usePublicKey;
  final String? privateKeyPath;
  final String? passphrase;
  final bool useCloudflare;

  const ServerConfig({
    required this.host,
    this.port = 22,
    required this.username,
    this.password = '',
    this.usePublicKey = false,
    this.privateKeyPath,
    this.passphrase,
    this.useCloudflare = false,
  });

  Map<String, dynamic> toStorageJson() => {
        'host': host,
        'port': port,
        'username': username,
        'usePublicKey': usePublicKey,
        'privateKeyPath': privateKeyPath,
        'useCloudflare': useCloudflare,
      };

  factory ServerConfig.fromStorageJson(Map<String, dynamic> json) =>
      ServerConfig(
        host: json['host'] as String? ?? '',
        port: json['port'] as int? ?? 22,
        username: json['username'] as String? ?? '',
        usePublicKey: json['usePublicKey'] as bool? ?? false,
        privateKeyPath: json['privateKeyPath'] as String?,
        useCloudflare: json['useCloudflare'] as bool? ?? false,
      );
}
