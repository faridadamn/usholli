import 'package:flutter/material.dart';

class TitipDoaSheet extends StatelessWidget {
  const TitipDoaSheet({super.key, required this.auth});
  final dynamic auth;

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text("Titip Doa")),
    );
  }
}