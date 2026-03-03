import 'package:armi_hub/app/screens/business_context_form_screen.dart';
import 'package:armi_hub/app/screens/home_screen.dart';
import 'package:armi_hub/app/screens/receipt_capture_screen.dart';
import 'package:armi_hub/core/network/network.dart';
import 'package:armi_hub/core/theme/brand_colors.dart';
import 'package:armi_hub/features/app_context/data/repositories/app_context_repository_impl.dart';
import 'package:armi_hub/features/app_context/data/repositories/branch_office_repository_impl.dart';
import 'package:armi_hub/features/app_context/domain/entities/business_context.dart';
import 'package:armi_hub/features/app_context/domain/repositories/branch_office_repository.dart';
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
    final colorScheme = ColorScheme.fromSeed(
      seedColor: BrandColors.mint,
      brightness: Brightness.light,
    ).copyWith(
      primary: BrandColors.mint,
      secondary: BrandColors.dark,
      surface: BrandColors.card,
      onPrimary: BrandColors.dark,
      onSurface: BrandColors.dark,
    );

    return BlocProvider.value(
      value: _appContextCubit,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Armi Hub',
        theme: ThemeData(
          colorScheme: colorScheme,
          scaffoldBackgroundColor: BrandColors.bg,
          cardTheme: const CardThemeData(
            color: BrandColors.card,
            elevation: 0,
            margin: EdgeInsets.zero,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            labelStyle: const TextStyle(color: Color(0xFF66758A), fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E6ED)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E6ED)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: BrandColors.mint, width: 1.5),
            ),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: BrandColors.dark,
            foregroundColor: Colors.white,
            centerTitle: true,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: BrandColors.mint,
              foregroundColor: BrandColors.dark,
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              side: const BorderSide(color: Color(0xFFCFD8E3)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          progressIndicatorTheme: const ProgressIndicatorThemeData(color: BrandColors.mint),
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
            loadBranchOffices: (businessId) => dependencies.branchOfficeRepository.getBranchOffices(
              businessId: businessId,
            ),
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
          loadBranchOffices: (businessId) => dependencies.branchOfficeRepository.getBranchOffices(
            businessId: businessId,
          ),
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
    required this.branchOfficeRepository,
    required this.createOrderFromReceiptUseCase,
    required this.getOrderHistoryUseCase,
    required this.retryFailedOrderUseCase,
  });

  final ApiClient apiClient;
  final OrdersLocalDataSource ordersLocalDataSource;
  final AppContextRepositoryImpl appContextRepository;
  final BranchOfficeRepository branchOfficeRepository;
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
    final branchOfficeRepository = BranchOfficeRepositoryImpl(apiClient: apiClient);

    return _AppDependencies(
      apiClient: apiClient,
      ordersLocalDataSource: local,
      appContextRepository: AppContextRepositoryImpl(),
      branchOfficeRepository: branchOfficeRepository,
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
