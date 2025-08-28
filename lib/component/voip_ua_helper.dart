import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:logger/logger.dart';
import 'package:flutter_voip/sip/sip_ua.dart';
import 'package:flutter_voip/sip/src/config.dart';
import 'package:flutter_voip/sip/src/constants.dart' as dart_sip_c;
import 'package:flutter_voip/sip/src/event_manager/event_manager.dart';
import 'package:flutter_voip/sip/src/logger.dart';
import 'package:flutter_voip/sip/src/message.dart';
import 'package:flutter_voip/sip/src/rtc_session.dart';
import 'package:flutter_voip/sip/src/stack_trace_nj.dart';
import 'package:flutter_voip/sip/src/transports/websocket_interface.dart';
import 'package:flutter_voip/sip/src/ua.dart';

class VoipUAHelper extends EventManager {
  VoipUA? _ua;
  SipCoreSettings? _settings;
  late VoipSettings _uaSettings;
  final Map<String?, Call> _calls = <String?, Call>{};

  RegistrationState _registerState =
      RegistrationState(state: RegistrationStateEnum.none);

  set loggingLevel(Level loggingLevel) => Log.loggingLevel = loggingLevel;

  bool get registered {
    if (_ua != null) {
      return _ua!.isRegistered() ?? false;
    }
    return false;
  }

  bool get connected {
    if (_ua != null) {
      return _ua!.isConnected();
    }
    return false;
  }

  RegistrationState get registerState => _registerState;

  void stop() async {
    if (_ua != null) {
      _ua!.stop();
    } else {
      Log.w('ERROR: stop called but not started, call start first.');
    }
  }

  void register() {
    assert(_ua != null,
        'register called but not started, you must call start first.');
    _ua!.register();
  }

  void unregister([bool all = true]) {
    if (_ua != null) {
      assert(registered, 'ERROR: you must call register first.');
      _ua!.unregister(all: all);
    } else {
      Log.e('ERROR: unregister called, you must call start first.');
    }
  }

  Future<bool> call(String target,
      {bool voiceonly = false,
      MediaStream? mediaStream,
      List<String>? headers}) async {
    if (_ua != null && _ua!.isConnected()) {
      Map<String, dynamic> options = buildCallOptions(voiceonly);
      if (mediaStream != null) {
        options['mediaStream'] = mediaStream;
      }
      List<dynamic> extHeaders = options['extraHeaders'] as List<dynamic>;
      extHeaders.addAll(headers ?? <String>[]);
      _ua!.call(target, options);
      return true;
    } else {
      logger.error(
          'Not connected, you will need to register.', null, StackTraceNJ());
    }
    return false;
  }

  Call? findCall(String id) {
    return _calls[id];
  }

