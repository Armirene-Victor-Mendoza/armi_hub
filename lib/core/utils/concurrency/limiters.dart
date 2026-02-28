import 'package:armi_hub/core/utils/concurrency/async_limiter.dart';

class CoreLimiters {
  static final imageUpload = AsyncLimiter(3);
  static final fileUpload = AsyncLimiter(2);
  static final imageCompression = AsyncLimiter(2);
  static final networkRequests = AsyncLimiter(4);
}
