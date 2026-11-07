import 'package:flutter/material.dart';
import 'package:flutter_safe_setstate/flutter_safe_setstate.dart';

class EmptyScreen extends StatefulWidget {
  const EmptyScreen({super.key});

  @override
  State<EmptyScreen> createState() => _EmptyScreenState();
}

class _EmptyScreenState extends State<EmptyScreen> {
  int _count = 0;

  void incrementCount() {
    safeSetState(this, () => _count++);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: incrementCount,
          child: const Icon(Icons.add),
        ),
        body: Center(child: Text(_count.toString())),
      ),
    );
  }
}
