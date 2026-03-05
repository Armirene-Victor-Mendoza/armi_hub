import 'dart:io';

import 'package:armi_hub/core/theme/brand_colors.dart';
import 'package:armi_hub/features/app_context/domain/entities/business_context.dart';
import 'package:armi_hub/features/order_creation/domain/entities/order_draft.dart';
import 'package:armi_hub/features/order_creation/domain/entities/order_status.dart';
import 'package:armi_hub/features/order_creation/domain/entities/payment_method_option.dart';
import 'package:armi_hub/features/order_creation/domain/use_cases/create_order_from_receipt_use_case.dart';
import 'package:armi_hub/features/order_creation/presentation/cubit/review_order_cubit.dart';
import 'package:armi_hub/features/order_creation/presentation/cubit/review_order_state.dart';
import 'package:armi_hub/features/receipt_capture/domain/entities/receipt_capture_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ReviewOrderScreen extends StatelessWidget {
  const ReviewOrderScreen({
    super.key,
    required this.captureResult,
    required this.contextData,
    required this.createOrderUseCase,
    required this.onGoToHistory,
    required this.onScanAnother,
  });

  final ReceiptCaptureResult captureResult;
  final BusinessContext contextData;
  final CreateOrderFromReceiptUseCase createOrderUseCase;
  final Future<void> Function() onGoToHistory;
  final Future<void> Function() onScanAnother;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ReviewOrderCubit>(
      create: (_) =>
          ReviewOrderCubit(createOrderUseCase: createOrderUseCase)
            ..initialize(captureResult: captureResult, context: contextData),
      child: _ReviewOrderView(
        contextData: contextData,
        onGoToHistory: onGoToHistory,
        onScanAnother: onScanAnother,
      ),
    );
  }
}

class _ReviewOrderView extends StatefulWidget {
  const _ReviewOrderView({
    required this.contextData,
    required this.onGoToHistory,
    required this.onScanAnother,
  });

  final BusinessContext contextData;
  final Future<void> Function() onGoToHistory;
  final Future<void> Function() onScanAnother;

  @override
  State<_ReviewOrderView> createState() => _ReviewOrderViewState();
}

class _ReviewOrderViewState extends State<_ReviewOrderView> {
  static const int _maxCreationFailuresInView = 2;

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _totalController;
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;

  int? _paymentMethod;
  bool _controllersSeeded = false;
  bool _retryLimitDialogShown = false;

