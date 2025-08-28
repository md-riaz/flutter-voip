import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_voip/flutter_voip.dart';

class VoipServiceImpl implements VoipService, SipHelperListener {
  final voipClient = VoipClient.getInstance();

  SipInfoData? sipInfoData;

  VoipServiceImpl() {
    voipClient.pitelCall.addListener(this);
  }

  @override
  Future<PitelSettings> registerSipWithoutFCM(PnPushParams pnPushParams) {
    return voipClient.registerSipWithoutFCM(pnPushParams);
  }

  @override
  Future<PitelSettings> setExtensionInfo(
    SipInfoData sipInfoData,
    PushNotifParams pushNotifParams,
  ) async {
    //! WARNING: solution 2
    // final SharedPreferences prefs = await SharedPreferences.getInstance();
    // final sipInfoEncode = jsonEncode(sipInfoData);
    // final pnPushParamsEncode = jsonEncode(pnPushParams);
    // await prefs.setString("SIP_INFO_DATA", sipInfoEncode);
    // await prefs.setString("PN_PUSH_PARAMS", pnPushParamsEncode);

    final deviceTokenRes = await PushVoipNotif.getDeviceToken();
    final fcmToken = await PushVoipNotif.getFCMToken();

    final pnPushParams = PnPushParams(
      pnProvider: Platform.isAndroid ? 'fcm' : 'apns',
      pnParam: Platform.isAndroid
          ? pushNotifParams.bundleId
          : '${pushNotifParams.teamId}.${pushNotifParams.bundleId}.voip',
      pnPrid: deviceTokenRes,
      fcmToken: fcmToken,
    );

    this.sipInfoData = sipInfoData;
    voipClient.setExtensionInfo(sipInfoData.toGetExtensionResponse());
    final pitelSetting = await voipClient.registerSipWithoutFCM(pnPushParams);
    return pitelSetting;
  }

  @override
  void callStateChanged(String callId, PitelCallState state) {
    if (kDebugMode) {
      print('❌ ❌ ❌ callStateChanged $callId state ${state.state.toString()}');
    }
  }

  @override
  void onCallInitiated(String callId) {
    if (kDebugMode) {
      print('❌ ❌ ❌ onCallInitiated $callId');
    }
  }

  @override
  void onCallReceived(String callId) {
    if (kDebugMode) {
      print('❌ ❌ ❌ onCallReceived $callId');
    }
  }

  @override
  void onNewMessage(VoipSIPMessageRequest msg) {
    if (kDebugMode) {
      print('❌ ❌ ❌ transportStateChanged ${msg.message}');
    }
  }

  @override
  void registrationStateChanged(VoipRegistrationState state) {
    if (kDebugMode) {
      print('❌ ❌ ❌ registrationStateChanged ${state.state.toString()}');
    }
  }

  @override
  void transportStateChanged(PitelTransportState state) {
    if (kDebugMode) {
      print('❌ ❌ ❌ transportStateChanged ${state.state.toString()}');
    }
  }
}

