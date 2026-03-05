import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/connection_service.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  final _ipController = TextEditingController();
  final _portController = TextEditingController(text: '8765');
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadLastIp();
  }

  void _loadLastIp() {
    final service = context.read<ConnectionService>();
    if (service.lastIpAddress.isNotEmpty) {
      _ipController.text = service.lastIpAddress;
    }
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void _connect() {
    if (_formKey.currentState!.validate()) {
      final service = context.read<ConnectionService>();
      final port = int.tryParse(_portController.text) ?? 8765;
      service.connect(_ipController.text.trim(), port: port);
    }
  }

  String? _validateIp(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an IP address';
    }
    // Basic IP validation
    final parts = value.split('.');
    if (parts.length != 4) {
      return 'Invalid IP address format';
    }
    for (final part in parts) {
      final num = int.tryParse(part);
      if (num == null || num < 0 || num > 255) {
        return 'Invalid IP address';
      }
    }
    return null;
  }

  String? _validatePort(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a port';
    }
    final port = int.tryParse(value);
    if (port == null || port < 1 || port > 65535) {
      return 'Invalid port number';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<ConnectionService>(
          builder: (context, service, _) {
            // Update IP field when last IP is loaded
            if (_ipController.text.isEmpty && service.lastIpAddress.isNotEmpty) {
              _ipController.text = service.lastIpAddress;
            }

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App Icon
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.devices,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Title
                      Text(
                        'Virtual Controller',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Control your Windows PC',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 48),

                      // IP Address Field
                      TextFormField(
                        controller: _ipController,
                        keyboardType: TextInputType.number,
                        validator: _validateIp,
                        enabled: service.status != ConnectionStatus.connecting,
                        decoration: InputDecoration(
                          labelText: 'PC IP Address',
                          hintText: '192.168.1.10',
                          prefixIcon: const Icon(Icons.computer),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Port Field
                      TextFormField(
                        controller: _portController,
                        keyboardType: TextInputType.number,
                        validator: _validatePort,
                        enabled: service.status != ConnectionStatus.connecting,
                        decoration: InputDecoration(
                          labelText: 'Port',
                          hintText: '8765',
                          prefixIcon: const Icon(Icons.tag),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Connect Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton(
                          onPressed: service.status == ConnectionStatus.connecting
                              ? null
                              : _connect,
                          child: service.status == ConnectionStatus.connecting
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Connect',
                                  style: TextStyle(fontSize: 18),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Status Indicator
                      _buildStatusIndicator(service),

                      // Error Message
                      if (service.errorMessage.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  service.errorMessage,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(ConnectionService service) {
    IconData icon;
    Color color;
    String text;

    switch (service.status) {
      case ConnectionStatus.disconnected:
        icon = Icons.power_off;
        color = Colors.grey;
        text = 'Disconnected';
        break;
      case ConnectionStatus.connecting:
        icon = Icons.sync;
        color = Colors.orange;
        text = 'Connecting...';
        break;
      case ConnectionStatus.connected:
        icon = Icons.check_circle;
        color = Colors.green;
        text = 'Connected';
        break;
      case ConnectionStatus.error:
        icon = Icons.error;
        color = Colors.red;
        text = 'Connection Error';
        break;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          'Status: $text',
          style: TextStyle(color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
