import 'package:flutter_voip/model/http/base_header.dart';

class GetSipInfoRequest {
  String number;

  GetSipInfoRequest({required this.number});

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'number': number,
    };
  }

  factory GetSipInfoRequest.fromMap(Map<String, dynamic> map) {
    return GetSipInfoRequest(
      number: map['number'] as String,
    );
  }
}

class GetSipInfoHeaders extends BaseHeaders {
  GetSipInfoHeaders({required String token})
      : super(authorization: 'JWT $token');
}

class GetSipInfoResponse {
  String token;

  GetSipInfoResponse({required this.token});

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'token': token,
    };
  }

  factory GetSipInfoResponse.fromMap(Map<String, dynamic> map) {
    return GetSipInfoResponse(
      token: map['token'] as String,
    );
  }
}
