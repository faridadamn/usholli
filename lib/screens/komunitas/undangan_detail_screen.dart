import 'package:flutter/material.dart';

class UndanganDetailScreen extends StatelessWidget {
  final dynamic undangan;
  final dynamic auth;

  const UndanganDetailScreen({
    super.key,
    required this.undangan,
    required this.auth,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail Undangan"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Judul
            Text(
              undangan?.judul ?? "Judul tidak ada",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            // Waktu
            Text(
              "Waktu: ${undangan?.waktuStr ?? '-'}",
              style: const TextStyle(fontSize: 14),
            ),

            const SizedBox(height: 6),

            // Alamat
            Text(
              "Tempat: ${undangan?.alamat ?? '-'}",
              style: const TextStyle(fontSize: 14),
            ),

            const SizedBox(height: 6),

            // Pembuat
            Text(
              "Dibuat oleh: ${undangan?.pembuatNama ?? '-'}",
              style: const TextStyle(fontSize: 14),
            ),

            const SizedBox(height: 20),

            // Deskripsi
            if (undangan?.deskripsi != null)
              Text(
                undangan.deskripsi,
                style: const TextStyle(fontSize: 14),
              ),

            const Spacer(),

            // Tombol hadir (dummy)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Kamu memilih hadir")),
                  );
                },
                child: const Text("Saya Hadir"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}