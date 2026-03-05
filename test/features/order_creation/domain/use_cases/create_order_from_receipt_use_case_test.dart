import 'package:armi_hub/features/app_context/domain/entities/business_context.dart';
import 'package:armi_hub/features/order_creation/domain/entities/create_order_request.dart';
import 'package:armi_hub/features/order_creation/domain/entities/create_order_result.dart';
import 'package:armi_hub/features/order_creation/domain/entities/order_draft.dart';
import 'package:armi_hub/features/order_creation/domain/entities/order_status.dart';
import 'package:armi_hub/features/order_creation/domain/entities/scanned_order.dart';
import 'package:armi_hub/features/order_creation/domain/entities/upload_image_result.dart';
import 'package:armi_hub/features/order_creation/domain/repositories/orders_repository.dart';
import 'package:armi_hub/features/order_creation/domain/use_cases/create_order_from_receipt_use_case.dart';
import 'package:armi_hub/features/receipt_capture/domain/entities/receipt_capture_result.dart';
import 'package:armi_hub/features/receipt_capture/domain/entities/receipt_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CreateOrderFromReceiptUseCase.buildInitialDraft', () {
    final useCase = CreateOrderFromReceiptUseCase(
      ordersRepository: _FakeOrdersRepository(),
    );

    test('mapea datos OCR a OrderDraft', () {
      const receiptData = ReceiptData(
        rawText: 'RAW',
        totalValue: 70900,
        paymentMethodCode: 2,
        paymentMethodLabelRaw: 'TARJETA DEBITO',
        customerNameRaw: 'ESTEBAN CAMARGO',
        customerFirstName: 'ESTEBAN',
        customerLastName: 'CAMARGO',
        customerAddress: 'CRA 13 #152-80 APTO 215',
        customerPhone: '3112295481',
        orderCentralId: '20363149',
      );

      final captureResult = ReceiptCaptureResult.success(
        imagePath: '/tmp/raw.jpg',
        optimizedImagePath: '/tmp/optimized.jpg',
        receiptData: receiptData,
      );

      const context = BusinessContext(
        businessId: 10345,
        storeId: '5940',
        businessName: 'Kokoriko',
        storeName: 'Kokoriko Buenavista Barranquilla',
        storeCity: 'BARRANQUILLA',
      );

      final draft = useCase.buildInitialDraft(
        captureResult: captureResult,
        context: context,
      );

      expect(draft.totalValue, 70900);
      expect(draft.paymentMethod, 2);
      expect(draft.firstName, 'ESTEBAN');
      expect(draft.lastName, 'CAMARGO');
      expect(draft.address, 'CRA 13 #152-80 APTO 215');
      expect(draft.phone, '3112295481');
      expect(draft.businessId, 10345);
      expect(draft.storeId, '5940');
      expect(draft.businessName, 'Kokoriko');
      expect(draft.storeName, 'Kokoriko Buenavista Barranquilla');
      expect(draft.city, 'BARRANQUILLA');
      expect(draft.receiptImagePath, '/tmp/optimized.jpg');
      expect(draft.ocrRawText, 'RAW');
      expect(draft.ocrTotal, 70900);
    });

    test('deja paymentMethod en null cuando OCR no lo detecta', () {
      const receiptData = ReceiptData(
        rawText: 'RAW',
        totalValue: 15000,
        customerNameRaw: 'JUAN PEREZ',
        customerFirstName: 'JUAN',
        customerLastName: 'PEREZ',
        customerAddress: 'CALLE 10 #20-30',
        customerPhone: '3001234567',
      );

      final captureResult = ReceiptCaptureResult.success(
        imagePath: '/tmp/raw.jpg',
        optimizedImagePath: '',
        receiptData: receiptData,
      );

      const context = BusinessContext(
        businessId: 10345,
        storeId: '5940',
        storeCity: 'BARRANQUILLA',
      );

      final draft = useCase.buildInitialDraft(
        captureResult: captureResult,
        context: context,
      );

      expect(draft.paymentMethod, isNull);
      expect(draft.receiptImagePath, '/tmp/raw.jpg');
    });
  });

  group('CreateOrderFromReceiptUseCase.submitOrder', () {
    test('guarda orderId publico cuando backend confirma CREATED', () async {
      final repository = _FakeOrdersRepository(
        createOrderResult: const CreateOrderResult(
          success: true,
          orderCreated: true,
          manualCreationRequired: false,
          statusCode: 200,
          responseBodyRaw: '{"ok":true}',
          publicOrderId: 'B310211',
          businessOrderId: '1235160084',
          backendStatus: 'CREATED',
        ),
      );
      final useCase = CreateOrderFromReceiptUseCase(
        ordersRepository: repository,
      );

      final result = await useCase.submitOrder(_validDraft());

      expect(result.status, OrderSyncStatus.success);
      expect(result.publicOrderId, 'B310211');
      expect(result.businessOrderId, '1235160084');
      expect(result.backendStatus, 'CREATED');
      expect(result.manualCreationRequired, isFalse);
      expect(repository.savedOrders.length, 1);
      expect(repository.updatedOrders.length, 1);
      expect(repository.uploadCalls, 1);
      expect(repository.createCalls, 1);
    });

    test('marca success manual cuando backend acepta pero no crea orden', () async {
        final repository = _FakeOrdersRepository(
          createOrderResult: const CreateOrderResult(
            success: true,
            orderCreated: false,
            manualCreationRequired: true,
            statusCode: 200,
            responseBodyRaw: '{"orderResponse":{"status":500}}',
            userMessage: 'Orden Recibida, creación manual',
            backendStatus: '500',
          ),
        );
        final useCase = CreateOrderFromReceiptUseCase(
          ordersRepository: repository,
        );

        final result = await useCase.submitOrder(_validDraft());

        expect(result.status, OrderSyncStatus.success);
        expect(result.publicOrderId, isNull);
        expect(result.backendStatus, '500');
        expect(result.manualCreationRequired, isTrue);
        expect(result.userMessage, 'Orden Recibida, creación manual');
        expect(repository.createCalls, 1);
      },
    );
  });
}