  void start(VoipSettings uaSettings) async {
    //! WARNING
    if (_ua != null) {
      logger.warn(
          'UA instance already exist!, stopping UA and creating a one...');
      _ua!.stop();
    }

    _uaSettings = uaSettings;

    _settings = SipCoreSettings();
    WebSocketInterface socket = WebSocketInterface(
        uaSettings.webSocketUrl, uaSettings.webSocketSettings);
    _settings!.sockets = <WebSocketInterface>[socket];
    _settings!.uri = uaSettings.uri;
    _settings!.contactUri = uaSettings.contactUri;
    _settings!.password = uaSettings.password;
    //! sip_domain
    _settings!.sipDomain = uaSettings.sipDomain;
    _settings!.ha1 = uaSettings.ha1;
    _settings!.displayName = uaSettings.displayName;
    _settings!.authorizationUser = uaSettings.authorizationUser;
    _settings!.userAgent = uaSettings.userAgent ?? dart_sip_c.USER_AGENT;
    _settings!.register = uaSettings.register;
    _settings!.registerExpires = uaSettings.register_expires;
    _settings!.registerExtraContactUriParams =
        uaSettings.registerParams.extraContactUriParams;
    _settings!.dtmfMode = uaSettings.dtmfMode;
    _settings!.sessionTimers = uaSettings.sessionTimers;
    _settings!.ice_gathering_timeout = uaSettings.iceGatheringTimeout;

    try {
      _ua = VoipUA(_settings);
      List<String> extraHeaders = [];
      uaSettings.webSocketSettings.extraHeaders.forEach((key, value) {
        extraHeaders.add('$key: $value');
      });
      _ua!.registrator()?.setExtraHeaders(extraHeaders);
      _ua!.on(EventSocketConnecting(), (EventSocketConnecting event) {
        logger.debug('connecting => ' + event.toString());
        _notifyTransportStateListeners(
            VoipTransportState(TransportStateEnum.CONNECTING));
      });

      _ua!.on(EventSocketConnected(), (EventSocketConnected event) {
        logger.debug('connected => ' + event.toString());
        _notifyTransportStateListeners(
            VoipTransportState(TransportStateEnum.CONNECTED));
      });

      _ua!.on(EventSocketDisconnected(), (EventSocketDisconnected event) {
        logger.debug('disconnected => ' + (event.cause.toString()));
        _notifyTransportStateListeners(VoipTransportState(
            TransportStateEnum.DISCONNECTED,
            cause: event.cause));
      });

      _ua!.on(EventRegistered(), (EventRegistered event) {
        logger.debug('registered => ' + event.cause.toString());
        _registerState = RegistrationState(
            state: RegistrationStateEnum.registered, cause: event.cause);
        _notifyRegsistrationStateListeners(_registerState);
      });

      _ua!.on(EventUnregister(), (EventUnregister event) {
        logger.debug('unregistered => ' + event.cause.toString());
        _registerState = RegistrationState(
            state: RegistrationStateEnum.unregistered, cause: event.cause);
        _notifyRegsistrationStateListeners(_registerState);
      });

      _ua!.on(EventRegistrationFailed(), (EventRegistrationFailed event) {
        logger.debug('registrationFailed => ' + (event.cause.toString()));
        _registerState = RegistrationState(
            state: RegistrationStateEnum.registrationFailed,
            cause: event.cause);
        _notifyRegsistrationStateListeners(_registerState);
      });

      _ua!.on(EventNewRTCSession(), (EventNewRTCSession event) {
        logger.debug('newRTCSession => ' + event.toString());
        RTCSession session = event.session!;
        if (session.direction == 'incoming') {
          // Set event handlers.
          session.addAllEventHandlers(
              buildCallOptions()['eventHandlers'] as EventManager);
        }
        _calls[event.id] =
            Call(event.id, session, VoipCallStateEnum.CALL_INITIATION);
        _notifyCallStateListeners(
            event, VoipCallState(VoipCallStateEnum.CALL_INITIATION));
      });

      _ua!.on(EventNewMessage(), (EventNewMessage event) {
        logger.debug('newMessage => ' + event.toString());
        //Only notify incoming message to listener
        if (event.message!.direction == 'incoming') {
          SIPMessageRequest message =
              SIPMessageRequest(event.message, event.originator, event.request);
          _notifyNewMessageListeners(message);
        }
      });

      _ua!.start();
    } catch (event, s) {
      logger.error(event.toString(), null, s);
    }
  }

  /// Build the call options.
  /// You may override this method in a custom SIPUAHelper class in order to
  /// modify the options to your needs.
  Map<String, dynamic> buildCallOptions([bool voiceonly = false]) =>
      _options(voiceonly);

