import 'package:flutter/material.dart';

class BannedAccountPage extends StatelessWidget {
  final String reason;
  const BannedAccountPage({super.key, required this.reason});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Banned Account'),
      ),
      body: Center(
        child: Text(
            'Your account has been banned for the following reason: $reason'),
      ),
    );
  }
}
