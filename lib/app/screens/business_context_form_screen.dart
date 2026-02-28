import 'package:armi_hub/features/app_context/domain/entities/business_context.dart';
import 'package:flutter/material.dart';

class BusinessContextFormScreen extends StatefulWidget {
  const BusinessContextFormScreen({
    super.key,
    this.initialContext,
    required this.onSave,
    this.title = 'Configurar comercio',
    this.popOnSave = true,
  });

  final BusinessContext? initialContext;
  final Future<void> Function(BusinessContext context) onSave;
  final String title;
  final bool popOnSave;

  @override
  State<BusinessContextFormScreen> createState() => _BusinessContextFormScreenState();
}

class _BusinessContextFormScreenState extends State<BusinessContextFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _businessIdController;
  late final TextEditingController _storeIdController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _businessIdController = TextEditingController(text: widget.initialContext?.businessId.toString() ?? '');
    _storeIdController = TextEditingController(text: widget.initialContext?.storeId ?? '');
  }

  @override
  void dispose() {
    _businessIdController.dispose();
    _storeIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text('Ingresa el contexto con el que se crearan las ordenes.'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _businessIdController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'business_id'),
                  validator: (value) {
                    final parsed = int.tryParse(value ?? '');
                    if (parsed == null || parsed <= 0) {
                      return 'Ingresa un business_id valido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _storeIdController,
                  decoration: const InputDecoration(labelText: 'store_id'),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'Ingresa un store_id valido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isSaving
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;

                          setState(() {
                            _isSaving = true;
                          });

                          final payload = BusinessContext(
                            businessId: int.parse(_businessIdController.text),
                            storeId: _storeIdController.text.trim(),
                          );

                          try {
                            await widget.onSave(payload);
                            if (!mounted) return;
                            if (widget.popOnSave) {
                              Navigator.of(context).pop(payload);
                            }
                          } catch (error) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('No se pudo guardar: $error')),
                            );
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isSaving = false;
                              });
                            }
                          }
                        },
                  child: Text(_isSaving ? 'Guardando...' : 'Guardar contexto'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
