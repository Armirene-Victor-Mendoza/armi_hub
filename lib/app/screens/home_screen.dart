import 'package:armi_hub/features/app_context/domain/entities/business_context.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.contextData,
    required this.onScanPressed,
    required this.onHistoryPressed,
    required this.onEditContextPressed,
  });

  final BusinessContext contextData;
  final VoidCallback onScanPressed;
  final VoidCallback onHistoryPressed;
  final VoidCallback onEditContextPressed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Armi Hub'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: onEditContextPressed,
            tooltip: 'Editar contexto',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('business_id: ${contextData.businessId}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('store_id: ${contextData.storeId}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onScanPressed,
                icon: const Icon(Icons.document_scanner),
                label: const Text('Escanear factura'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onHistoryPressed,
                icon: const Icon(Icons.history),
                label: const Text('Historial de ordenes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
