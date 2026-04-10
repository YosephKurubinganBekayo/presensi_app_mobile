import 'package:flutter/material.dart';
import 'package:presensi_app/models/user.dart';

class WaliKelasPage extends StatelessWidget {
  const WaliKelasPage({super.key, required UserModel user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Halaman Wali Kelas")),
      body: Column(
        children: [
          DropdownButtonFormField(
            items: const [
              DropdownMenuItem(value: "X-A", child: Text("Kelas X-A")),
              DropdownMenuItem(value: "X-B", child: Text("Kelas X-B")),
            ],
            onChanged: (value) {},
            decoration: const InputDecoration(labelText: "Pilih Kelas"),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: 10,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text("Nama Siswa $index"),
                  subtitle: const Text("Hadir: 10 | Izin: 1 | Alpha: 0"),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}