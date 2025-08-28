import 'package:flutter/material.dart';
import 'package:flutter_voip/flutter_voip.dart';
import 'package:flutter_voip/component/voip_ua_helper.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class CallControlsDemo extends StatefulWidget {
  const CallControlsDemo({super.key});
  @override
  State<CallControlsDemo> createState() => _CallControlsDemoState();
}

class _CallControlsDemoState extends State<CallControlsDemo>
    implements SipUaHelperListener {
  final _ua = VoipUAHelper();

  // Connection inputs
  final _wssCtrl =
      TextEditingController(text: 'wss://your-sbc.example.com:7443');
  final _domainCtrl = TextEditingController(text: 'your.sip.domain');
  final _portCtrl = TextEditingController(text: '5060');
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _displayCtrl = TextEditingController(text: 'Flutter SIP');

  // Call inputs
  final _destCtrl = TextEditingController();
  final _referCtrl = TextEditingController();
  final _infoBodyCtrl = TextEditingController(text: 'app/example');

  // State
  String? _currentCallId;
  String _callState = 'Idle';
  bool _incoming = false;
  bool _muted = false;
  bool _held = false;
  bool _speaker = false;

  String _transport = 'DISCONNECTED';
  String _registration = 'Unregistered';

  @override
  void initState() {
    super.initState();
    _ua.addSipUaHelperListener(this);
  }

  @override
  void dispose() {
    _ua.removeSipUaHelperListener(this);
    _ua.stop();
    _wssCtrl.dispose();
    _domainCtrl.dispose();
    _portCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _displayCtrl.dispose();
    _destCtrl.dispose();
    _referCtrl.dispose();
    _infoBodyCtrl.dispose();
    super.dispose();
  }

  void _register() {
    final domain = _domainCtrl.text.trim();
    final port = _portCtrl.text.trim();
    final user = _userCtrl.text.trim();
    final pass = _passCtrl.text;
    final wss = _wssCtrl.text.trim();
    if (domain.isEmpty || port.isEmpty || user.isEmpty || pass.isEmpty || wss.isEmpty) {
      _toast('Please fill all connection fields');
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
    _ua.start(settings);
  }

  void _unregister() => _ua.unregister();

  Future<void> _makeCall() async {
    final dest = _destCtrl.text.trim();
    final domain = _domainCtrl.text.trim();
    final port = _portCtrl.text.trim();
    if (dest.isEmpty) return _toast('Enter a destination number');
    await _ua.call('sip:$dest@$domain:$port', voiceonly: true);
  }

  void _answer() {
    if (_currentCallId == null) return;
    _ua.findCall(_currentCallId!)?.answer(_ua.buildCallOptions(true));
  }

  void _hangup() {
    if (_currentCallId == null) return;
    _ua.findCall(_currentCallId!)?.hangup();
  }

  void _toggleMute() {
    if (_currentCallId == null) return;
    final call = _ua.findCall(_currentCallId!);
    if (call == null) return;
    if (_muted) {
      call.unmute(true, false);
    } else {
      call.mute(true, false);
    }
  }

  void _toggleHold() {
    if (_currentCallId == null) return;
    final call = _ua.findCall(_currentCallId!);
    if (call == null) return;
    if (_held) {
      call.unhold();
    } else {
      call.hold();
    }
  }

  void _toggleSpeaker() {
    _speaker = !_speaker;
    Helper.setSpeakerphoneOn(_speaker);
    setState(() {});
  }

  void _sendDTMF(String tone) {
    if (_currentCallId == null) return;
    _ua.findCall(_currentCallId!)?.sendDTMF(tone);
  }

  void _sendInfo() {
    if (_currentCallId == null) return;
    _ua
        .findCall(_currentCallId!)
        ?.sendInfo('application/custom', _infoBodyCtrl.text, {});
  }

  void _refer() {
    if (_currentCallId == null) return;
    final target = _referCtrl.text.trim();
    if (target.isEmpty) return _toast('Enter refer target');
    _ua.findCall(_currentCallId!)?.refer(target);
  }

  // SipUaHelperListener
  @override
  void transportStateChanged(VoipTransportState state) {
    setState(() => _transport = state.state.toString().split('.').last);
  }

  @override
  void registrationStateChanged(RegistrationState state) {
    setState(() => _registration = state.state.toString().split('.').last);
  }

  @override
  void callStateChanged(Call call, VoipCallState state) {
    setState(() {
      _currentCallId = call.id;
      _callState = state.state.toString().split('.').last;
      _incoming = call.direction.toUpperCase() == 'INCOMING';
      if (state.state == VoipCallStateEnum.MUTED) {
        if (state.audio) _muted = true;
      }
      if (state.state == VoipCallStateEnum.UNMUTED) {
        if (state.audio) _muted = false;
      }
      if (state.state == VoipCallStateEnum.HOLD) {
        _held = true;
      }
      if (state.state == VoipCallStateEnum.UNHOLD) {
        _held = false;
      }
      if (state.state == VoipCallStateEnum.ENDED ||
          state.state == VoipCallStateEnum.FAILED) {
        _incoming = false;
        _muted = false;
        _held = false;
        _speaker = false;
      }
    });
  }

  @override
  void onNewMessage(SIPMessageRequest msg) {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Call Controls Demo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Transport: $_transport    |    Register: $_registration'),
          const SizedBox(height: 8),
          _sectionTitle('SIP Connection'),
          _rowField('WSS URL', _wssCtrl, hint: 'wss://host:port'),
          _rowField('Domain', _domainCtrl, hint: 'example.com'),
          _rowField('Port', _portCtrl, keyboardType: TextInputType.number),
          _rowField('Username', _userCtrl),
          _rowField('Password', _passCtrl, obscureText: true),
          _rowField('Display Name', _displayCtrl),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.link),
                label: const Text('Register'),
                onPressed: _register,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.link_off),
                label: const Text('Unregister'),
                onPressed: _unregister,
              ),
            ),
          ]),
          const Divider(height: 32),
          _sectionTitle('Call'),
          _rowField('Destination', _destCtrl, hint: '1001'),
          Wrap(spacing: 12, runSpacing: 12, children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.call),
              label: const Text('Call'),
              onPressed: _makeCall,
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.call_end),
              label: const Text('Hangup'),
              onPressed: _hangup,
            ),
            if (_incoming)
              FilledButton.icon(
                icon: const Icon(Icons.phone_in_talk),
                label: const Text('Answer'),
                onPressed: _answer,
              ),
          ]),
          const SizedBox(height: 12),
          Text('Call State: $_callState'),
          const Divider(height: 32),
          _sectionTitle('In-Call Controls'),
          Wrap(spacing: 12, runSpacing: 12, children: [
            ElevatedButton(
              onPressed: _toggleMute,
              child: Text(_muted ? 'Unmute' : 'Mute'),
            ),
            ElevatedButton(
              onPressed: _toggleHold,
              child: Text(_held ? 'Unhold' : 'Hold'),
            ),
            ElevatedButton(
              onPressed: _toggleSpeaker,
              child: Text(_speaker ? 'Speaker Off' : 'Speaker On'),
            ),
          ]),
          const SizedBox(height: 8),
          _sectionTitle('DTMF'),
          _dtmfPad(),
          const SizedBox(height: 8),
          _sectionTitle('Send INFO'),
          _rowField('Body', _infoBodyCtrl, hint: 'app/example'),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              onPressed: _sendInfo,
              child: const Text('Send INFO'),
            ),
          ),
          const SizedBox(height: 8),
          _sectionTitle('Transfer (REFER)'),
          _rowField('Target', _referCtrl, hint: 'sip:1002@domain:5060 or 1002'),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              onPressed: _refer,
              child: const Text('Refer'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dtmfPad() {
    final tones = ['1','2','3','4','5','6','7','8','9','*','0','#'];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: tones
          .map((t) => ElevatedButton(
                onPressed: () => _sendDTMF(t),
                child: Text(t, style: const TextStyle(fontSize: 18)),
              ))
          .toList(),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      );

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
