import 'package:universal_platform/universal_platform.dart';

class ApiConfig {
  static String getBaseUrl() {
    if (UniversalPlatform.isWeb) {
      return "http://localhost:8000";
    } else {
      return "http://10.0.2.2:8000";
    }
  }
}