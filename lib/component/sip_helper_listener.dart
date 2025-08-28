import 'package:flutter_voip/component/voip_call_state.dart';
import 'package:flutter_voip/sip/sip_ua.dart';

abstract class SipHelperListener {
  void onCallInitiated(String callId);
  void onCallReceived(String callId);
  void callStateChanged(String callId, VoipCallState state);

  void transportStateChanged(VoipTransportState state);
  void registrationStateChanged(VoipRegistrationState state);
  //For SIP messaga coming
  void onNewMessage(VoipSIPMessageRequest msg);
}
