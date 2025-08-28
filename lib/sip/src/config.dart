import '../sip_ua.dart';
import 'constants.dart' as dart_sip_c;
import 'constants.dart';
import 'exceptions.dart' as exceptions;
import 'grammar.dart';
import 'logger.dart';
// ignore: library_prefixes
import 'socket.dart' as Socket;
import 'transports/websocket_interface.dart';
import 'uri.dart';
import 'utils.dart' as utils;

// Default settings.
class SipCoreSettings {
  // SIP authentication.
  String? authorizationUser;
  String? password;
  String? realm;
  String? ha1;

  // SIP account.
  String? displayName;
  dynamic uri;
  dynamic contactUri;
  //! sip_domain
  dynamic sipDomain;
  String userAgent = dart_sip_c.USER_AGENT;

  // SIP instance id (GRUU).
  String? instanceId;

  // Preloaded SIP Route header field.
  bool usePreloadedRoute = true;

  // Session parameters.
  bool sessionTimers = true;
  SipMethod sessionTimersRefreshMethod = SipMethod.UPDATE;
  int noAnswerTimeout = 60;

  // Registration parameters.
  bool? register = true;
  int? registerExpires = 600;
  dynamic registrarServer;
  Map<String, dynamic>? registerExtraContactUriParams;

  // Dtmf mode
  DtmfMode dtmfMode = DtmfMode.INFO;

  // Connection options.
  List<WebSocketInterface>? sockets = <WebSocketInterface>[];
  // ignore: non_constant_identifier_names
  int connection_recovery_max_interval = 30;
  // ignore: non_constant_identifier_names
  int connection_recovery_min_interval = 2;

  /*
   * Host address.
   * Value to be set in Via sent_by and host part of Contact FQDN.
  */
  // ignore: non_constant_identifier_names
  String? via_host = '${utils.createRandomToken(12)}.invalid';

  // DartSIP ID
  // ignore: non_constant_identifier_names
  String? jssip_id;

  // ignore: non_constant_identifier_names
  String? hostport_params;

  /// ICE Gathering Timeout (in millisecond).
  // ignore: non_constant_identifier_names
  int ice_gathering_timeout = 500;
}

// (breaking change) Class renamed to SipCoreSettings

