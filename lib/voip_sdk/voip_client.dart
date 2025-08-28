import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_voip/config/voip_config.dart';
import 'package:flutter_voip/model/http/get_extension_info.dart';
import 'package:flutter_voip/model/voip_error.dart';
import 'package:flutter_voip/model/sip_server.dart';
import 'package:flutter_voip/voip_sdk/voip_api.dart';
import 'package:flutter_voip/voip_sdk/voip_call.dart';
import 'package:flutter_voip/voip_sdk/voip_log.dart';
import 'package:flutter_voip/services/models/pn_push_params.dart';
import 'package:flutter_voip/sip/src/sip_ua_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_voip/services/sip_info_data.dart';

import '../voip_sdk/voip_profile.dart';

class VoipClient {
  static VoipClient? _instance;
  static VoipClient getInstance() {
    _instance ??= VoipClient();
    return _instance!;
  }

  VoipClient() {
    _pitelApi = VoipApi.getInstance();
  }

  late String _token;
  late String _pitelToken;
  late VoipApi _pitelApi;
  late SipServer? _sipServer;
  late VoipProfileUser profileUser;
  String _username = '';
  String _password = '';
  String _displayName = '';
  String _userAgent = VoipConfig.userAgent;
  final VoipLog _logger = VoipLog(tag: 'VoipClient');
  final VoipCall pitelCall = VoipCall();

  final String wssTest = 'wss://sbc03.tel4vn.com:7444';
  final String domainTest = 'pi0003.tel4vn.com';
  final int portTest = 5060;
  final String usernameTest = '103';
  final String passwordTest = '12345678@X';

  final bool isTest = false;

  bool _registerSip({String? fcmToken}) {
    if (_sipServer != null) {
      final settings = PitelSettings();
      Map<String, String> _wsExtraHeaders = {
        'Origin': 'https://${_sipServer?.domain}:${_sipServer?.port}',
        'Host': '${_sipServer?.domain}:${_sipServer?.port}',
        'X-PushToken': "${Platform.isIOS ? 'ios;' : 'android;'}$fcmToken",
      };
      settings.webSocketUrl = _sipServer?.wss ?? "";
      settings.webSocketSettings.allowBadCertificate = true;
      settings.uri = 'sip:$_username@${_sipServer?.domain}:${_sipServer?.port}';
      settings.webSocketSettings.extraHeaders = _wsExtraHeaders;
      settings.authorizationUser = _username;
      settings.password = _password;
      settings.displayName = _displayName;
      settings.userAgent = _userAgent;
      settings.registerParams.extraContactUriParams = {
        'X-PushToken': "${Platform.isIOS ? 'ios;' : 'android;'}$fcmToken",
      };
      settings.dtmfMode = DtmfMode.RFC2833;
      pitelCall.register(settings);
      return true;
    } else {
      _logger.info('You must login');
      return false;
    }
  }

  Future<PitelSettings> registerSipWithoutFCM(PnPushParams pnPushParams) async {
    final settings = PitelSettings();
    Map<String, String> _wsExtraHeaders = {
      'Origin': 'https://${_sipServer?.domain}:${_sipServer?.port}',
      'Host': '${_sipServer?.domain}:${_sipServer?.port}',
    };

    // Optional: If you have TURN, add via settings.iceServers before register.

    settings.webSocketUrl = _sipServer?.wss ?? "";
    settings.webSocketSettings.allowBadCertificate = true;
    settings.uri = 'sip:$_username@${_sipServer?.domain}:${_sipServer?.port}';
    settings.contactUri =
        'sip:$_username@${_sipServer?.domain}:${_sipServer?.port};pn-prid=${pnPushParams.pnPrid};pn-provider=${pnPushParams.pnProvider};pn-param=${pnPushParams.pnParam};fcm-token=${pnPushParams.fcmToken};transport=wss;name-caller=encode';
    settings.webSocketSettings.extraHeaders = _wsExtraHeaders;
    settings.authorizationUser = _username;
    settings.password = _password;
    // Use the raw display name without vendor-specific encoding/suffixes
    settings.displayName = _displayName;
    settings.userAgent = _userAgent;
    settings.register_expires = 600;
    settings.dtmfMode = DtmfMode.RFC2833;
    //! sip_domain
    settings.sipDomain = '${_sipServer?.domain}:${_sipServer?.port}';

    pitelCall.register(settings);
    return settings;
  }

