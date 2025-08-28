import 'package:flutter/material.dart';
import 'package:flutter_voip/flutter_voip.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DemoSipApp());
}

class DemoSipApp extends StatelessWidget {
  const DemoSipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutter_voip demo',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: const DemoHomePage(),
    );
  }
}

class DemoHomePage extends StatefulWidget {
  const DemoHomePage({super.key});

  @override
  State<DemoHomePage> createState() => _DemoHomePageState();
}

class _DemoHomePageState extends State<DemoHomePage>
    implements SipUaHelperListener {
  final _ua = VoipUAHelper();

  // Basic inputs
  final _wssCtrl =
      TextEditingController(text: 'wss://your-sbc.example.com:7443');
  final _domainCtrl = TextEditingController(text: 'your.sip.domain');
  final _portCtrl = TextEditingController(text: '5060');
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _displayCtrl = TextEditingController(text: 'Flutter SIP');

  // Dial pad
  final _dialCtrl = TextEditingController();

  // State
  String _transport = 'DISCONNECTED';
  String _registration = 'Unregistered';
  String? _currentCallId;
  String _callState = 'Idle';
  bool _incoming = false;

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
    _dialCtrl.dispose();
    super.dispose();
  }

  void _register() {
    final domain = _domainCtrl.text.trim();
    final port = _portCtrl.text.trim();
    final user = _userCtrl.text.trim();
    final pass = _passCtrl.text;
    final wss = _wssCtrl.text.trim();

    if (domain.isEmpty || port.isEmpty || user.isEmpty || pass.isEmpty || wss.isEmpty) {
      _toast(context, 'Please fill WSS, domain, port, username, password');
      return;
    }

    final settings = PitelSettings();
    settings.webSocketUrl = wss;
    settings.webSocketSettings.allowBadCertificate = true; // demo-friendly
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

  void _unregister() {
    _ua.unregister();
  }

  Future<void> _makeCall() async {
    final dest = _dialCtrl.text.trim();
    final domain = _domainCtrl.text.trim();
    final port = _portCtrl.text.trim();
    if (dest.isEmpty) {
      _toast(context, 'Enter a destination (extension/number)');
      return;
    }
    if (!_ua.connected) {
      _toast(context, 'Not connected/registered');
      return;
    }
    // Use full SIP URI for clarity
    await _ua.call('sip:$dest@$domain:$port', voiceonly: true);
  }

  void _hangup() {
    if (_currentCallId == null) return;
    final call = _ua.findCall(_currentCallId!);
    call?.hangup();
  }

  void _answer() {
    if (_currentCallId == null) return;
    final call = _ua.findCall(_currentCallId!);
    call?.answer(_ua.buildCallOptions(true));
  }

  // SipUaHelperListener
  @override
  void transportStateChanged(PitelTransportState state) {
    setState(() {
      _transport = state.state.toString().split('.').last;
    });
  }

  @override
  void registrationStateChanged(RegistrationState state) {
    setState(() {
      _registration = state.state.toString().split('.').last;
    });
  }

  @override
  void callStateChanged(Call call, PitelCallState state) {
    setState(() {
      _currentCallId = call.id;
      _callState = state.state.toString().split('.').last;
      _incoming = call.direction.toUpperCase() == 'INCOMING';
      if (state.state == PitelCallStateEnum.ENDED ||
          state.state == PitelCallStateEnum.FAILED) {
        _incoming = false;
      }
    });
  }

  @override
  void onNewMessage(SIPMessageRequest msg) {
    // For demo, just log or ignore.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('flutter_voip demo'),
      ),
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
          Row(
            children: [
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
            ],
          ),
          const Divider(height: 32),
          _sectionTitle('Call'),
          _rowField('Destination', _dialCtrl, hint: '1001'),
          const SizedBox(height: 8),
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
          const SizedBox(height: 16),
          Text('Current Call State: $_callState'),
          if (_currentCallId != null)
            Text('Call ID: ${_currentCallId!}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  void _toast(BuildContext context, String msg) {
    final snack = SnackBar(content: Text(msg));
    ScaffoldMessenger.of(context).showSnackBar(snack);
  }
}

