import 'package:flutter/widgets.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_voip/component/voip_rtc_video_renderer.dart';

class VoipRTCVideoView extends RTCVideoView {
  VoipRTCVideoView(VoipRTCVideoRenderer renderer, {Key? key})
      : super(renderer, key: key);
}
