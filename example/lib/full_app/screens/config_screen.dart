import 'package:flutter/material.dart';
import 'package:flutter_voip/flutter_voip.dart';

class ConfigScreen extends StatefulWidget {
  final SipInfoData initialSip;
  final PushNotifParams initialPush;
  final Future<void> Function(SipInfoData sip, PushNotifParams push) onSave;
  final Future<void> Function() onRegister;

  const ConfigScreen({
    super.key,
    required this.initialSip,
    required this.initialPush,
    required this.onSave,
    required this.onRegister,
  });

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  late final TextEditingController _wssCtrl;
  late final TextEditingController _regSrvCtrl;
  late final TextEditingController _outSrvCtrl;
  late final TextEditingController _portCtrl;
  late final TextEditingController _userCtrl;
  late final TextEditingController _authCtrl;
  late final TextEditingController _displayCtrl;
  late final TextEditingController _bundleCtrl;
  late final TextEditingController _teamCtrl;

  @override
  void initState() {
    super.initState();
    final s = widget.initialSip;
    final p = widget.initialPush;
    _wssCtrl = TextEditingController(text: s.wssUrl);
    _regSrvCtrl = TextEditingController(text: s.registerServer);
    _outSrvCtrl = TextEditingController(text: s.outboundServer);
    _portCtrl = TextEditingController(text: (s.port ?? 5060).toString());
    _userCtrl = TextEditingController(text: s.accountName);
    _authCtrl = TextEditingController(text: s.authPass);
    _displayCtrl = TextEditingController(text: s.displayName);
    _bundleCtrl = TextEditingController(text: p.bundleId);
    _teamCtrl = TextEditingController(text: p.teamId);
  }

  @override
  void dispose() {
    _wssCtrl.dispose();
    _regSrvCtrl.dispose();
    _outSrvCtrl.dispose();
    _portCtrl.dispose();
    _userCtrl.dispose();
    _authCtrl.dispose();
    _displayCtrl.dispose();
    _bundleCtrl.dispose();
    _teamCtrl.dispose();
    super.dispose();
  }

  SipInfoData _buildSip() {
    return SipInfoData(
      wssUrl: _wssCtrl.text.trim(),
      registerServer: _regSrvCtrl.text.trim(),
      outboundServer: _outSrvCtrl.text.trim(),
      port: int.tryParse(_portCtrl.text.trim()),
      accountName: _userCtrl.text.trim(),
      authPass: _authCtrl.text,
      displayName: _displayCtrl.text.trim(),
      userAgent: 'Flutter VoIP Example',
    );
  }

  PushNotifParams _buildPush() {
    return PushNotifParams(teamId: _teamCtrl.text.trim(), bundleId: _bundleCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('SIP Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _field('WSS URL', _wssCtrl, hint: 'wss://sbc.example.com:7443'),
        _field('Register Server', _regSrvCtrl, hint: 'sip.example.com'),
        _field('Outbound Proxy (optional)', _outSrvCtrl, hint: 'sbc.example.com'),
        _field('Port', _portCtrl, keyboardType: TextInputType.number, hint: '5060'),
        _field('SIP Username', _userCtrl),
        _field('SIP Password', _authCtrl, obscureText: true),
        _field('Display Name', _displayCtrl),
        const Divider(height: 24),
        const Text('Push Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _field('Bundle ID', _bundleCtrl, hint: 'com.example.flutterVoipExample'),
        _field('Team ID (iOS only)', _teamCtrl, hint: 'ABCDE12345'),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Save'),
              onPressed: () => widget.onSave(_buildSip(), _buildPush()),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              icon: const Icon(Icons.link),
              label: const Text('Register Now'),
              onPressed: () async {
                await widget.onSave(_buildSip(), _buildPush());
                await widget.onRegister();
              },
            ),
          ),
        ])
      ],
    );
  }

  Widget _field(String label, TextEditingController c, {String? hint, TextInputType? keyboardType, bool obscureText = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 6),
          TextField(
            controller: c,
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
}

