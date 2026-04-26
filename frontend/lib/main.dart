import 'package:flutter/material.dart';
import 'core/config/app_config.dart';
import 'core/services/api_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgriSense &',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const HealthCheckPage(),
    );
  }
}

class HealthCheckPage extends StatefulWidget {
  const HealthCheckPage({super.key});

  @override
  State<HealthCheckPage> createState() => _HealthCheckPageState();
}

class _HealthCheckPageState extends State<HealthCheckPage> {
  String _status = 'Non testé';
  Color _statusColor = Colors.grey;
  bool _isLoading = false;

  Future<void> _checkApi() async {
    setState(() {
      _isLoading = true;
      _status = 'Vérification en cours...';
    });

    final result = await ApiService.checkHealth();

    setState(() {
      _isLoading = false;
      if (result['status'] == 'healthy' || result['status'] == 'ok') {
        _status = 'Connecté ! (Backend: ${result['service'] ?? 'OK'})';
        _statusColor = Colors.green;
      } else {
        _status = 'Erreur : ${result['message']}';
        _statusColor = Colors.red;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AgriSense - Diagnostic Connexion'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Configuration actuelle :',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SelectableText('API URL: ${AppConfig.apiUrl}'),
              const SizedBox(height: 30),
              const Text('Statut de la connexion :'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.1),
                  border: Border.all(color: _statusColor),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _status,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _statusColor, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 30),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton.icon(
                  onPressed: _checkApi,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tester la connexion'),
                ),
              const SizedBox(height: 40),
              const Text(
                'Note: Si vous êtes sur un vrai téléphone, assurez-vous d\'être sur le même réseau WiFi que votre PC et d\'utiliser l\'IP de votre PC.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
