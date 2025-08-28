import 'package:flutter/material.dart';
import 'package:flutter_voip/config/voip_config.dart';

class VoipLog {
  VoipLog({required String tag}) : _tag = tag;
  final String _tag;

  void error(dynamic message) {
    if (VoipConfig.isDebug) {
      debugPrint('VoipLogError - $_tag, $message');
    }
  }

  void info(dynamic message) {
    if (VoipConfig.isDebug) {
      debugPrint('VoipLogInfo - $_tag, $message');
    }
  }
}