  Map<String, dynamic> _options([bool voiceonly = false]) {
    // Register callbacks to desired call events
    EventManager handlers = EventManager();
    handlers.on(EventCallConnecting(), (EventCallConnecting event) {
      logger.debug('call connecting');
      _notifyCallStateListeners(
          event, VoipCallState(VoipCallStateEnum.CONNECTING));
    });
    handlers.on(EventCallProgress(), (EventCallProgress event) {
      logger.debug('call is in progress');
      _notifyCallStateListeners(
          event,
          VoipCallState(VoipCallStateEnum.PROGRESS,
              originator: event.originator));
    });
    handlers.on(EventCallFailed(), (EventCallFailed event) {
      logger.debug('call failed with cause: ' + (event.cause.toString()));
      _notifyCallStateListeners(
          event,
          VoipCallState(VoipCallStateEnum.FAILED,
              originator: event.originator, cause: event.cause));
      _calls.remove(event.id);
    });
    handlers.on(EventCallEnded(), (EventCallEnded event) {
      logger.debug('call ended with cause: ' + (event.cause.toString()));
      _notifyCallStateListeners(
          event,
          VoipCallState(VoipCallStateEnum.ENDED,
              originator: event.originator, cause: event.cause));
      _calls.remove(event.id);
    });
    handlers.on(EventCallAccepted(), (EventCallAccepted event) {
      logger.debug('call accepted');
      _notifyCallStateListeners(
          event, VoipCallState(VoipCallStateEnum.ACCEPTED));
    });
    handlers.on(EventCallConfirmed(), (EventCallConfirmed event) {
      logger.debug('call confirmed');
      _notifyCallStateListeners(
          event, VoipCallState(VoipCallStateEnum.CONFIRMED));
    });
    handlers.on(EventCallHold(), (EventCallHold event) {
      logger.debug('call hold');
      _notifyCallStateListeners(
          event,
          VoipCallState(VoipCallStateEnum.HOLD,
              originator: event.originator));
    });
    handlers.on(EventCallUnhold(), (EventCallUnhold event) {
      logger.debug('call unhold');
      _notifyCallStateListeners(
          event,
          VoipCallState(VoipCallStateEnum.UNHOLD,
              originator: event.originator));
    });
    handlers.on(EventCallMuted(), (EventCallMuted event) {
      logger.debug('call muted');
      _notifyCallStateListeners(
          event,
          VoipCallState(VoipCallStateEnum.MUTED,
              audio: event.audio ?? false, video: event.video ?? false));
    });
    handlers.on(EventCallUnmuted(), (EventCallUnmuted event) {
      logger.debug('call unmuted');
      _notifyCallStateListeners(
          event,
          VoipCallState(VoipCallStateEnum.UNMUTED,
              audio: event.audio ?? false, video: event.video ?? false));
    });
    handlers.on(EventStream(), (EventStream event) async {
      // Wating for callscreen ready.
      Timer(const Duration(milliseconds: 100), () {
        _notifyCallStateListeners(
            event,
            VoipCallState(VoipCallStateEnum.STREAM,
                stream: event.stream, originator: event.originator));
      });
    });
    handlers.on(EventCallRefer(), (EventCallRefer refer) async {
      logger.debug('Refer received, Transfer current call to => ${refer.aor}');
      _notifyCallStateListeners(
          refer, VoipCallState(VoipCallStateEnum.REFER, refer: refer));
      //Always accept.
      refer.accept((RTCSession session) {
        logger.debug('session initialized.');
      }, buildCallOptions(true));
    });

    Map<String, dynamic> _defaultOptions = <String, dynamic>{
      'eventHandlers': handlers,
      'extraHeaders': <dynamic>[],
      'pcConfig': <String, dynamic>{
        'sdpSemantics': 'unified-plan',
        'iceServers': _uaSettings.iceServers
      },
      'mediaConstraints': <String, dynamic>{
        'audio': true,
        'video': voiceonly
            ? false
            : <String, dynamic>{
                'mandatory': <String, dynamic>{
                  'minWidth': '640',
                  'minHeight': '480',
                  'minFrameRate': '30',
                },
                'facingMode': 'user',
                'optional': <dynamic>[],
              }
      },
      'rtcOfferConstraints': <String, dynamic>{
        'mandatory': <String, dynamic>{
          'OfferToReceiveAudio': true,
          'OfferToReceiveVideo': !voiceonly,
        },
        'optional': <dynamic>[],
      },
      'rtcAnswerConstraints': <String, dynamic>{
        'mandatory': <String, dynamic>{
          'OfferToReceiveAudio': true,
          'OfferToReceiveVideo': true,
        },
        'optional': <dynamic>[],
      },
      'rtcConstraints': <String, dynamic>{
        'mandatory': <dynamic, dynamic>{},
        'optional': <Map<String, dynamic>>[
          <String, dynamic>{'DtlsSrtpKeyAgreement': true},
        ],
      },
      'sessionTimersExpires': 120
    };
    return _defaultOptions;
  }

  Message sendMessage(String target, String body,
      [Map<String, dynamic>? options]) {
    return _ua!.sendMessage(target, body, options);
  }

  void terminateSessions(Map<String, dynamic> options) {
    _ua!.terminateSessions(options as Map<String, Object>);
  }

  final Set<SipUaHelperListener> _sipUaHelperListeners =
      <SipUaHelperListener>{};

  void addSipUaHelperListener(SipUaHelperListener listener) {
    _sipUaHelperListeners.add(listener);
  }

  void removeSipUaHelperListener(SipUaHelperListener listener) {
    _sipUaHelperListeners.remove(listener);
  }

  void _notifyTransportStateListeners(VoipTransportState state) {
    for (var listener in _sipUaHelperListeners) {
      listener.transportStateChanged(state);
    }
  }

  void _notifyRegsistrationStateListeners(RegistrationState state) {
    for (var listener in _sipUaHelperListeners) {
      listener.registrationStateChanged(state);
    }
  }

  void _notifyCallStateListeners(CallEvent event, VoipCallState state) {
    Call? call = _calls[event.id];
    if (call == null) {
      logger.e('Call ${event.id} not found!');
      return;
    }
    call.state = state.state;
    for (var listener in _sipUaHelperListeners) {
      listener.callStateChanged(call, state);
    }
  }

  void _notifyNewMessageListeners(SIPMessageRequest msg) {
    for (var listener in _sipUaHelperListeners) {
      listener.onNewMessage(msg);
    }
  }
}
