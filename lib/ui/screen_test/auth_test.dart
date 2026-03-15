import 'package:flutter/material.dart';

void main(List<String> args) {
  runApp(const AuthTest());
}

class AuthTest extends StatefulWidget {
  const AuthTest({super.key});

  @override
  State<AuthTest> createState() => _AuthTestState();
}

class _AuthTestState extends State<AuthTest> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {'/': (context) => const Home()},
      home: Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () async {},
            child: const Text('Auth'),
          ),
        ),
      ),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(onPressed: () async {}, child: const Text('Auth')),
    );
  }
}