  void setExtensionInfo(GetExtensionResponse extensionResponse) {
    _logger.info('sipServer ${extensionResponse.sipServer.toString()}');
    final String userAgentInit = extensionResponse.sipServer.userAgent ?? '';
    final String userAgentConvert =
        userAgentInit.isNotEmpty ? userAgentInit : 'Flutter SDK: VoIP Client';

    _sipServer = extensionResponse.sipServer;
    _username = extensionResponse.username;
    _password = extensionResponse.password;
    _displayName = extensionResponse.displayName;
    _userAgent = userAgentConvert;

    if (isTest) {
      _username = usernameTest;
      _password = passwordTest;
      _sipServer = SipServer(
        id: 0,
        domain: domainTest,
        port: portTest,
        outboundProxy: '',
        wss: wssTest,
        transport: 0,
        createdAt: '',
        project: '',
      );
    }
    _logger.info('sipAccount ${extensionResponse.username} enabled');
  }

  Future<Either<bool, Error>> call(String dest, [bool voiceonly = true]) async {
    final String destSip =
        'sip:$dest@${_sipServer?.domain}:${_sipServer?.port}';
    if (destSip != _mySipUri) {
      try {
        final isCallSuccess = await pitelCall.call(dest, voiceonly);
        return left(isCallSuccess);
      } catch (err) {
        return right(VoipError(err.toString()));
      }
    } else {
      _logger.error('Cannot call because number is mine');
      return right(VoipError('Cannot call because number is mine'));
    }
  }

  release() {
    pitelCall.unregister();
  }

  Future<bool> login(
    String username,
    String password, {
    String? fcmToken,
  }) async {
    _logger.info('login $username $password');
    final loginSuccess = await _login(username, password);
    _logger.info('login $loginSuccess');
    if (loginSuccess) {
      final getProfileSuccess = await _getProfile();
      _logger.info('login getProfileSuccess $getProfileSuccess');
      if (getProfileSuccess) {
        final getSipInfoSucces = await _getSipInfo();
        _logger.info('login getSipInfoSucces $getSipInfoSucces');
        if (getSipInfoSucces) {
          await _getExtensionInfo();
          return _registerSip(fcmToken: fcmToken);
        }
      }
    }
    if (isTest) {
      await _getExtensionInfo();
      return _registerSip(fcmToken: fcmToken);
    }
    return false;
  }

  Future<bool> _login(String username, String password) async {
    try {
      final tk = await _pitelApi.login(username: username, password: password);
      _token = tk;
      _logger.info('token - $_token');
      return true;
    } catch (err) {
      if (kDebugMode) {
        print(err);
      }
      return false;
    }
  }

  Future<bool> _getProfile() async {
    try {
      final profile = await _pitelApi.getProfile(token: _token);
      profileUser = profile;
      return true;
    } catch (err) {
      if (kDebugMode) {
        print(err);
      }
      return false;
    }
  }

  Future<bool> _getSipInfo() async {
    try {
      final pitelToken = await _pitelApi.getSipInfo(
        token: _token,
        sipUsername: profileUser.sipAccount.sipUserName,
      );
      _pitelToken = pitelToken;
      _logger.info('pitelToken $_pitelToken');
      return true;
    } catch (err) {
      _logger.error(err);
      return false;
    }
  }

  Future<bool> _getExtensionInfo() async {
    try {
      final sipResponse = await _pitelApi.getExtensionInfo(
        pitelToken: _pitelToken,
        sipUsername: profileUser.sipAccount.sipUserName,
      );
      if (sipResponse.enabled) {
        _logger.info('sipServer ${sipResponse.sipServer.toString()}');
        _sipServer = sipResponse.sipServer;
        _username = sipResponse.username;
        _password = sipResponse.password;
        _displayName = sipResponse.displayName;
        if (isTest) {
          _username = usernameTest;
          _password = passwordTest;
          _sipServer = SipServer(
            id: 0,
            domain: domainTest,
            port: portTest,
            outboundProxy: '',
            wss: wssTest,
            transport: 0,
            createdAt: '',
            project: '',
          );
        }
        _logger.info('sipAccount ${sipResponse.username} enabled');
        return true;
      } else {
        _logger.error('sipAccount ${sipResponse.username} not enabled');
        return false;
      }
    } catch (err) {
      _logger.error('_getExtensionInfo $err');
      if (isTest) {
        _username = usernameTest;
        _password = passwordTest;
        _sipServer = SipServer(
          id: 0,
          domain: domainTest,
          port: portTest,
          outboundProxy: '',
          wss: wssTest,
          transport: 0,
          createdAt: '',
          project: '',
        );
        return true;
      }
      return false;
    }
  }

  Future<void> logoutExtension(SipInfoData sipInfoData) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove("HAS_DEVICE_TOKEN");
    pitelCall.unregister();
  }

  String? get _mySipUri =>
      'sip:$_username@${_sipServer?.domain}:${_sipServer?.port}';
}



