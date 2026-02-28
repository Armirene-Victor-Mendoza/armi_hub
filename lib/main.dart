import 'package:armi_hub/app/screens/business_context_form_screen.dart';
import 'package:armi_hub/app/screens/home_screen.dart';
import 'package:armi_hub/app/screens/receipt_capture_screen.dart';
import 'package:armi_hub/core/network/network.dart';
import 'package:armi_hub/features/app_context/data/repositories/app_context_repository_impl.dart';
import 'package:armi_hub/features/app_context/domain/entities/business_context.dart';
import 'package:armi_hub/features/app_context/presentation/cubit/app_context_cubit.dart';
import 'package:armi_hub/features/app_context/presentation/cubit/app_context_state.dart';
import 'package:armi_hub/features/order_creation/data/datasources/orders_local_data_source.dart';
import 'package:armi_hub/features/order_creation/data/datasources/orders_remote_data_source.dart';
import 'package:armi_hub/features/order_creation/data/repositories/orders_repository_impl.dart';
import 'package:armi_hub/features/order_creation/domain/use_cases/create_order_from_receipt_use_case.dart';
import 'package:armi_hub/features/order_creation/domain/use_cases/get_order_history_use_case.dart';
import 'package:armi_hub/features/order_creation/domain/use_cases/retry_failed_order_use_case.dart';
import 'package:armi_hub/features/order_creation/presentation/screens/history_screen.dart';
import 'package:armi_hub/features/order_creation/presentation/screens/review_order_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  runApp(const ArmiHubApp());
}

class ArmiHubApp extends StatefulWidget {
  const ArmiHubApp({super.key});

  @override
  State<ArmiHubApp> createState() => _ArmiHubAppState();
}

class _ArmiHubAppState extends State<ArmiHubApp> {
  late final _AppDependencies _dependencies;
  late final AppContextCubit _appContextCubit;

  @override
  void initState() {
    super.initState();
    _dependencies = _AppDependencies.create();
    _appContextCubit = AppContextCubit(repository: _dependencies.appContextRepository)..load();
  }

  @override
  void dispose() {
    _appContextCubit.close();
    _dependencies.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _appContextCubit,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Armi Hub',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0A7A53)),
          useMaterial3: true,
        ),
        home: _AppRoot(dependencies: _dependencies),
      ),
    );
  }
}

class _AppRoot extends StatelessWidget {
  const _AppRoot({required this.dependencies});

  final _AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppContextCubit, AppContextState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final businessContext = state.context;
        if (businessContext == null) {
          return BusinessContextFormScreen(
            popOnSave: false,
            onSave: (payload) => context.read<AppContextCubit>().save(payload),
          );
        }

        return HomeScreen(
          contextData: businessContext,
          onScanPressed: () => _openCaptureFlow(context, businessContext),
          onHistoryPressed: () => _openHistory(context),
          onEditContextPressed: () => _openContextEditor(context, businessContext),
        );
      },
    );
  }

  Future<void> _openCaptureFlow(BuildContext context, BusinessContext businessContext) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (captureContext) => ReceiptCaptureScreen(
          onEvidenceReady: (captureResult) {
            Navigator.of(captureContext).push(
              MaterialPageRoute<void>(
                builder: (_) => ReviewOrderScreen(
                  captureResult: captureResult,
                  contextData: businessContext,
                  createOrderUseCase: dependencies.createOrderFromReceiptUseCase,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openHistory(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HistoryScreen(
          getOrderHistoryUseCase: dependencies.getOrderHistoryUseCase,
          retryFailedOrderUseCase: dependencies.retryFailedOrderUseCase,
        ),
      ),
    );
  }

  Future<void> _openContextEditor(BuildContext context, BusinessContext businessContext) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BusinessContextFormScreen(
          title: 'Editar comercio',
          initialContext: businessContext,
          onSave: (payload) => context.read<AppContextCubit>().save(payload),
        ),
      ),
    );
  }
}

class _AppDependencies {
  _AppDependencies({
    required this.apiClient,
    required this.ordersLocalDataSource,
    required this.appContextRepository,
    required this.createOrderFromReceiptUseCase,
    required this.getOrderHistoryUseCase,
    required this.retryFailedOrderUseCase,
  });

  final ApiClient apiClient;
  final OrdersLocalDataSource ordersLocalDataSource;
  final AppContextRepositoryImpl appContextRepository;
  final CreateOrderFromReceiptUseCase createOrderFromReceiptUseCase;
  final GetOrderHistoryUseCase getOrderHistoryUseCase;
  final RetryFailedOrderUseCase retryFailedOrderUseCase;

  factory _AppDependencies.create() {
    final apiConfig = ApiConfig.fromEnvironment();
    final apiClient = ApiClient(config: apiConfig);
    final remote = OrdersRemoteDataSource(apiClient: apiClient);
    final local = OrdersLocalDataSource();
    final repository = OrdersRepositoryImpl(remote: remote, local: local);
    final createOrderUseCase = CreateOrderFromReceiptUseCase(ordersRepository: repository);

    return _AppDependencies(
      apiClient: apiClient,
      ordersLocalDataSource: local,
      appContextRepository: AppContextRepositoryImpl(),
      createOrderFromReceiptUseCase: createOrderUseCase,
      getOrderHistoryUseCase: GetOrderHistoryUseCase(repository),
      retryFailedOrderUseCase: RetryFailedOrderUseCase(createOrderUseCase),
    );
  }

  void dispose() {
    apiClient.close();
    ordersLocalDataSource.close();
  }
}
