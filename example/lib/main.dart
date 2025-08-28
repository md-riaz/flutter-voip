import 'package:flutter/material.dart';

import 'demos/basic_sip_demo.dart';
import 'demos/call_controls_demo.dart';
import 'demos/messaging_demo.dart';
import 'demos/video_demo.dart';
import 'demos/screens_demo.dart';

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
      home: const DemoMenuPage(),
    );
  }
}

class DemoMenuPage extends StatelessWidget {
  const DemoMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tiles = <_DemoTile>[
      _DemoTile('Basic SIP (register/call)', const BasicSipDemo()),
      _DemoTile('Call Controls (DTMF, hold, mute, speaker, refer)',
          const CallControlsDemo()),
      _DemoTile('Messaging (SIP MESSAGE)', const MessagingDemo()),
      _DemoTile('Video Call (local/remote views)', const VideoDemo()),
      _DemoTile('Prebuilt Screens + SDK wiring', const ScreensDemo()),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('flutter_voip examples')),
      body: ListView.separated(
        itemCount: tiles.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final t = tiles[index];
          return ListTile(
            title: Text(t.title),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => t.page)),
          );
        },
      ),
    );
  }
}

class _DemoTile {
  final String title;
  final Widget page;
  _DemoTile(this.title, this.page);
}
