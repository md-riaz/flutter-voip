import 'package:flutter_voip/config/voip_config.dart';
import 'package:flutter_voip/web_service/http_service.dart';

class PortalService extends HttpService {
  static PortalService? _instance;
  static PortalService getInstance() {
    _instance ??= PortalService();
    return _instance!;
  }

  @override
  String get domain => VoipConfig.domainPortal;
}
