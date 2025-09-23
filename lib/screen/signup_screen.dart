
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'home_map.dart';

class SignupScreen extends StatefulWidget {
  static const routeName = '/signup';
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  String? _error;

  void _signup() async {
    if (_password.text != _confirm.text) {
      setState(() { _error = "Passwords don't match"; });
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await Provider.of<AuthProvider>(context, listen: false).signup(_email.text.trim(), _password.text);
      Navigator.of(context).pushReplacementNamed(HomeMapScreen.routeName);
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BinSpot — Sign up')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _email, decoration: InputDecoration(labelText: 'Email')),
            SizedBox(height: 8),
            TextField(controller: _password, decoration: InputDecoration(labelText: 'Password'), obscureText: true),
            SizedBox(height: 8),
            TextField(controller: _confirm, decoration: InputDecoration(labelText: 'Confirm Password'), obscureText: true),
            SizedBox(height: 16),
            if (_error != null) Text(_error!, style: TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: _loading ? null : _signup,
              child: _loading ? CircularProgressIndicator() : Text('Sign up'),
            ),
          ],
        ),
      ),
    );
  }
}
