import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import 'siswa_detail_page.dart';

class SiswaTab extends StatefulWidget {
  const SiswaTab({super.key});

  @override
  State<SiswaTab> createState() => _SiswaTabState();
}

class _SiswaTabState extends State<SiswaTab> {
  List<dynamic> kelasList = [];
  int? selectedKelasId;
  List<dynamic> siswaList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    initLoad();
  }

  Future<void> initLoad() async {
    setState(() => isLoading = true);
    kelasList = await AdminService.getKelas(); // ✅ hanya sekali
    siswaList = await AdminService.getSiswa();
    setState(() => isLoading = false);
  }

  Future<void> _confirmDeleteAll() async {
    final confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Konfirmasi"),
        content: const Text(
          "Semua data siswa akan dihapus.\nTindakan ini tidak bisa dibatalkan.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Hapus"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AdminService.deleteAllSiswa();
      // await loadSiswa();

      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Semua data siswa berhasil dihapus")),
      );
    }
  }

  Future<void> loadKelas() async {
    kelasList = await AdminService.getKelas();
  }

  Future<void> loadSiswa() async {
    setState(() => isLoading = true);
    siswaList = await AdminService.getSiswa();
    setState(() => isLoading = false);
  }

  void showForm({dynamic siswa, int? siswaIndex}) async {
    // await loadKelas();

    selectedKelasId = siswa?["kelas_id"];
    final namaController = TextEditingController(text: siswa?["nama"]);
    final nisController = TextEditingController(text: siswa?["nis"]);
    final kelasController = TextEditingController(text: siswa?["kelas"]);

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== TITLE =====
                Row(
                  children: [
                    Icon(
                      siswa == null ? Icons.person_add : Icons.edit,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      siswa == null ? "Tambah Siswa" : "Edit Siswa",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ===== NAMA =====
                TextField(
                  controller: namaController,
                  decoration: InputDecoration(
                    labelText: "Nama Lengkap",
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ===== NIS =====
                TextField(
                  controller: nisController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "NIS",
                    prefixIcon: const Icon(Icons.badge),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ===== KELAS =====
                DropdownButtonFormField<int>(
                  value: selectedKelasId,
                  decoration: InputDecoration(
                    labelText: "Kelas",
                    prefixIcon: const Icon(Icons.class_),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  items: kelasList.map((kelas) {
                    return DropdownMenuItem<int>(
                      value: kelas["id"],
                      child: Text(kelas["nama"]),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedKelasId = value;
                    });
                  },
                ),
                const SizedBox(height: 28),

                // ===== BUTTONS =====
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Batal"),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: () async {
                        if (namaController.text.isEmpty ||
                            nisController.text.isEmpty ||
                            selectedKelasId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Semua field wajib diisi"),
                            ),
                          );
                          return;
                        }

                        final messenger = ScaffoldMessenger.of(context);

                        try {
                          if (siswa == null) {
                            await AdminService.tambahSiswa(
                              namaController.text.trim(),
                              nisController.text.trim(),
                              selectedKelasId!,
                            );
                          } else {
                            await AdminService.updateSiswa(
                              siswa["id"],
                              namaController.text.trim(),
                              nisController.text.trim(),
                              selectedKelasId!,
                            );
                          }

                          if (!mounted) return;

                          Navigator.pop(context); // ✅ Tutup dialog dulu

                          messenger.clearSnackBars();
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                siswa == null
                                    ? "Siswa berhasil ditambahkan"
                                    : "Siswa berhasil diperbarui",
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );

                          await loadSiswa(); // ✅ Reload setelah dialog hilang
                        } catch (e) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text("Gagal: ${e.toString()}"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: const Text("Simpan"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => showForm(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // ===== HEADER SECTION =====
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              border: Border(
                bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ICON
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.school, color: Colors.blue),
                ),

                const SizedBox(width: 12),

                // TITLE + COUNT
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Data Siswa",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${siswaList.length} siswa terdaftar",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                // DELETE BUTTON
                IconButton(
                  tooltip: "Hapus Semua",
                  onPressed: siswaList.isEmpty ? null : _confirmDeleteAll,
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                ),
              ],
            ),
          ),

          // ===== LIST SECTION =====
          Expanded(
            child: RefreshIndicator(
              onRefresh: loadSiswa,
              child: siswaList.isEmpty
                  ? const Center(
                      child: Text(
                        "Belum ada data siswa",
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: siswaList.length,
                      itemBuilder: (context, index) {
                        final siswa = siswaList[index];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              child: Text(
                                siswa["nama"][0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              siswa["nama"],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                "NIS: ${siswa["nis"]}\nKelas: ${siswa["kelas"]}",
                              ),
                            ),
                            isThreeLine: true,
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SiswaDetailPage(siswa: siswa),
                                ),
                              );

                              if (result == true) {
                                loadSiswa();
                              }
                            },
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) async {
                                if (value == "edit") {
                                  showForm(siswa: siswa);
                                } else if (value == "delete") {
                                  final confirm = await showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text("Konfirmasi"),
                                      content: const Text(
                                        "Yakin ingin menghapus siswa ini?",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text("Batal"),
                                        ),
                                        FilledButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text("Hapus"),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    await AdminService.deleteSiswa(siswa["id"]);
                                    loadSiswa();
                                  }
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: "edit",
                                  child: Text("Edit"),
                                ),
                                PopupMenuItem(
                                  value: "delete",
                                  child: Text("Hapus"),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
