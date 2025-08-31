import 'package:flutter/material.dart';
import 'package:flutter_voip/flutter_voip.dart';

class DialerScreen extends StatefulWidget {
  final Future<void> Function(String destination) onCall;
  final String regState;
  final VoipCallStateEnum callState;

  const DialerScreen({
    super.key,
    required this.onCall,
    required this.regState,
    required this.callState,
  });

  @override
  State<DialerScreen> createState() => _DialerScreenState();
}

class _DialerScreenState extends State<DialerScreen> {
  final _destCtrl = TextEditingController();

  @override
  void dispose() {
    _destCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Register: ${widget.regState}    |    Call: ${widget.callState.name}'),
          const SizedBox(height: 12),
          TextField(
            controller: _destCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Destination (extension/number)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.call),
              label: const Text('Call'),
              onPressed: () async {
                final dest = _destCtrl.text.trim();
                if (dest.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Enter destination')),
                  );
                  return;
                }
                await widget.onCall(dest);
              },
            ),
          ),
        ],
      ),
    );
  }
}

