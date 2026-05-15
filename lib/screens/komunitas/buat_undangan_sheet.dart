import 'package:flutter/material.dart';

class BuatUndanganSheet extends StatelessWidget {
  const BuatUndanganSheet({super.key, required this.auth});

  final dynamic auth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Buat Undangan"),
      ),
      body: const Center(
        child: Text("Form Buat Undangan"),
      ),
    );
  }
}