class _FakeOrdersRepository implements OrdersRepository {
  _FakeOrdersRepository({
    CreateOrderResult? createOrderResult,
    UploadImageResult? uploadResult,
  }) : _createOrderResult =
           createOrderResult ??
           const CreateOrderResult(
             success: true,
             orderCreated: true,
             manualCreationRequired: false,
             statusCode: 200,
             responseBodyRaw: '{}',
           ),
       _uploadResult =
           uploadResult ??
           const UploadImageResult(
             success: true,
             statusCode: 200,
             responseBodyRaw: '{}',
             urlImage: 'https://img.test/ticket.jpg',
           );

  final CreateOrderResult _createOrderResult;
  final UploadImageResult _uploadResult;
  final List<ScannedOrder> savedOrders = <ScannedOrder>[];
  final List<ScannedOrder> updatedOrders = <ScannedOrder>[];
  int uploadCalls = 0;
  int createCalls = 0;

  @override
  Future<CreateOrderResult> createSignatureOrder(CreateOrderRequest request) {
    createCalls += 1;
    return Future<CreateOrderResult>.value(_createOrderResult);
  }

  @override
  Future<List<ScannedOrder>> getOrderHistory({String? status}) {
    throw UnimplementedError();
  }

  @override
  Future<ScannedOrder?> getOrderById(String id) {
    throw UnimplementedError();
  }

  @override
  Future<void> saveOrderAttempt(ScannedOrder order) {
    savedOrders.add(order);
    return Future<void>.value();
  }

  @override
  Future<void> updateOrderAttempt(ScannedOrder order) {
    updatedOrders.add(order);
    return Future<void>.value();
  }

  @override
  Future<UploadImageResult> uploadReceiptImage({required String imagePath}) {
    uploadCalls += 1;
    return Future<UploadImageResult>.value(_uploadResult);
  }
}

OrderDraft _validDraft() {
  return const OrderDraft(
    totalValue: 70900,
    paymentMethod: 2,
    firstName: 'ESTEBAN',
    lastName: 'CAMARGO',
    address: 'CRA. 13 #152-80, BOGOTA',
    phone: '3112295481',
    businessId: 10345,
    storeId: '5940',
    businessName: 'Kokorico',
    storeName: 'Kokorico Buenavista Barranquilla',
    city: 'BARRANQUILLA',
    receiptImagePath: '/tmp/ticket.jpg',
    ocrRawText: 'RAW',
    uploadedImageUrl: null,
  );
}
