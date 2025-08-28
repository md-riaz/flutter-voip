class VoipConfig {
  // Generic, app-provided configuration. No vendor defaults.
  static String _domainSDK = '';
  static String _domainPortal = '';
  static String _userAgent = 'VoIP Client';

  static String get domainSDK => _domainSDK;
  static String get domainPortal => _domainPortal;
  static String get userAgent => _userAgent;

  static bool isDebug = true;

  // Setters for app/runtime to inject their own values
  static void setDomainSDK(String domain) {
    _domainSDK = domain;
  }

  static void setDomainPortal(String domain) {
    _domainPortal = domain;
  }

  static void setUserAgent(String value) {
    _userAgent = value;
  }
}
