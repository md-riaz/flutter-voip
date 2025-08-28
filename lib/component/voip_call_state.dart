import 'package:flutter_voip/sip/sip_ua.dart';
import 'package:flutter_voip/sip/src/event_manager/events.dart';
import 'package:flutter_voip/sip/src/message.dart';

class VoipRegistrationState {
  late VoipRegistrationStateEnum state;
  late ErrorCause cause;

  VoipRegistrationState(RegistrationState registerState) {
    state = registerState.state!.convertToVoipRegistrationStateEnum();
    cause = registerState.cause!;
  }
}

enum VoipRegistrationStateEnum {
  none,
  registrationFailed,
  registered,
  unregistered,
}

extension RegistrationStateEnumExt on RegistrationStateEnum {
  VoipRegistrationStateEnum convertToVoipRegistrationStateEnum() {
    switch (this) {
      case RegistrationStateEnum.none:
        return VoipRegistrationStateEnum.none;
      case RegistrationStateEnum.registered:
        return VoipRegistrationStateEnum.registered;
      case RegistrationStateEnum.registrationFailed:
        return VoipRegistrationStateEnum.registrationFailed;
      case RegistrationStateEnum.unregistered:
        return VoipRegistrationStateEnum.unregistered;
    }
  }
}

class VoipSIPMessageRequest extends SIPMessageRequest {
  VoipSIPMessageRequest(Message message, String originator, dynamic request)
      : super(message, originator, request);
}
