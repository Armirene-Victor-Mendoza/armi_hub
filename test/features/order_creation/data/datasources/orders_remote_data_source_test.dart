import 'dart:convert';

import 'package:armi_hub/core/network/api_client.dart';
import 'package:armi_hub/core/network/api_config.dart';
import 'package:armi_hub/features/order_creation/data/datasources/orders_remote_data_source.dart';
import 'package:armi_hub/features/order_creation/domain/entities/create_order_request.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('OrdersRemoteDataSource.createSignatureOrder', () {
    test(
      'retorna error cuando orderResponse tiene status 500 aunque HTTP sea 200',
      () async {
        final dataSource = _buildDataSource((_) async {
          return http.Response(
            jsonEncode(<String, dynamic>{
              'message': 'Firma recibida exitosamente',
              'orderResponse': <String, dynamic>{
                'status': 500,
                'error':
                    '{"status":"INTERNAL_SERVER_ERROR","message":"La distancia entre la tienda y el cliente es mayor a 20 km","data":""}',
              },
            }),
            200,
          );
        });

        final result = await dataSource.createSignatureOrder(_sampleRequest());

        expect(result.success, isFalse);
        expect(result.backendStatus, '500');
        expect(
          result.errorMessage,
          'La distancia entre la tienda y el cliente es mayor a 20 km',
        );
      },
    );

    test('retorna success solo con CREATED + successful + orderId', () async {
      final dataSource = _buildDataSource((_) async {
        return http.Response(
          jsonEncode(<String, dynamic>{
            'message': 'Firma recibida exitosamente',
            'orderResponse': <String, dynamic>{
              'status': 'CREATED',
              'message': 'Success',
              'data': <String, dynamic>{
                'successful': true,
                'orderId': 'B310211',
                'businessOrderId': '1235160084',
              },
            },
          }),
          200,
        );
      });

      final result = await dataSource.createSignatureOrder(_sampleRequest());

      expect(result.success, isTrue);
      expect(result.publicOrderId, 'B310211');
      expect(result.businessOrderId, '1235160084');
      expect(result.backendStatus, 'CREATED');
      expect(result.errorMessage, isNull);
    });

    test('retorna error si CREATED llega sin orderId', () async {
      final dataSource = _buildDataSource((_) async {
        return http.Response(
          jsonEncode(<String, dynamic>{
            'message': 'Firma recibida exitosamente',
            'orderResponse': <String, dynamic>{
              'status': 'CREATED',
              'data': <String, dynamic>{'successful': true},
            },
          }),
          200,
        );
      });

      final result = await dataSource.createSignatureOrder(_sampleRequest());

      expect(result.success, isFalse);
      expect(result.publicOrderId, isNull);
      expect(result.errorMessage, 'Firma recibida exitosamente');
    });

    test('usa fallback cuando orderResponse.error no es JSON valido', () async {
      final dataSource = _buildDataSource((_) async {
        return http.Response(
          jsonEncode(<String, dynamic>{
            'message': 'Firma recibida exitosamente',
            'orderResponse': <String, dynamic>{
              'status': 500,
              'error': 'backend exploded',
            },
          }),
          200,
        );
      });

      final result = await dataSource.createSignatureOrder(_sampleRequest());

      expect(result.success, isFalse);
      expect(result.errorMessage, 'backend exploded');
    });
  });
}

OrdersRemoteDataSource _buildDataSource(
  Future<http.Response> Function(http.Request request) handler,
) {
  final client = MockClient(handler);
  final apiClient = ApiClient(
    config: const ApiConfig(baseUrl: 'https://example.test'),
    client: client,
  );
  return OrdersRemoteDataSource(apiClient: apiClient);
}

CreateOrderRequest _sampleRequest() {
  return const CreateOrderRequest(
    totalValue: 70900,
    paymentMethod: 2,
    firstName: 'ESTEBAN',
    lastName: 'CAMARGO',
    address: 'CRA. 13 #152-80, BOGOTA',
    phone: '3112295481',
    businessId: 10345,
    storeId: '5940',
    city: 'BARRANQUILLA',
    urlImage:
        'https://storage.googleapis.com/upload-tickets-kokorico/ticket.jpg',
  );
}
