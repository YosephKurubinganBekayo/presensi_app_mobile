import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import 'guru_detail_page.dart';

class GuruTab extends StatefulWidget {
  const GuruTab({super.key});

  @override
  State<GuruTab> createState() => _GuruTabState();
}

class _GuruTabState extends State<GuruTab> {
  List<dynamic> guruList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadGuru();
  }

  Future<void> loadGuru() async {
    setState(() => isLoading = true);
    guruList = await AdminService.getGuru();
    setState(() => isLoading = false);
  }

  void showForm({dynamic guru}) {
    final namaController = TextEditingController(text: guru?["nama"]);
    final mapelController = TextEditingController(text: guru?["mapel"]);
    final emailController = TextEditingController(text: guru?["email"]);
    final nipController = TextEditingController(text: guru?["nip"]);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(guru == null ? "Tambah Guru" : "Edit Guru"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: namaController,
              decoration: const InputDecoration(labelText: "Nama"),
            ),
            TextField(
              controller: nipController,
              decoration: const InputDecoration(labelText: "NIP:"),
            ),
            // TextField(
            //   controller: kelasController,
            //   decoration: const InputDecoration(labelText: "Mapel"),
            // ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (guru == null) {
                await AdminService.tambahGuru(
                  namaController.text,
                  nipController.text,
                  mapelController.text,
                  emailController.text,
                  "defaultpassword", // 🔥 Tambahkan password default
                );
              } else {
                await AdminService.updateGuru(
                  guru["nip"],
                  namaController.text,
                  nipController.text,
                  mapelController.text,
                );
              }

              Navigator.pop(context);
              loadGuru();
            },
            child: const Text("Simpan"),
          ),
        ],
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
      appBar: AppBar(
        title: const Text("Data Guru"),
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.delete_forever),
          //   onPressed: () async {
          //     await AdminService.deleteAllSiswa();
          //     loadSiswa();
          //   },
          // ),
        ],
      ),
      body: ListView.builder(
        itemCount: guruList.length,
        itemBuilder: (context, index) {
          final guru = guruList[index];

          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              title: Text(guru["nama"]),
              subtitle: Text("NIP: ${guru["nip"] ?? "-"}"),
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => GuruDetailPage(guru: guru)),
                );

                if (result == true) {
                  loadGuru();
                }
              },
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => showForm(guru: guru),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      await AdminService.deleteSiswa(guru["id"]);
                      loadGuru();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
