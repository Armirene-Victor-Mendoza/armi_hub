import 'package:armi_hub/core/theme/brand_colors.dart';
import 'package:armi_hub/features/order_creation/domain/entities/order_status.dart';
import 'package:armi_hub/features/order_creation/domain/entities/scanned_order.dart';
import 'package:armi_hub/features/order_creation/domain/use_cases/get_order_history_use_case.dart';
import 'package:armi_hub/features/order_creation/domain/use_cases/retry_failed_order_use_case.dart';
import 'package:armi_hub/features/order_creation/presentation/cubit/history_cubit.dart';
import 'package:armi_hub/features/order_creation/presentation/cubit/history_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, required this.getOrderHistoryUseCase, required this.retryFailedOrderUseCase});

  final GetOrderHistoryUseCase getOrderHistoryUseCase;
  final RetryFailedOrderUseCase retryFailedOrderUseCase;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HistoryCubit>(
      create: (_) =>
          HistoryCubit(getOrderHistoryUseCase: getOrderHistoryUseCase, retryFailedOrderUseCase: retryFailedOrderUseCase)..load(),
      child: const _HistoryView(),
    );
  }
}

class _HistoryView extends StatelessWidget {
  const _HistoryView();

  static const int _maxCreationFailuresInView = 2;
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColors.bg,
      appBar: AppBar(title: const Text('Historial de ordenes')),
      body: BlocBuilder<HistoryCubit, HistoryState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.items.isEmpty) {
            return const Center(child: Text('Aun no hay ordenes procesadas.'));
          }

          return RefreshIndicator(
            onRefresh: () => context.read<HistoryCubit>().load(),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemBuilder: (context, index) {
                final item = state.items[index];
                final isRetrying = state.retryingOrderId == item.id;
                final isRetryExhausted = item.creationFailureCount >= _maxCreationFailuresInView;

                return Container(
                  decoration: BoxDecoration(color: BrandColors.card, borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                item.storeName?.trim().isNotEmpty == true ? item.storeName!.trim() : 'Tienda ${item.storeId}',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            _StatusChip(status: item.status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_businessName(item)}  •  ID tienda ${item.storeId}',
                          style: const TextStyle(color: Color(0xFF5C6570), fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _orderReference(item),
                          style: const TextStyle(color: Color(0xFF5C6570), fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text('Fecha: ${_dateFormat.format(item.createdAt.toLocal())}'),
                        Text('Total: ${item.totalValue.toStringAsFixed(2)}'),
                        Text('Metodo de pago: ${item.paymentMethodLabel}'),
                        const SizedBox(height: 8),
                        Text('Cliente: ${_clientName(item)}'),
                        Text('Direccion: ${_safeText(item.address)}'),
                        if (item.responseStatusCode != null) Text('HTTP: ${item.responseStatusCode}'),
                        if ((item.errorMessage ?? '').isNotEmpty)
                          Text(item.errorMessage!, style: const TextStyle(color: Colors.red)),
                        if (item.status == OrderSyncStatus.error &&
                            !isRetryExhausted) ...<Widget>[
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: isRetrying
                                ? null
                                : () {
                                    context.read<HistoryCubit>().retryOrder(item);
                                  },
                            icon: isRetrying
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.refresh_rounded),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemCount: state.items.length,
            ),
          );
        },
      ),
    );
  }

  String _clientName(ScannedOrder item) {
    final fullName = '${item.firstName} ${item.lastName}'.trim();
    return fullName.isEmpty ? 'Sin cliente' : fullName;
  }

  String _businessName(ScannedOrder item) {
    final trimmed = item.businessName?.trim() ?? '';
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
    return 'Comercio ${item.businessId}';
  }

  String _safeText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? 'Sin direccion' : trimmed;
  }

  String _orderReference(ScannedOrder item) {
    final publicOrderId = item.publicOrderId?.trim() ?? '';
    if (publicOrderId.isNotEmpty) {
      return 'Orden #$publicOrderId';
    }
    return item.status == OrderSyncStatus.success ? 'Sin ID publico' : 'Orden no creada';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final OrderSyncStatus status;

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final String label;

    switch (status) {
      case OrderSyncStatus.success:
        bg = BrandColors.mintSoft;
        label = 'Enviada';
      case OrderSyncStatus.pending:
        bg = const Color(0xFFFFF3D8);
        label = 'Pendiente';
      case OrderSyncStatus.error:
        bg = const Color(0xFFFFE5E5);
        label = 'Error';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}
