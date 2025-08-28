import 'package:flutter/material.dart';
import 'package:flutter_voip/flutter_voip.dart';

class VideoDemo extends StatefulWidget {
  const VideoDemo({super.key});
  @override
  State<VideoDemo> createState() => _VideoDemoState();
}

class _VideoDemoState extends State<VideoDemo> implements SipHelperListener {
  final VoipCall _call = VoipCall();

  // Connection inputs
  final _wssCtrl =
      TextEditingController(text: 'wss://your-sbc.example.com:7443');
  final _domainCtrl = TextEditingController(text: 'your.sip.domain');
  final _portCtrl = TextEditingController(text: '5060');
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _displayCtrl = TextEditingController(text: 'Flutter SIP');
  final _destCtrl = TextEditingController();

  String _regState = 'Unregistered';
  String _callState = 'Idle';

  @override
  void initState() {
    super.initState();
    _call.addListener(this);
    _call.initializeLocal();
    _call.initializeRemote();
  }

  @override
  void dispose() {
    _call.unregister();
    _call.disposeLocalRenderer();
    _call.disposeRemoteRenderer();
    _wssCtrl.dispose();
    _domainCtrl.dispose();
    _portCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _displayCtrl.dispose();
    _destCtrl.dispose();
    super.dispose();
  }

  void _register() {
    final domain = _domainCtrl.text.trim();
    final port = _portCtrl.text.trim();
    final user = _userCtrl.text.trim();
    final pass = _passCtrl.text;
    final wss = _wssCtrl.text.trim();

    if (domain.isEmpty || port.isEmpty || user.isEmpty || pass.isEmpty || wss.isEmpty) {
      _toast('Please fill connection inputs');
      return;
    }

    final settings = VoipSettings();
    settings.webSocketUrl = wss;
    settings.webSocketSettings.allowBadCertificate = true;
    settings.uri = 'sip:$user@$domain:$port';
    settings.authorizationUser = user;
    settings.password = pass;
    settings.displayName = _displayCtrl.text.trim().isEmpty
        ? user
        : _displayCtrl.text.trim();
    settings.userAgent = 'Flutter VoIP Example';
    settings.sipDomain = '$domain:$port';
    settings.dtmfMode = DtmfMode.RFC2833;
    _call.register(settings);
  }

  Future<void> _makeVideoCall() async {
    final dest = _destCtrl.text.trim();
    final domain = _domainCtrl.text.trim();
    final port = _portCtrl.text.trim();
    if (dest.isEmpty) return _toast('Enter a destination');
    await _call.call('sip:$dest@$domain:$port', false); // video enabled
  }

  void _answer() {
    _call.answer();
  }

  void _hangup() {
    _call.hangup();
  }

  void _toggleCam() {
    _call.toggleCamera();
  }

  void _toggleMute() {
    _call.mute();
  }

  void _toggleSpeaker() {
    _call.enableSpeakerphone(!_call.audioMuted);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video Call Demo')),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    color: Colors.black,
                    child: _call.remoteRenderer?.isInit == true
                        ? FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: 480,
                              height: 320,
                              child: VoipRTCVideoView(_call.remoteRenderer!),
                            ),
                          )
                        : const Center(
                            child: Text('Remote video',
                                style: TextStyle(color: Colors.white))),
                  ),
                ),
                Expanded(
                  child: Container(
                    color: Colors.black,
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: SizedBox(
                        width: 160,
                        height: 120,
                        child: _call.localRenderer?.isInit == true
                            ? VoipRTCVideoView(_call.localRenderer!)
                            : const ColoredBox(color: Colors.black54),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Register: $_regState    |    Call: $_callState'),
                const SizedBox(height: 8),
                _rowField('WSS URL', _wssCtrl, hint: 'wss://host:port'),
                _rowField('Domain', _domainCtrl, hint: 'example.com'),
                _rowField('Port', _portCtrl, keyboardType: TextInputType.number),
                _rowField('Username', _userCtrl),
                _rowField('Password', _passCtrl, obscureText: true),
                _rowField('Display Name', _displayCtrl),
                Row(children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _register,
                      child: const Text('Register'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _call.unregister,
                      child: const Text('Unregister'),
                    ),
                  ),
                ]),
                const Divider(height: 24),
                _rowField('Destination', _destCtrl, hint: '1001'),
                Wrap(spacing: 12, children: [
                  ElevatedButton(
                    onPressed: _makeVideoCall,
                    child: const Text('Call'),
                  ),
                  OutlinedButton(
                    onPressed: _hangup,
                    child: const Text('Hangup'),
                  ),
                  FilledButton(
                    onPressed: _answer,
                    child: const Text('Answer'),
                  ),
                ]),
                const SizedBox(height: 8),
                Wrap(spacing: 12, children: [
                  OutlinedButton(
                    onPressed: _toggleCam,
                    child: const Text('Toggle Camera'),
                  ),
                  OutlinedButton(
                    onPressed: _toggleMute,
                    child: const Text('Mute/Unmute'),
                  ),
                  OutlinedButton(
                    onPressed: _toggleSpeaker,
                    child: const Text('Speaker On/Off'),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // SipHelperListener (SDK-level)
  @override
  void callStateChanged(String callId, VoipCallState state) {
    setState(() => _callState = state.state.toString().split('.').last);
  }

  @override
  void onCallInitiated(String callId) {}

  @override
  void onCallReceived(String callId) {}

  @override
  void onNewMessage(VoipSIPMessageRequest msg) {}

  @override
  void registrationStateChanged(VoipRegistrationState state) {
    setState(() => _regState = state.state.toString().split('.').last);
  }

  @override
  void transportStateChanged(VoipTransportState state) {}

  Widget _rowField(String label, TextEditingController controller,
      {String? hint,
      TextInputType? keyboardType,
      bool obscureText = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            decoration: InputDecoration(
              hintText: hint,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

