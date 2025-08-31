import 'dart:io';

import 'package:clipboard/clipboard.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_voip/flutter_voip.dart';
import 'package:flutter_voip/voip_push/android_connection_service.dart';

class PushDebugScreen extends StatefulWidget {
  final String bundleId;
  final Future<void> Function(String fcmToken) registerWithManualToken;

  const PushDebugScreen({
    super.key,
    required this.bundleId,
    required this.registerWithManualToken,
  });

  @override
  State<PushDebugScreen> createState() => _PushDebugScreenState();
}

class _PushDebugScreenState extends State<PushDebugScreen> {
  // Use an example FCM token by default (no Firebase call).
  final _fcmCtrl = TextEditingController(
    text:
        'example-fcm-token-aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
  );

  bool _firebaseInitAttempted = false;
  String _status = 'Idle';

  @override
  void dispose() {
    _fcmCtrl.dispose();
    super.dispose();
  }

  Future<void> _copyToken() async {
    await FlutterClipboard.copy(_fcmCtrl.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Token copied')));
  }

  Future<void> _registerManual() async {
    setState(() => _status = 'Registering with manual token...');
    await widget.registerWithManualToken(_fcmCtrl.text.trim());
    if (!mounted) return;
    setState(() => _status = 'Registered (manual)');
  }

  Future<void> _initFirebaseOptional() async {
    // Optional: developers can enable this if google-services are configured.
    try {
      await PushNotifAndroid.initFirebase();
      if (!mounted) return;
      setState(() {
        _firebaseInitAttempted = true;
        _status = 'Firebase initialized (optional)';
      });
    } catch (e) {
      if (kDebugMode) {
        print('Firebase init skipped/failed: ' + e.toString());
      }
      if (!mounted) return;
      setState(() {
        _firebaseInitAttempted = true;
        _status = 'Firebase not available (skipped)';
      });
    }
  }

  Future<void> _simulateIncoming() async {
    // Show incoming call UI without FCM; useful for background/locked testing.
    AndroidConnectionService.showCallkitIncoming(
      CallkitParamsModel(
        uuid: DateTime.now().millisecondsSinceEpoch.toString(),
        nameCaller: 'Demo Caller',
        avatar: '',
        phoneNumber: '+12025550123',
        appName: 'Flutter VoIP Example',
        backgroundColor: '#0955fa',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Push & Background',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _kv('Platform', Platform.isAndroid ? 'Android' : (Platform.isIOS ? 'iOS' : 'Other')),
        _kv('Bundle ID', widget.bundleId),
        const SizedBox(height: 12),
        const Text(
          'Manual FCM Token (no Firebase init)',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _fcmCtrl,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
            hintText: 'Enter example FCM token',
          ),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 12, runSpacing: 12, children: [
          ElevatedButton.icon(
            onPressed: _registerManual,
            icon: const Icon(Icons.link),
            label: const Text('Register (Manual Token)'),
          ),
          OutlinedButton.icon(
            onPressed: _copyToken,
            icon: const Icon(Icons.copy),
            label: const Text('Copy Token'),
          ),
        ]),
        const Divider(height: 32),
        const Text('Optional Firebase init (for real FCM)',
            style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _initFirebaseOptional,
              icon: const Icon(Icons.notifications_active_outlined),
              label: const Text('Init Firebase (optional)'),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        _statusBox(_status),
        const Divider(height: 32),
        const Text('Simulate Incoming Call',
            style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _simulateIncoming,
          icon: const Icon(Icons.ring_volume),
          label: const Text('Show CallKit Incoming'),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tip: Put the app in background/lock screen to test full-screen incoming.',
          style: TextStyle(color: Colors.black54),
        ),
      ],
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            SizedBox(width: 110, child: Text(k, style: const TextStyle(color: Colors.black54))),
            Expanded(child: Text(v, maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
        ),
      );

  Widget _statusBox(String text) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blueGrey.shade50,
          border: Border.all(color: Colors.blueGrey.shade100),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text),
      );
}