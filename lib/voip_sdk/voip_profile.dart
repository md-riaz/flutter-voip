import 'package:flutter_voip/model/http/get_profile.dart';
import 'package:flutter_voip/model/sip_account.dart';

class VoipProfileUser {
  String email;
  String username;
  String firstName;
  String lastName;
  String name;
  SipAccount sipAccount;

  VoipProfileUser({
    required this.email,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.name,
    required this.sipAccount,
  });

  factory VoipProfileUser.convertFrom(GetProfileResponse profileResponse) {
    return VoipProfileUser(
      email: profileResponse.email,
      username: profileResponse.username,
      firstName: profileResponse.firstName,
      lastName: profileResponse.lastName,
      name: profileResponse.name,
      sipAccount: profileResponse.sipAccount,
    );
  }

  @override
  String toString() {
    return 'email $email\n'
        'username $username\n'
        'firstName $firstName\n'
        'lastName $lastName\n'
        'name $name\n'
        'sipAccount username ${sipAccount.sipUserName}\n'
        'sipAccount pass ${sipAccount.sipPassword}';
  }
}

