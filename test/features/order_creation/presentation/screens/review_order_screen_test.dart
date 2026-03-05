import 'package:armi_hub/features/app_context/domain/entities/business_context.dart';
import 'package:armi_hub/features/order_creation/domain/entities/create_order_request.dart';
import 'package:armi_hub/features/order_creation/domain/entities/create_order_result.dart';
import 'package:armi_hub/features/order_creation/domain/entities/scanned_order.dart';
import 'package:armi_hub/features/order_creation/domain/entities/upload_image_result.dart';
import 'package:armi_hub/features/order_creation/domain/repositories/orders_repository.dart';
import 'package:armi_hub/features/order_creation/domain/use_cases/create_order_from_receipt_use_case.dart';
import 'package:armi_hub/features/order_creation/presentation/screens/review_order_screen.dart';
import 'package:armi_hub/features/receipt_capture/domain/entities/receipt_capture_result.dart';
import 'package:armi_hub/features/receipt_capture/domain/entities/receipt_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('bloquea confirmar cuando paymentMethod OCR es null', (tester) async {
    final useCase = CreateOrderFromReceiptUseCase(ordersRepository: _FakeOrdersRepository());
    const contextData = BusinessContext(
      businessId: 10345,
      storeId: '5940',
      storeCity: 'BARRANQUILLA',
      businessName: 'Kokoriko',
      storeName: 'Kokoriko Buenavista Barranquilla',
    );

    const receiptData = ReceiptData(
      rawText: 'RAW',
      totalValue: 41900,
      paymentMethodCode: null,
      customerNameRaw: 'LILIANA CARRERA',
      customerFirstName: 'LILIANA',
      customerLastName: 'CARRERA',
      customerAddress: 'CALLE 147 #19-79 APTO 305',
      customerPhone: '3187740893',
    );

    final captureResult = ReceiptCaptureResult.success(
      imagePath: '',
      optimizedImagePath: '',
      receiptData: receiptData,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ReviewOrderScreen(
          captureResult: captureResult,
          contextData: contextData,
          createOrderUseCase: useCase,
          onGoToHistory: () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final submitFinder = find.widgetWithText(ElevatedButton, 'Confirmar y crear orden');
    expect(submitFinder, findsOneWidget);

    final disabledButton = tester.widget<ElevatedButton>(submitFinder);
    expect(disabledButton.onPressed, isNull);
    expect(find.text('Selecciona metodo de pago'), findsOneWidget);
    expect(find.text('41900'), findsOneWidget);
    expect(find.text('41900.00'), findsNothing);

    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1 - Efectivo').last);
    await tester.pumpAndSettle();

    final enabledButton = tester.widget<ElevatedButton>(submitFinder);
    expect(enabledButton.onPressed, isNotNull);
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
