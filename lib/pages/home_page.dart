import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          // 🔵 HEADER BIRU MELENGKUNG
          Container(
            height: 200,
            decoration: const BoxDecoration(
              color: Color(0xFF1565C0),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 🏫 HEADER SEKOLAH
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.school, color: Color(0xFF1565C0)),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Sekolah Menengah Pertama",
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Negeri 1 Kupang Tengah",
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 👤 CARD PROFIL
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 4,
                    child: ListTile(
                      leading: const CircleAvatar(
                        radius: 28,
                        backgroundImage: AssetImage("assets/profile.jpg"),
                      ),
                      title: const Text(
                        "Ahmad Fauzi, S.Pd",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        "NIP: 198912282010031001\nWali Kelas X IPA 1",
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Expanded(
                    child: ListView(
                      children: [
                        // 📘 KELAS SAYA
                        Text(
                          "Kelas Saya",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),

                        _kelasCard(),

                        const SizedBox(height: 20),

                        // 📅 JADWAL HARI INI
                        Text(
                          "Jadwal Mengajar Hari Ini",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),

                        _jadwalCard(
                          "Matematika",
                          "Kelas VII A | 07.30 - 08.45",
                        ),
                        _jadwalCard(
                          "Matematika",
                          "Kelas VII B | 09.00 - 10.15",
                        ),
                        _jadwalCard("Matematika", "Kelas IX A | 10.30 - 11.45"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kelasCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.blue.shade200],
          ),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "X IPA 1",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4),
            Text(
              "Untuk Rekapan Kehadiran",
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _jadwalCard(String mapel, String detail) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        leading: Container(
          width: 6,
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        title: Text(mapel, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(detail),
      ),
    );
  }
}
