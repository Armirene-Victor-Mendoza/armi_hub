import 'package:armi_hub/core/theme/brand_colors.dart';
import 'package:armi_hub/features/app_context/domain/entities/branch_office.dart';
import 'package:armi_hub/features/app_context/domain/entities/business_context.dart';
import 'package:flutter/material.dart';

class BusinessContextFormScreen extends StatefulWidget {
  const BusinessContextFormScreen({
    super.key,
    this.initialContext,
    required this.onSave,
    required this.loadBranchOffices,
    this.title = 'Seleccionar tienda',
    this.popOnSave = true,
  });

  final BusinessContext? initialContext;
  final Future<void> Function(BusinessContext context) onSave;
  final Future<List<BranchOffice>> Function(int businessId) loadBranchOffices;
  final String title;
  final bool popOnSave;

  @override
  State<BusinessContextFormScreen> createState() => _BusinessContextFormScreenState();
}

class _BusinessContextFormScreenState extends State<BusinessContextFormScreen> {
  static const int _kokoricoBusinessId = 10345;
  static const String _kokoricoName = 'Kokoriko';

  final _formKey = GlobalKey<FormState>();

  bool _isSaving = false;
  bool _isLoadingBranches = true;
  String? _loadError;
  List<BranchOffice> _branches = <BranchOffice>[];
  int? _selectedBranchId;

  String _normalizeCityName(String rawCity) {
    return rawCity.split('-').first.trim();
  }

  BranchOffice? get _selectedBranch {
    if (_selectedBranchId == null) return null;
    for (final branch in _branches) {
      if (branch.id == _selectedBranchId) {
        return branch;
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _fetchBranchOffices();
  }

  Future<void> _fetchBranchOffices() async {
    setState(() {
      _isLoadingBranches = true;
      _loadError = null;
    });

    try {
      final branches = await widget.loadBranchOffices(_kokoricoBusinessId);
      if (!mounted) return;

      final parsedStoreId = int.tryParse(widget.initialContext?.storeId ?? '');
      BranchOffice? matching;
      if (parsedStoreId != null) {
        for (final branch in branches) {
          if (branch.id == parsedStoreId) {
            matching = branch;
            break;
          }
        }
      }

      setState(() {
        _branches = branches;
        _selectedBranchId = matching?.id ?? (branches.isNotEmpty ? branches.first.id : null);
        _isLoadingBranches = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoadingBranches = false;
        _loadError = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColors.bg,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Container(
              margin: const EdgeInsets.all(14),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              decoration: BoxDecoration(
                gradient: BrandColors.topGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: BrandColors.mint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.storefront_rounded, color: BrandColors.dark),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: _buildBody(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoadingBranches) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return _ErrorState(
        message: 'No se pudieron cargar las tiendas: $_loadError',
        buttonLabel: 'Reintentar',
        onPressed: _fetchBranchOffices,
      );
    }

    if (_branches.isEmpty) {
      return _ErrorState(
        message: 'No hay tiendas disponibles para Kokoriko.',
        buttonLabel: 'Recargar',
        onPressed: _fetchBranchOffices,
      );
    }

    final selectedBranch = _selectedBranch;

    return Form(
      key: _formKey,
      child: ListView(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: BrandColors.card,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('Comercio activo', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: '$_kokoricoName ($_kokoricoBusinessId)',
                  enabled: false,
                  decoration: const InputDecoration(labelText: 'Comercio'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  key: ValueKey<int?>(_selectedBranchId),
                  initialValue: _selectedBranchId,
                  decoration: const InputDecoration(labelText: 'Tienda'),
                  isExpanded: true,
                  items: _branches
                      .map(
                        (branch) => DropdownMenuItem<int>(
                          value: branch.id,
                          child: Text('${branch.name} (${branch.id})'),
                        ),
                      )
                      .toList(),
                  onChanged: _isSaving
                      ? null
                      : (value) {
                          setState(() {
                            _selectedBranchId = value;
                          });
                        },
                  validator: (value) => value == null ? 'Selecciona una tienda' : null,
                ),
              ],
            ),
          ),
          if (selectedBranch != null) ...<Widget>[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: BrandColors.card,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(selectedBranch.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('Ciudad: ${_normalizeCityName(selectedBranch.city)}'),
                  Text('Estado: ${selectedBranch.state}'),
                  Text('Direccion: ${selectedBranch.address}'),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isSaving
                ? null
                : () async {
                    if (!_formKey.currentState!.validate()) return;
                    final branch = _selectedBranch;
                    if (branch == null) return;

                    setState(() {
                      _isSaving = true;
                    });

                    final payload = BusinessContext(
                      businessId: _kokoricoBusinessId,
                      storeId: branch.storeId,
                      businessName: _kokoricoName,
                      storeName: branch.name,
                      storeCity: _normalizeCityName(branch.city),
                    );

                    try {
                      await widget.onSave(payload);
                      if (!context.mounted) return;
                      if (widget.popOnSave) {
                        Navigator.of(context).pop(payload);
                      }
                    } catch (error) {
                      if (!context.mounted) return;
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
            child: Text(_isSaving ? 'Guardando...' : 'Guardar seleccion'),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.buttonLabel, required this.onPressed});

  final String message;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: BrandColors.card,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onPressed, child: Text(buttonLabel)),
          ],
        ),
      ),
    );
  }
}
