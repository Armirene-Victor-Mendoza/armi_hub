import 'package:armi_hub/features/app_context/domain/entities/business_context.dart';
import 'package:armi_hub/features/order_creation/domain/entities/create_order_request.dart';
import 'package:armi_hub/features/order_creation/domain/entities/create_order_result.dart';
import 'package:armi_hub/features/order_creation/domain/entities/scanned_order.dart';
import 'package:armi_hub/features/order_creation/domain/entities/upload_image_result.dart';
import 'package:armi_hub/features/order_creation/domain/repositories/orders_repository.dart';
import 'package:armi_hub/features/order_creation/domain/use_cases/create_order_from_receipt_use_case.dart';
import 'package:armi_hub/features/receipt_capture/domain/entities/receipt_capture_result.dart';
import 'package:armi_hub/features/receipt_capture/domain/entities/receipt_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CreateOrderFromReceiptUseCase.buildInitialDraft', () {
    final useCase = CreateOrderFromReceiptUseCase(ordersRepository: _FakeOrdersRepository());

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

      final draft = useCase.buildInitialDraft(captureResult: captureResult, context: context);

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

      const context = BusinessContext(businessId: 10345, storeId: '5940', storeCity: 'BARRANQUILLA');

      final draft = useCase.buildInitialDraft(captureResult: captureResult, context: context);

      expect(draft.paymentMethod, isNull);
      expect(draft.receiptImagePath, '/tmp/raw.jpg');
    });
  });
}

class _FakeOrdersRepository implements OrdersRepository {
  @override
  Future<CreateOrderResult> createSignatureOrder(CreateOrderRequest request) {
    throw UnimplementedError();
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
    throw UnimplementedError();
  }

  @override
  Future<void> updateOrderAttempt(ScannedOrder order) {
    throw UnimplementedError();
  }

  @override
  Future<UploadImageResult> uploadReceiptImage({required String imagePath}) {
    throw UnimplementedError();
  }
}
