import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/admin_service.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/presensi_service.dart';

class PresensiTab extends StatefulWidget {
  const PresensiTab({super.key});

  @override
  State<PresensiTab> createState() => _PresensiTabState();
}

class _PresensiTabState extends State<PresensiTab> {
  List<dynamic> presensiList = [];
  Map<String, dynamic>? statistik;

  List<dynamic> kelasList = [];

  int? selectedKelas;
  String? selectedTanggal;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadInitial();
  }

  Future<void> loadInitial() async {
    await loadKelas();
    await loadData();
  }

  Future<void> loadKelas() async {
    kelasList = await AdminService.getKelas();
  }

  Future<void> loadData() async {
    setState(() => loading = true);

    presensiList = await PresensiService.getPresensi(
      kelasId: selectedKelas,
      tanggal: selectedTanggal,
    );

    statistik = await PresensiService.getStatistikPresensi(
      kelasId: selectedKelas,
      tanggal: selectedTanggal,
    );

    setState(() => loading = false);
  }

  Future<void> mulaiPresensiMulti() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile == null) return;

    setState(() => loading = true);

    try {
      final result = await PresensiService.recognizePresensi(
        imagePath: pickedFile.path,
        // kelasId: selectedKelas!,
      );

      int total = result["total_faces"];
      int recognized = result["recognized_count"];

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$recognized dari $total wajah berhasil dikenali"),
        ),
      );

      await loadData();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }

    setState(() => loading = false);
  }

  Future<void> pickTanggal() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        selectedTanggal = DateFormat("yyyy-MM-dd").format(picked);
      });

      loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // ================= FILTER =================
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: DropdownButton<int>(
                  isExpanded: true,
                  hint: const Text("Filter Kelas"),
                  value: selectedKelas,
                  items: kelasList
                      .map(
                        (k) => DropdownMenuItem<int>(
                          value: k["id"],
                          child: Text(k["nama"]),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    setState(() => selectedKelas = val);
                    loadData();
                  },
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: pickTanggal,
                child: const Text("Pilih Tanggal"),
              ),
            ],
          ),
        ),

        // ================= STATISTIK =================
        if (statistik != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                buildStatCard("Hadir", statistik!["hadir"], Colors.green),
                buildStatCard("Izin", statistik!["izin"], Colors.orange),
                buildStatCard("Alfa", statistik!["alfa"], Colors.red),
              ],
            ),
          ),

        const SizedBox(height: 10),

        // ================= LIST =================
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: presensiList.length,
            itemBuilder: (context, index) {
              final item = presensiList[index];
              bool hadir = item["status"] == "Hadir";

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F3F7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item["nama"] ?? "-",
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${item["kelas"] ?? "-"} • ${item["mapel"] ?? "-"}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // STATUS BADGE
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: hadir
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        item["status"] ?? "",
                        style: TextStyle(
                          color: hadir ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // ICON KECIL
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: hadir ? Colors.blue : Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // ================= TOMBOL BESAR =================
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              onPressed: mulaiPresensiMulti, // 🔥 GANTI DI SINI
              icon: const Icon(Icons.camera_alt),
              label: const Text(
                "Mulai Presensi Kelas",
                style: TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildStatCard(String title, int value, Color color) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.15),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
              const SizedBox(height: 5),
              Text(
                value.toString(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color getStatusColor(String? status) {
    switch (status) {
      case "Hadir":
        return Colors.green;
      case "Izin":
        return Colors.orange;
      case "Alfa":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String formatTanggal(String? tanggal) {
    if (tanggal == null) return "-";
    DateTime dt = DateTime.parse(tanggal);
    return DateFormat("dd MMM yyyy HH:mm").format(dt);
  }

  void confirmDelete(int id) async {
    await PresensiService.deletePresensi(id);
    loadData();
  }
}
