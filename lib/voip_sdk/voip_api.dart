import 'dart:async';

import 'package:flutter_voip/model/http/get_extension_info.dart';
import 'package:flutter_voip/model/http/get_profile.dart';
import 'package:flutter_voip/model/http/get_sip_info.dart';
import 'package:flutter_voip/model/http/login.dart';
import 'package:flutter_voip/voip_sdk/voip_profile.dart';
import 'package:flutter_voip/web_service/api_web_service.dart';
import 'package:flutter_voip/web_service/portal_service.dart';
import 'package:flutter_voip/web_service/sdk_service.dart';

class _VoipAPIImplement implements VoipApi {
  final ApiWebService _sdkService = SDKService.getInstance();
  final ApiWebService _portalService = PortalService.getInstance();

  @override
  Future<String> login(
      {String api = '/api/v1/auth/login/',
      required String username,
      required String password}) async {
    final request = LoginRequest(username: username, password: password);
    try {
      final response = await _sdkService.post(api, null, request.toMap());
      final loginResponse = LoginResponse.fromMap(response);
      return loginResponse.token;
    } catch (err) {
      rethrow;
    }
  }

  @override
  Future<VoipProfileUser> getProfile(
      {String api = '/api/v1/auth/profile/', required String token}) async {
    final headers = GetProfileHeaders(token: token);
    try {
      final response = await _sdkService.get(api, headers.toMap(), null);
      final profileResponse = GetProfileResponse.fromMap(response);
      final profileUser = VoipProfileUser.convertFrom(profileResponse);
      return profileUser;
    } catch (err) {
      rethrow;
    }
  }

  @override
  Future<String> getSipInfo(
      {String api = '/api/v1/sdk/token/',
      required String token,
      required String sipUsername}) async {
    final headers = GetSipInfoHeaders(token: token);
    final params = GetSipInfoRequest(number: sipUsername);
    try {
      final response =
          await _sdkService.get(api, headers.toMap(), params.toMap());
      final pitelToken = GetSipInfoResponse.fromMap(response);
      return pitelToken.token;
    } catch (err) {
      rethrow;
    }
  }

  @override
  Future<GetExtensionResponse> getExtensionInfo(
      {String api = '/sdk/info/',
      required String pitelToken,
      required String sipUsername}) async {
    final headers = GetExtensionInfoHeaders(xPitelToken: pitelToken);
    final params = GetExtensionInfoRequest(number: sipUsername);
    try {
      final response =
          await _portalService.get(api, headers.toMap(), params.toMap());
      final getExtInfo = GetExtensionResponse.fromMap(response);
      return getExtInfo;
    } catch (err) {
      rethrow;
    }
  }

}

abstract class VoipApi {
  static VoipApi? _instance;
  static VoipApi getInstance() {
    _instance ??= _VoipAPIImplement();
    return _instance!;
  }

  // Allow apps to inject their own implementation
  static void setInstance(VoipApi api) {
    _instance = api;
  }

  Future<String> login(
      {String api = '/api/v1/auth/login/',
      required String username,
      required String password});

  Future<VoipProfileUser> getProfile(
      {String api = '/api/v1/auth/profile/', required String token});

  Future<String> getSipInfo(
      {String api = '/api/v1/sdk/token/',
      required String token,
      required String sipUsername});

  Future<GetExtensionResponse> getExtensionInfo(
      {String api = '/sdk/info/',
      required String pitelToken,
      required String sipUsername});

}
