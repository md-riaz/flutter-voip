import 'package:flutter/material.dart';
import 'package:flutter_voip/flutter_voip.dart';
import 'package:flutter_voip/component/voip_ua_helper.dart';

class MessagingDemo extends StatefulWidget {
  const MessagingDemo({super.key});

  @override
  State<MessagingDemo> createState() => _MessagingDemoState();
}

class _MessagingDemoState extends State<MessagingDemo>
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

  // Message inputs
  final _toCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController(text: 'Hello from flutter_voip');

  final _log = <String>[];

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
    _toCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  void _register() {
    final domain = _domainCtrl.text.trim();
    final port = _portCtrl.text.trim();
    final user = _userCtrl.text.trim();
    final pass = _passCtrl.text;
    final wss = _wssCtrl.text.trim();
    if (domain.isEmpty ||
        port.isEmpty ||
        user.isEmpty ||
        pass.isEmpty ||
        wss.isEmpty) {
      _toast('Please fill all connection fields');
      return;
    }
    final settings = VoipSettings();
    settings.webSocketUrl = wss;
    settings.webSocketSettings.allowBadCertificate = true;
    settings.uri = 'sip:$user@$domain:$port';
    settings.authorizationUser = user;
    settings.password = pass;
    settings.displayName =
        _displayCtrl.text.trim().isEmpty ? user : _displayCtrl.text.trim();
    settings.userAgent = 'Flutter VoIP Example';
    settings.sipDomain = '$domain:$port';
    _ua.start(settings);
  }

  void _unregister() => _ua.unregister();

  void _sendMessage() {
    final to = _toCtrl.text.trim();
    final domain = _domainCtrl.text.trim();
    final port = _portCtrl.text.trim();
    if (to.isEmpty) return _toast('Enter destination user');
    final target = to.contains('sip:') ? to : 'sip:$to@$domain:$port';
    _ua.sendMessage(target, _bodyCtrl.text, {'contentType': 'text/plain'});
    setState(() {
      _log.insert(0, 'Sent MESSAGE to $target: ${_bodyCtrl.text}');
    });
  }

  // Listener
  @override
  void onNewMessage(SIPMessageRequest msg) {
    final from = msg.message?.remote_identity?.uri?.user ?? 'unknown';
    final body = msg.request?.body ?? '';
    setState(() {
      _log.insert(0, 'Incoming from $from: $body');
    });
  }

  @override
  void transportStateChanged(VoipTransportState state) {
    setState(() => _transport = state.state.toString().split('.').last);
  }

  @override
  void registrationStateChanged(RegistrationState state) {
    setState(() => _registration = state.state.toString().split('.').last);
  }

  @override
  void callStateChanged(Call call, VoipCallState state) {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messaging (SIP MESSAGE)')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Transport: $_transport    |    Register: $_registration'),
                const SizedBox(height: 8),
                _sectionTitle('SIP Connection'),
                _rowField('WSS URL', _wssCtrl, hint: 'wss://host:port'),
                _rowField('Domain', _domainCtrl, hint: 'example.com'),
                _rowField('Port', _portCtrl,
                    keyboardType: TextInputType.number),
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
                _sectionTitle('Send MESSAGE'),
                _rowField('To (user or sip:uri)', _toCtrl, hint: '1002'),
                _rowField('Body', _bodyCtrl),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton(
                    onPressed: _sendMessage,
                    child: const Text('Send'),
                  ),
                ),
                const Divider(height: 32),
                _sectionTitle('Log'),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              reverse: true,
              itemCount: _log.length,
              itemBuilder: (_, i) => Text(_log[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      );

  Widget _rowField(String label, TextEditingController controller,
      {String? hint, TextInputType? keyboardType, bool obscureText = false}) {
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
