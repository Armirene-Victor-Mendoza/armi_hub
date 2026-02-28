import 'package:armi_hub/features/order_creation/domain/entities/order_status.dart';
import 'package:armi_hub/features/order_creation/domain/use_cases/get_order_history_use_case.dart';
import 'package:armi_hub/features/order_creation/domain/use_cases/retry_failed_order_use_case.dart';
import 'package:armi_hub/features/order_creation/presentation/cubit/history_cubit.dart';
import 'package:armi_hub/features/order_creation/presentation/cubit/history_state.dart';
import 'package:armi_hub/features/order_creation/domain/entities/payment_method_option.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({
    super.key,
    required this.getOrderHistoryUseCase,
    required this.retryFailedOrderUseCase,
  });

  final GetOrderHistoryUseCase getOrderHistoryUseCase;
  final RetryFailedOrderUseCase retryFailedOrderUseCase;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HistoryCubit>(
      create: (_) => HistoryCubit(
        getOrderHistoryUseCase: getOrderHistoryUseCase,
        retryFailedOrderUseCase: retryFailedOrderUseCase,
      )..load(),
      child: const _HistoryView(),
    );
  }
}

class _HistoryView extends StatelessWidget {
  const _HistoryView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de ordenes')),
      body: BlocBuilder<HistoryCubit, HistoryState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.items.isEmpty) {
            return const Center(
              child: Text('Aun no hay ordenes procesadas.'),
            );
          }

          return RefreshIndicator(
            onRefresh: () => context.read<HistoryCubit>().load(),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemBuilder: (context, index) {
                final item = state.items[index];
                final isRetrying = state.retryingOrderId == item.id;

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('ID local: ${item.id}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('Fecha: ${item.createdAt.toLocal()}'),
                        Text('Total: ${item.totalValue.toStringAsFixed(2)}'),
                        Text('Metodo: ${item.paymentMethod} - ${PaymentMethodCatalog.nameFor(item.paymentMethod)}'),
                        Text('Estado: ${item.statusLabel}'),
                        if (item.responseStatusCode != null) Text('HTTP: ${item.responseStatusCode}'),
                        if ((item.errorMessage ?? '').isNotEmpty)
                          Text(
                            item.errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        if (item.status == OrderSyncStatus.error) ...<Widget>[
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: isRetrying
                                ? null
                                : () {
                                    context.read<HistoryCubit>().retryOrder(item);
                                  },
                            icon: isRetrying
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemCount: state.items.length,
            ),
          );
        },
      ),
    );
  }
}
