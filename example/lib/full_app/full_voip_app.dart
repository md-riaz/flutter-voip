import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_voip/flutter_voip.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

import 'screens/config_screen.dart';
import 'screens/dialer_screen.dart';
import 'screens/push_debug_screen.dart';

class FullVoipApp extends StatefulWidget {
  const FullVoipApp({super.key});

  @override
  State<FullVoipApp> createState() => _FullVoipAppState();
}

class _FullVoipAppState extends State<FullVoipApp> {
  final _voipService = VoipServiceImpl();
  final _call = VoipClient.getInstance().pitelCall;

  int _tab = 0;
  String _registerState = 'UNREGISTERED';
  VoipCallStateEnum _callState = VoipCallStateEnum.NONE;

  SipInfoData _sipInfo = SipInfoData.defaultSipInfo();
  PushNotifParams _pushParams = PushNotifParams(teamId: '', bundleId: 'com.example.flutterVoipExample');

  @override
  void initState() {
    super.initState();
    _loadPersisted();
  }

  Future<void> _loadPersisted() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final sipJson = prefs.getString('SIP_INFO_DATA');
      final pushJson = prefs.getString('PUSH_NOTIF_PARAMS');
      if (sipJson != null) {
        _sipInfo = SipInfoData.fromJson(dartConvert(sipJson) as Map<String, dynamic>);
      }
      if (pushJson != null) {
        _pushParams = PushNotifParams.fromJson(dartConvert(pushJson) as Map<String, dynamic>);
      }
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('SIP_INFO_DATA', jsonEncode(_sipInfo.toJson()));
    await prefs.setString('PUSH_NOTIF_PARAMS', jsonEncode(_pushParams.toJson()));
  }

  // Register using push-aware contact parameters.
  Future<void> _register() async {
    if (_sipInfo.wssUrl.isEmpty || _sipInfo.registerServer.isEmpty || _sipInfo.accountName.isEmpty || _sipInfo.authPass.isEmpty) {
      _toast('Please complete SIP settings in Settings tab');
      setState(() => _registerState = 'UNREGISTERED');
      return;
    }
    await _persist();
    await _voipService.setExtensionInfo(_sipInfo, _pushParams);
  }

  Future<void> _registerForCall() async {
    // Called when tapping Accept on incoming callkit or when placing call from locked screen.
    await _register();
  }

  void _onRegisterState(String s) {
    setState(() => _registerState = s);
  }

  void _onCallState(VoipCallStateEnum s) {
    setState(() => _callState = s);
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<bool> _ensurePermissions({bool withCamera = false}) async {
    if (Platform.isAndroid || Platform.isIOS) {
      final mic = await Permission.microphone.request();
      if (withCamera) {
        await Permission.camera.request();
      }
      if (!mic.isGranted) {
        _toast('Microphone permission is required.');
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final body = IndexedStack(index: _tab, children: [
      DialerScreen(
        onCall: (dest) async {
          final ok = await _ensurePermissions();
          if (!ok) return;
          if (_registerState != 'REGISTERED') await _register();
          await VoipClient.getInstance().call(dest, true);
        },
        regState: _registerState,
        callState: _callState,
      ),
      ConfigScreen(
        initialSip: _sipInfo,
        initialPush: _pushParams,
        onSave: (sip, push) async {
          setState(() {
            _sipInfo = sip;
            _pushParams = push;
          });
          await _persist();
          _toast('Settings saved');
        },
        onRegister: _register,
      ),
      PushDebugScreen(
        bundleId: _pushParams.bundleId,
        registerWithManualToken: (fcmToken) async {
          if (_sipInfo.wssUrl.isEmpty || _sipInfo.registerServer.isEmpty || _sipInfo.accountName.isEmpty || _sipInfo.authPass.isEmpty) {
            _toast('Complete SIP settings first');
            return;
          }
          // Build push params using manual token without Firebase APIs.
          final pn = PnPushParams(
            pnProvider: Platform.isAndroid ? 'fcm' : 'apns',
            pnPrid: fcmToken,
            pnParam: Platform.isAndroid ? _pushParams.bundleId : '${_pushParams.teamId}.${_pushParams.bundleId}.voip',
            fcmToken: fcmToken,
          );
          // Apply SIP settings and register with push params
          final client = VoipClient.getInstance();
          client.setExtensionInfo(_sipInfo.toGetExtensionResponse());
          await client.registerSipWithoutFCM(pn);
        },
      ),
    ]);

    final scaffold = Scaffold(
      appBar: AppBar(
        title: const Text('Full VoIP App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.link),
            tooltip: 'Register',
            onPressed: _register,
          ),
          IconButton(
            icon: const Icon(Icons.link_off),
            tooltip: 'Unregister',
            onPressed: _call.unregister,
          ),
        ],
      ),
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dialpad), label: 'Dialer'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
          NavigationDestination(icon: Icon(Icons.notifications_active), label: 'Push'),
        ],
        onDestinationSelected: (i) => setState(() => _tab = i),
      ),
    );

    // Wrap with VoipApp to hook push/CallKit events and background flows.
    return VoipApp(
      handleRegister: _register,
      handleRegisterCall: _registerForCall,
      child: VoipCallWidget(
        goBack: () {},
        goToCall: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => CallScreen(
              bgColor: Colors.black,
              callState: _callState,
              onCallState: _onCallState,
              showHoldCall: true,
              txtMute: 'Mute',
              txtUnMute: 'Unmute',
              txtSpeaker: 'Speaker',
              txtOutgoing: 'Outgoing',
              txtIncoming: 'Incoming',
              txtHoldCall: 'Hold',
              txtUnHoldCall: 'Unhold',
              txtTimer: 'Duration',
              txtWaiting: '00:00',
            ),
          ));
        },
        onRegisterState: _onRegisterState,
        onCallState: _onCallState,
        bundleId: _pushParams.bundleId,
        sipInfoData: _sipInfo,
        child: scaffold,
      ),
    );
  }
}

// Lightweight JSON helpers to keep example self-contained without external deps.
dynamic dartConvert(String json) => (jsonDecode(json) as Map<String, dynamic>);