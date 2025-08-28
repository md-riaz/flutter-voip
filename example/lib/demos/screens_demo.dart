import 'package:flutter/material.dart';
import 'package:flutter_voip/flutter_voip.dart';

class ScreensDemo extends StatefulWidget {
  const ScreensDemo({super.key});
  @override
  State<ScreensDemo> createState() => _ScreensDemoState();
}

class _ScreensDemoState extends State<ScreensDemo>
    implements SipHelperListener {
  final VoipCall _call = VoipClient.getInstance().pitelCall;

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
  VoipCallStateEnum _callState = VoipCallStateEnum.NONE;

  @override
  void initState() {
    super.initState();
    _call.addListener(this);
  }

  @override
  void dispose() {
    _call.removeListener(this);
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

  Future<void> _callWithUi() async {
    final dest = _destCtrl.text.trim();
    final domain = _domainCtrl.text.trim();
    final port = _portCtrl.text.trim();
    if (dest.isEmpty) return _toast('Enter destination');
    // Place call
    await _call.call('sip:$dest@$domain:$port', true);
    if (!mounted) return;
    // Show prebuilt screen
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _CallScreenRoute(
        getState: () => _callState,
        onState: (s) => setState(() => _callState = s),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prebuilt Screens Demo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Register: $_regState    |    Call: ${_callState.name}'),
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
          _sectionTitle('Use CallScreen UI'),
          _rowField('Destination', _destCtrl, hint: '1001'),
          ElevatedButton(
            onPressed: _callWithUi,
            child: const Text('Call with CallScreen'),
          ),
          const SizedBox(height: 24),
          const Text(
            'Tip: For full push/CallKit integration, wrap your app with VoipApp,\n'
            'and use VoipCallWidget to handle incoming/outgoing flows.',
          ),
        ],
      ),
    );
  }

  // Listener (SDK-level)
  @override
  void callStateChanged(String callId, VoipCallState state) {
    setState(() => _callState = state.state);
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

class _CallScreenRoute extends StatefulWidget {
  final VoipCallStateEnum Function() getState;
  final void Function(VoipCallStateEnum) onState;
  const _CallScreenRoute({required this.getState, required this.onState});
  @override
  State<_CallScreenRoute> createState() => _CallScreenRouteState();
}

class _CallScreenRouteState extends State<_CallScreenRoute> {
  @override
  Widget build(BuildContext context) {
    return CallScreen(
      bgColor: Colors.black,
      callState: widget.getState(),
      onCallState: widget.onState,
      showHoldCall: true,
      txtMute: 'Mute',
      txtUnMute: 'Unmute',
      txtSpeaker: 'Speaker',
      txtOutgoing: 'Outgoing',
      txtIncoming: 'Incoming',
      txtHoldCall: 'Hold',
      txtUnHoldCall: 'Unhold',
      txtTimer: 'Duration',
      txtWaiting: '00:00',
    );
  }
}

