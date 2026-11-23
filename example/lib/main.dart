import 'dart:async';

import 'package:flutter/material.dart';

import 'reveal.dart';
import 'sensitive_screen.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal, brightness: Brightness.dark),
      home: const CardPage(),
    );
  }
}

class CardPage extends StatefulWidget {
  const CardPage({super.key});

  @override
  State<CardPage> createState() => _CardPageState();
}

class _CardPageState extends State<CardPage> {
  // A test number, never a real one, even in a demo.
  static const _number = '4000 0012 3456 4821';
  static const _pin = '2580';

  final _security = SensitiveScreen();
  late final StreamSubscription<void> _shots;
  bool _shield = true;
  bool _cover = true;

  @override
  void initState() {
    super.initState();
    _shots = _security.screenshots.listen((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Screenshot taken. Card details stay hidden.')),
      );
    });
    // The iOS shield attaches to the window, so wait until it exists.
    WidgetsBinding.instance.addPostFrameCallback((_) => _setShield(true));
  }

  @override
  void dispose() {
    _shots.cancel();
    _security.dispose();
    super.dispose();
  }

  Future<void> _setShield(bool on) async {
    final ok = await _security.setShield(on);
    if (mounted && ok) setState(() => _shield = on);
  }

  Future<void> _setCover(bool on) async {
    final ok = await _security.setCover(on);
    if (mounted && ok) setState(() => _cover = on);
  }

  Future<bool> _unlock() async {
    final res = await _security.authenticate('Show your card details');
    if (res == AuthResult.unavailable && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Set up Face ID, a fingerprint or a passcode first.')),
      );
    }
    return res == AuthResult.granted;
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Sensitive screen')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SecureReveal(
            unlock: _unlock,
            builder: (context, revealed, secondsLeft) => Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Card number', style: text.labelLarge),
                    const SizedBox(height: 8),
                    Text(
                      revealed ? _number : '•••• •••• •••• ${_number.substring(15)}',
                      textDirection: TextDirection.ltr,
                      style: text.headlineSmall?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                    ),
                    const SizedBox(height: 8),
                    Text(revealed ? 'Hides in ${secondsLeft}s. Tap to hide now.' : 'Tap to unlock'),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          HoldToReveal(
            builder: (context, held) => Card(
              child: ListTile(
                leading: Icon(held ? Icons.visibility : Icons.fingerprint),
                title: Text(held ? _pin : '••••', textDirection: TextDirection.ltr),
                subtitle: Text(held ? 'Let go to hide' : 'Hold to see your PIN'),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            value: _shield,
            onChanged: _setShield,
            title: const Text('Screenshot shield'),
            subtitle: const Text('Screenshots and recordings come out black'),
          ),
          SwitchListTile(
            value: _cover,
            onChanged: _setCover,
            title: const Text('Hide in app switcher'),
            subtitle: const Text('Blurs the app when you leave it'),
          ),
        ],
      ),
    );
  }
}
