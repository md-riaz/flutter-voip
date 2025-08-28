import 'package:flutter_voip/sip/src/sip_ua_helper.dart';

import 'models/pn_push_params.dart';
import 'models/push_notif_params.dart';
import 'sip_info_data.dart';

abstract class VoipService {
  Future<PitelSettings> setExtensionInfo(
    SipInfoData sipInfoData,
    PushNotifParams pushNotifParams,
  );
  Future<PitelSettings> registerSipWithoutFCM(
    PnPushParams pnPushParams,
  );
}
