import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  bool isLoading = true;

  int totalSiswa = 0;
  int totalGuru = 0;
  int totalPresensiHariIni = 0;
  double persentaseKehadiran = 0;

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    final response =
        await AuthService.getWithAuth("/api/admin/dashboard");

    if (!mounted) return;

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        totalSiswa = data["total_siswa"] ?? 0;
        totalGuru = data["total_guru"] ?? 0;
        totalPresensiHariIni = data["presensi_hari_ini"] ?? 0;
        persentaseKehadiran =
            (data["persentase_kehadiran"] ?? 0).toDouble();
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget statCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        crossAxisCount: MediaQuery.of(context).size.width > 700 ? 2 : 1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 3,
        children: [
          statCard(
            "Total Siswa",
            totalSiswa.toString(),
            Icons.school,
            Colors.blue,
          ),
          statCard(
            "Total Guru",
            totalGuru.toString(),
            Icons.person,
            Colors.green,
          ),
          statCard(
            "Presensi Hari Ini",
            totalPresensiHariIni.toString(),
            Icons.fact_check,
            Colors.orange,
          ),
          statCard(
            "Persentase Kehadiran",
            "${persentaseKehadiran.toStringAsFixed(1)} %",
            Icons.bar_chart,
            Colors.purple,
          ),
        ],
      ),
    );
  }
}