// Configuration checks.
class Checks {
  Map<String, Null Function(SipCoreSettings src, SipCoreSettings? dst)>
      mandatory =
      <String, Null Function(SipCoreSettings src, SipCoreSettings? dst)>{
    'sockets': (SipCoreSettings src, SipCoreSettings? dst) {
      List<WebSocketInterface>? sockets = src.sockets;
      /* Allow defining sockets parameter as:
       *  Socket: socket
       *  List of Socket: [socket1, socket2]
       *  List of Objects: [{socket: socket1, weight:1}, {socket: Socket2, weight:0}]
       *  List of Objects and Socket: [{socket: socket1}, socket2]
       */
      List<WebSocketInterface> copy = <WebSocketInterface>[];
      if (sockets is List && sockets!.isNotEmpty) {
        for (WebSocketInterface socket in sockets) {
          if (Socket.isSocket(socket)) {
            copy.add(socket);
          }
        }
      } else {
        throw exceptions.ConfigurationError('sockets', sockets);
      }

      dst!.sockets = copy;
    },
    'uri': (SipCoreSettings src, SipCoreSettings? dst) {
      dynamic uri = src.uri;
      if (src.uri == null && dst!.uri == null) {
        throw exceptions.ConfigurationError('uri', null);
      }
      if (!uri.contains(RegExp(r'^sip:', caseSensitive: false))) {
        uri = '${dart_sip_c.SIP}:$uri';
      }
      dynamic parsed = URI.parse(uri);
      if (parsed == null) {
        throw exceptions.ConfigurationError('uri', parsed);
      } else if (parsed.user == null) {
        throw exceptions.ConfigurationError('uri', parsed);
      } else {
        dst!.uri = parsed;
      }
    }
  };
  Map<String, Null Function(SipCoreSettings src, SipCoreSettings? dst)>
      optional =
      <String, Null Function(SipCoreSettings src, SipCoreSettings? dst)>{
    'authorization_user': (SipCoreSettings src, SipCoreSettings? dst) {
      String? authorizationUser = src.authorizationUser;
      if (authorizationUser == null) return;
      if (Grammar.parse('"$authorizationUser"', 'quoted_string') == -1) {
        return;
      } else {
        dst!.authorizationUser = authorizationUser;
      }
    },
    //! sip_domain
    'sip_domain': (SipCoreSettings src, SipCoreSettings? dst) {
      String sipDomain = src.sipDomain;
      dst!.sipDomain = sipDomain;
    },
    'user_agent': (SipCoreSettings src, SipCoreSettings? dst) {
      String userAgent = src.userAgent;
      dst!.userAgent = userAgent;
    },
    'connection_recovery_max_interval':
        (SipCoreSettings src, SipCoreSettings? dst) {
      int connectionRecoveryMaxInterval = src.connection_recovery_max_interval;
      if (connectionRecoveryMaxInterval > 0) {
        dst!.connection_recovery_max_interval = connectionRecoveryMaxInterval;
      }
    },
    'connection_recovery_min_interval':
        (SipCoreSettings src, SipCoreSettings? dst) {
      int connectionRecoveryMinInterval = src.connection_recovery_min_interval;
      if (connectionRecoveryMinInterval > 0) {
        dst!.connection_recovery_min_interval = connectionRecoveryMinInterval;
      }
    },
    'contact_uri': (SipCoreSettings src, SipCoreSettings? dst) {
      dynamic contactUri = src.contactUri;
      if (contactUri == null) return;
      if (contactUri is String) {
        dynamic uri = Grammar.parse(contactUri, 'SIP_URI');
        if (uri != -1) {
          dst!.contactUri = uri;
        }
      }
    },
    'display_name': (SipCoreSettings src, SipCoreSettings? dst) {
      String? displayName = src.displayName;
      if (displayName == null) return;
      dst!.displayName = displayName;
    },
    'instance_id': (SipCoreSettings src, SipCoreSettings? dst) {
      String? instanceId = src.instanceId;
      if (instanceId == null) return;
      if (instanceId.contains(RegExp(r'^uuid:', caseSensitive: false))) {
        instanceId = instanceId.substring(5);
      }
      if (Grammar.parse(instanceId, 'uuid') == -1) {
        return;
      } else {
        dst!.instanceId = instanceId;
      }
    },
    'no_answer_timeout': (SipCoreSettings src, SipCoreSettings? dst) {
      int noAnswerTimeout = src.noAnswerTimeout;
      if (noAnswerTimeout > 0) {
        dst!.noAnswerTimeout = noAnswerTimeout;
      }
    },
    'session_timers': (SipCoreSettings src, SipCoreSettings? dst) {
      bool sessionTimers = src.sessionTimers;
      dst!.sessionTimers = sessionTimers;
    },
    'session_timers_refresh_method':
        (SipCoreSettings src, SipCoreSettings? dst) {
      SipMethod method = src.sessionTimersRefreshMethod;
      if (method == SipMethod.INVITE || method == SipMethod.UPDATE) {
        dst!.sessionTimersRefreshMethod = method;
      }
    },
    'password': (SipCoreSettings src, SipCoreSettings? dst) {
      String? password = src.password;
      if (password == null) return;
      dst!.password = password.toString();
    },
    'realm': (SipCoreSettings src, SipCoreSettings? dst) {
      String? realm = src.realm;
      if (realm == null) return;
      dst!.realm = realm.toString();
    },
    'ha1': (SipCoreSettings src, SipCoreSettings? dst) {
      String? ha1 = src.ha1;
      if (ha1 == null) return;
      dst!.ha1 = ha1.toString();
    },
    'register': (SipCoreSettings src, SipCoreSettings? dst) {
      bool? register = src.register;
      if (register == null) return;
      dst!.register = register;
    },
    'register_expires': (SipCoreSettings src, SipCoreSettings? dst) {
      int? registerExpires = src.registerExpires;
      if (registerExpires == null) return;
      if (registerExpires > 0) {
        dst!.registerExpires = registerExpires;
      }
    },
    'registrar_server': (SipCoreSettings src, SipCoreSettings? dst) {
      dynamic registrarServer = src.registrarServer;
      if (registrarServer == null) return;
      if (!registrarServer.contains(RegExp(r'^sip:', caseSensitive: false))) {
        registrarServer = '${dart_sip_c.SIP}:$registrarServer';
      }
      dynamic parsed = URI.parse(registrarServer);
      if (parsed == null || parsed.user != null) {
        return;
      } else {
        dst!.registrarServer = parsed;
      }
    },
    'register_extra_contact_uri_params':
        (SipCoreSettings src, SipCoreSettings? dst) {
      Map<String, dynamic>? registerExtraContactUriParams =
          src.registerExtraContactUriParams;
      if (registerExtraContactUriParams == null) return;
      dst!.registerExtraContactUriParams = registerExtraContactUriParams;
    },
    'use_preloaded_route': (SipCoreSettings src, SipCoreSettings? dst) {
      bool usePreloadedRoute = src.usePreloadedRoute;
      dst!.usePreloadedRoute = usePreloadedRoute;
    },
    'dtmf_mode': (SipCoreSettings src, SipCoreSettings? dst) {
      DtmfMode dtmfMode = src.dtmfMode;
      dst!.dtmfMode = dtmfMode;
    },
  };
}

final Checks checks = Checks();

void load(SipCoreSettings src, SipCoreSettings? dst) {
  try {
    // Check Mandatory parameters.
    checks.mandatory.forEach((String parameter,
        Null Function(SipCoreSettings, SipCoreSettings?) fun) {
      logger.info('Check mandatory parameter => $parameter.');
      fun(src, dst);
    });

    // Check Optional parameters.
    checks.optional.forEach((String parameter,
        Null Function(SipCoreSettings, SipCoreSettings?) fun) {
      logger.debug('Check optional parameter => $parameter.');
      fun(src, dst);
    });
  } catch (e) {
    logger.error('Failed to load config: ${e.toString()}');
    rethrow;
  }
}
