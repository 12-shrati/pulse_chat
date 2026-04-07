class ServerConfig {
  ServerConfig._();

  static const String _host = String.fromEnvironment(
    'SERVER_IP',
    defaultValue: '10.0.2.2', // Android emulator -> host machine
  );

  static const int _port = int.fromEnvironment(
    'SERVER_PORT',
    defaultValue: 8080,
  );

  static String get httpBaseUrl => 'http://$_host:$_port';
  static String get wsUrl => 'ws://$_host:$_port';
}
