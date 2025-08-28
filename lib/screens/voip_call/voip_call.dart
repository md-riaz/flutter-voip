import 'dart:io';
import 'package:eraser/eraser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming_timer/flutter_callkit_incoming.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_voip/flutter_voip.dart';
import 'package:flutter_show_when_locked/flutter_show_when_locked.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VoipCallWidget extends StatefulWidget {
  final VoipCall _pitelCall = VoipClient.getInstance().pitelCall;
  final VoidCallback goBack;
  final VoidCallback goToCall;
  final Function(String) onRegisterState;
  final Function(VoipCallStateEnum) onCallState;
  final Widget child;
  final String bundleId;
  final SipInfoData? sipInfoData;
  final String appMode;

  VoipCallWidget({
    Key? key,
    required this.goBack,
    required this.goToCall,
    required this.child,
    required this.onRegisterState,
    required this.onCallState,
    required this.bundleId,
    required this.sipInfoData,
    this.appMode = '',
  }) : super(key: key);

  @override
  State<VoipCallWidget> createState() => _MyVoipCallWidget();
}

class _MyVoipCallWidget extends State<VoipCallWidget>
    implements SipHelperListener {
  VoipCall get pitelCall => widget._pitelCall;
  VoipClient pitelClient = VoipClient.getInstance();
  String state = '';

  @override
  initState() {
    super.initState();
    state = pitelCall.getRegisterState();
    _bindEventListeners();
  }

  @override
  void deactivate() {
    super.deactivate();
    _removeEventListeners();
  }

  void _bindEventListeners() {
    pitelCall.addListener(this);
  }

  void _removeEventListeners() {
    pitelCall.removeListener(this);
  }

  // HANDLE: handle message if register status change
  @override
  void onNewMessage(VoipSIPMessageRequest msg) {}

  @override
  void callStateChanged(String callId, VoipCallState state) async {
    widget.onCallState(state.state);
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    if (state.state == VoipCallStateEnum.ENDED) {
      pitelCall.resetOutPhone();
      pitelCall.resetNameCaller();
      pitelCall.setIsHoldCall(false);
      FlutterCallkitIncoming.endAllCalls();
      if (Platform.isAndroid) {
        await FlutterShowWhenLocked().hide();
      }
      widget.goBack();
    }
    if (state.state == VoipCallStateEnum.FAILED) {
      pitelCall.resetOutPhone();
      pitelCall.resetNameCaller();
      pitelCall.setIsHoldCall(false);
      widget.goBack();
    }
    if (state.state == VoipCallStateEnum.STREAM) {
      pitelCall.enableSpeakerphone(false);
    }
    if (state.state == VoipCallStateEnum.ACCEPTED) {
      pitelCall.setIsHoldCall(true);
      if (Platform.isAndroid) {
        Eraser.clearAllAppNotifications();
      }
    }
  }

  @override
  void transportStateChanged(VoipTransportState state) {}

  @override
  void onCallReceived(String callId) async {
    pitelCall.setCallCurrent(callId);
    //! Back up
    if (Platform.isIOS) {
      pitelCall.answer();
    }
    widget.goToCall();
  }

  @override
  void onCallInitiated(String callId) {
    pitelCall.setCallCurrent(callId);
    widget.goToCall();
  }

  void goToBack() {
    pitelClient.release();
    widget.goBack();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: widget.child,
    );
  }

  // STATUS: check register status
  @override
  void registrationStateChanged(VoipRegistrationState state) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    switch (state.state) {
      case VoipRegistrationStateEnum.registrationFailed:
        pitelCall.resetOutPhone();
        break;
      case VoipRegistrationStateEnum.none:
      case VoipRegistrationStateEnum.unregistered:
        prefs.setString("REGISTER_STATE", "UNREGISTERED");
        widget.onRegisterState("UNREGISTERED");
        //! WARNING
        // _registerExtFailed();
        break;
      case VoipRegistrationStateEnum.registered:
        EasyLoading.dismiss();
        if (pitelCall.outPhone.isNotEmpty) {
          pitelClient.call(pitelCall.outPhone, true).then(
                (value) => value.fold((succ) => "OK", (err) {
                  EasyLoading.showToast(
                    err.toString(),
                    toastPosition: EasyLoadingToastPosition.center,
                  );
                }),
              );
        }
        if (Platform.isIOS) {
          FlutterCallkitIncoming.startIncomingCall();
        }
        prefs.setString("REGISTER_STATE", "REGISTERED");
        widget.onRegisterState("REGISTERED");
        break;
    }
  }

}


