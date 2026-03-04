import 'package:armi_hub/features/order_creation/domain/entities/order_draft.dart';
import 'package:armi_hub/features/order_creation/domain/entities/payment_method_option.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('default payment method is Datafono (2)', () {
    expect(PaymentMethodCatalog.defaultCode, 2);
    expect(PaymentMethodCatalog.nameFor(2), 'Datafono');
  });

  test('order draft maps to create order request payload', () {
    const draft = OrderDraft(
      totalValue: 120.5,
      paymentMethod: 2,
      firstName: 'Juan',
      lastName: 'Perez',
      address: 'Av. Principal 123',
      phone: '58412551511',
      businessId: 45,
      storeId: '0001',
      city: 'BARRANQUILLA',
      receiptImagePath: '/tmp/receipt.jpg',
      ocrRawText: 'TOTAL 120.5',
      ocrTotal: 120.5,
      uploadedImageUrl: 'https://storage.googleapis.com/bucket/receipt.jpg',
    );

    final payload = draft.toCreateOrderRequest().toJson();

    expect(payload['total_value'], 120.5);
    expect(payload['payment_method'], 2);
    expect(payload['business_id'], 45);
    expect(payload['store_id'], '0001');
    expect(payload['city'], 'BARRANQUILLA');
    expect(payload['url_image'], 'https://storage.googleapis.com/bucket/receipt.jpg');
  });

  test('order draft throws when url_image is missing', () {
    const draft = OrderDraft(
      totalValue: 120.5,
      paymentMethod: 2,
      firstName: 'Juan',
      lastName: 'Perez',
      address: 'Av. Principal 123',
      phone: '58412551511',
      businessId: 45,
      storeId: '0001',
      city: 'BARRANQUILLA',
      receiptImagePath: '/tmp/receipt.jpg',
      ocrRawText: 'TOTAL 120.5',
      ocrTotal: 120.5,
    );

    expect(draft.toCreateOrderRequest, throwsStateError);
  });
}