  @override
  void initState() {
    super.initState();
    _totalController = TextEditingController();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _addressController = TextEditingController();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _totalController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReviewOrderCubit, ReviewOrderState>(
      listenWhen: (previous, current) =>
          previous.submittedOrder != current.submittedOrder ||
          previous.creationFailureCount != current.creationFailureCount,
      listener: (context, state) async {
        if (state.creationFailureCount < _maxCreationFailuresInView) {
          _retryLimitDialogShown = false;
        } else if (!_retryLimitDialogShown) {
          _retryLimitDialogShown = true;
          await _showRetryLimitDialog(context);
        }

        final order = state.submittedOrder;
        if (order == null) return;

        final isSuccess = order.status == OrderSyncStatus.success;
        final publicOrderId = order.publicOrderId?.trim();
        final successMessage = (publicOrderId != null && publicOrderId.isNotEmpty)
            ? 'La orden fue enviada correctamente.\n\nOrden #$publicOrderId'
            : 'La orden fue enviada correctamente.\n\nSin ID publico.';

        showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(isSuccess ? 'Orden creada' : 'No se pudo crear'),
            content: Text(isSuccess ? successMessage : (order.errorMessage ?? 'Ocurrio un error enviando la orden.')),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('Aceptar'),
              ),
            ],
          ),
        );
      },
      child: Scaffold(
        backgroundColor: BrandColors.bg,
        appBar: AppBar(title: const Text('Revisar orden')),
        body: BlocBuilder<ReviewOrderCubit, ReviewOrderState>(
          builder: (context, state) {
            final draft = state.initialDraft;

            if (draft == null) {
              return const Center(child: CircularProgressIndicator());
            }

            _seedControllersIfNeeded(draft);

            return SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(14),
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(gradient: BrandColors.topGradient, borderRadius: BorderRadius.circular(18)),
                    child: const Text(
                      'Verifica los datos antes de crear la orden.',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (draft.receiptImagePath.isNotEmpty)
                    Container(
                      decoration: BoxDecoration(color: BrandColors.card, borderRadius: BorderRadius.circular(18)),
                      padding: const EdgeInsets.all(8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(File(draft.receiptImagePath), height: 180, fit: BoxFit.cover),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: BrandColors.card, borderRadius: BorderRadius.circular(18)),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: _ReadonlyInfo(label: 'ID del comercio', value: widget.contextData.businessId.toString()),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ReadonlyInfo(label: 'ID de la tienda', value: widget.contextData.storeId),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: BrandColors.card, borderRadius: BorderRadius.circular(18)),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: <Widget>[
                          TextFormField(
                            controller: _totalController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Valor total'),
                            validator: (value) {
                              final parsed = double.tryParse((value ?? '').replaceAll(',', '.'));
                              if (parsed == null || parsed <= 0) {
                                return 'Ingresa un total valido mayor a 0';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<int>(
                            key: ValueKey<int?>(_paymentMethod),
                            initialValue: _paymentMethod,
                            decoration: const InputDecoration(labelText: 'Metodo de pago'),
                            hint: const Text('Selecciona metodo de pago'),
                            items: PaymentMethodCatalog.options
                                .map(
                                  (option) =>
                                      DropdownMenuItem<int>(value: option.code, child: Text('${option.code} - ${option.name}')),
                                )
                                .toList(),
                            validator: (value) {
                              if (value == null) {
                                return 'Selecciona un metodo de pago';
                              }
                              return null;
                            },
                            onChanged: state.isSubmitting
                                ? null
                                : (value) {
                                    if (value == null) return;
                                    setState(() {
                                      _paymentMethod = value;
                                    });
                                  },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _firstNameController,
                            decoration: const InputDecoration(labelText: 'Nombre'),
                            validator: _requiredValidator,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _lastNameController,
                            decoration: const InputDecoration(labelText: 'Apellido'),
                            validator: _requiredValidator,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _addressController,
                            decoration: const InputDecoration(labelText: 'Direccion'),
                            validator: _requiredValidator,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(labelText: 'Telefono'),
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return 'Campo obligatorio';
                              }
                              if (!RegExp(r'^[0-9+]{8,20}$').hasMatch(value!.trim())) {
                                return 'Telefono invalido';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (state.errorMessage != null) ...<Widget>[
                    const SizedBox(height: 10),
                    Text(state.errorMessage!, style: const TextStyle(color: Colors.red)),
                  ],
                  if (state.creationFailureCount > 0) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(
                      state.creationFailureCount < _maxCreationFailuresInView
                          ? 'Tienes 1 reintento adicional disponible.'
                          : 'Reintentos agotados en esta orden.',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF5C6570)),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Builder(
                    builder: (context) {
                      final canSubmit =
                          !state.isSubmitting &&
                          _paymentMethod != null &&
                          state.creationFailureCount < _maxCreationFailuresInView;
                      return ElevatedButton.icon(
                        onPressed: !canSubmit
                            ? null
                            : () {
                                if (!_formKey.currentState!.validate()) return;

                                final total = double.parse(_totalController.text.replaceAll(',', '.'));
                                final payload = draft.copyWith(
                                  totalValue: total,
                                  paymentMethod: _paymentMethod,
                                  firstName: _firstNameController.text,
                                  lastName: _lastNameController.text,
                                  address: _addressController.text,
                                  phone: _phoneController.text,
                                );

                                context.read<ReviewOrderCubit>().submit(payload);
                              },
                        icon: state.isSubmitting
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.cloud_upload_rounded),
                        label: Text(state.isSubmitting ? 'Enviando...' : 'Confirmar y crear orden'),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _seedControllersIfNeeded(OrderDraft draft) {
    if (_controllersSeeded) return;
    _controllersSeeded = true;
    _paymentMethod = draft.paymentMethod;
    _totalController.text = _formatTotalForInput(draft.totalValue);
    _firstNameController.text = draft.firstName;
    _lastNameController.text = draft.lastName;
    _addressController.text = draft.address;
    _phoneController.text = draft.phone;
  }

  String _formatTotalForInput(double totalValue) {
    if (totalValue <= 0) return '';

    if (totalValue == totalValue.truncateToDouble()) {
      return totalValue.toInt().toString();
    }

    final withPrecision = totalValue.toStringAsFixed(6);
    return withPrecision.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }

  String? _requiredValidator(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return 'Campo obligatorio';
    }
    return null;
  }

  Future<void> _showRetryLimitDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope<void>(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          Navigator.of(dialogContext).pop();
          widget.onGoToHistory();
        },
        child: AlertDialog(
          title: const Text('Reintentos agotados'),
          content: const Text(
            'Ya no puedes crear esta orden desde Revisar. Elige una accion para continuar.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await widget.onGoToHistory();
              },
              child: const Text('Ir a Historial'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await widget.onScanAnother();
              },
              child: const Text('Escanear otra factura'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadonlyInfo extends StatelessWidget {
  const _ReadonlyInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: BrandColors.mintSoft, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF52606D))),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
