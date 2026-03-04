import 'package:growthbook_sdk_flutter/growthbook_sdk_flutter.dart';

class FeatureFlagsService {
  static const String orderCreationFlagKey = 'armi_hub_order_creation';
  static const String _sdkKey = 'sdk-UXEP0quf5ldIwZzf';
  static const String _hostUrl = String.fromEnvironment(
    'GROWTHBOOK_HOST_URL',
    defaultValue: 'https://cdn.growthbook.io',
  );

  Future<void>? _initializeFuture;
  GrowthBookSDK? _sdk;
  bool _isOrderCreationEnabled = true;

  Future<void> ensureInitialized() {
    return _initializeFuture ??= _initialize();
  }

  bool get isOrderCreationEnabled => _isOrderCreationEnabled;

  Future<void> _initialize() async {
    try {
      _sdk = await GBSDKBuilderApp(
        apiKey: _sdkKey,
        hostURL: _hostUrl,
        attributes: const <String, dynamic>{},
        growthBookTrackingCallBack: (dynamic _) {},
        gbFeatures: <String, GBFeature>{
          orderCreationFlagKey: GBFeature(defaultValue: true),
        },
      ).initialize();

      _isOrderCreationEnabled = _sdk?.feature(orderCreationFlagKey).on ?? true;
    } catch (_) {
      _isOrderCreationEnabled = true;
    }
  }
}
