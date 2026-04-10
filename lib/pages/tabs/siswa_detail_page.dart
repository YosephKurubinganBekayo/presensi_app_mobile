import 'package:flutter/material.dart';
import 'package:presensi_app/services/auth_service.dart';
import '../../services/admin_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dio/dio.dart';

class SiswaDetailPage extends StatefulWidget {
  final Map siswa;

  const SiswaDetailPage({super.key, required this.siswa});
  @override
  State<SiswaDetailPage> createState() => _SiswaDetailPageState();
}

class _SiswaDetailPageState extends State<SiswaDetailPage> {
  List<Map<String, dynamic>> faceImages = [];
  bool hasEmbedding = false;
  double uploadProgress = 0.0;
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    hasEmbedding = widget.siswa["embedding"] != null;
    loadFaces();
  }

  Future<void> loadFaces() async {
    try {
      final response = await Dio().get(
        "${AuthService.baseUrl}/api/ai/faces/${widget.siswa["id"]}",
      );
      if (!mounted) return;
      setState(() {
        faceImages = List<Map<String, dynamic>>.from(response.data);
      });
    } catch (e) {
      print("Load faces error: $e");
    }
  }

  Future<void> deleteFace(int faceId) async {
    try {
      final token = await AuthService.getToken();

      await Dio().delete(
        "${AuthService.baseUrl}/api/ai/faces/$faceId",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      // 🔥 HAPUS LANGSUNG DARI LIST LOKAL
      setState(() {
        faceImages.removeWhere((face) => face["id"] == faceId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Foto berhasil dihapus"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal hapus: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> pickAndUploadImage(
    BuildContext context,
    ImageSource source,
  ) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 85);

    if (pickedFile == null) return;

    final token = await AuthService.getToken();

    setState(() {
      isUploading = true;
      uploadProgress = 0;
    });

    try {
      Dio dio = Dio();

      final bytes = await pickedFile.readAsBytes();

      FormData formData = FormData.fromMap({
        "file": MultipartFile.fromBytes(bytes, filename: "face.jpg"),
      });

      Response response = await dio.post(
        "${AuthService.baseUrl}/api/ai/upload/${widget.siswa["id"]}",
        data: formData,
        options: Options(
          headers: {"Authorization": "Bearer $token"},
          validateStatus: (status) => true, // 🔥 penting
        ),
        onSendProgress: (sent, total) {
          setState(() {
            uploadProgress = sent / total;
          });
        },
      );

      // 🔥 Delay kecil supaya progress terlihat 100%
      await Future.delayed(const Duration(milliseconds: 300));

      setState(() {
        isUploading = false;
        uploadProgress = 0;
      });

      if (response.statusCode == 200) {
        setState(() {
          hasEmbedding = true;
        });

        await loadFaces();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Embedding berhasil disimpan"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal: ${response.data}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        isUploading = false;
        uploadProgress = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Upload error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.siswa["nama"].toString().isNotEmpty
        ? widget.siswa["nama"][0].toUpperCase()
        : "?";

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Detail Siswa",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ================= HEADER =================
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary.withOpacity(0.08),
                        Colors.white,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.15),
                        child: Text(
                          initial,
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.siswa["nama"],
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "NIS: ${widget.siswa["nis"] ?? "-"}",
                              style: const TextStyle(
                                color: Color.fromARGB(255, 42, 42, 42),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: hasEmbedding
                              ? Colors.green.withOpacity(0.15)
                              : Colors.orange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          hasEmbedding ? "Aktif" : "Belum Aktif",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: hasEmbedding ? Colors.green : Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ================= CARD DETAIL =================
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Informasi Siswa",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 18),

                      detailRow("Kelas", widget.siswa["kelas"] ?? "-"),
                      const SizedBox(height: 14),
                      detailRow(
                        "Status Embedding",
                        hasEmbedding ? "Sudah Terdaftar" : "Belum Terdaftar",
                        color: hasEmbedding ? Colors.green : Colors.orange,
                      ),

                      const SizedBox(height: 24),

                      // BUTTON
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: () => pickAndUploadImage(
                                context,
                                ImageSource.camera,
                              ),
                              icon: const Icon(Icons.camera_alt),
                              label: const Text("Kamera"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: () => pickAndUploadImage(
                                context,
                                ImageSource.gallery,
                              ),
                              icon: const Icon(Icons.upload),
                              label: const Text("Upload"),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // FOTO TITLE
                      const Text(
                        "Foto Wajah Terdaftar",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),

                      faceImages.isEmpty
                          ? Container(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              alignment: Alignment.center,
                              child: const Text(
                                "Belum ada foto",
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : SizedBox(
                              height: 120,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: faceImages.length,
                                itemBuilder: (context, index) {
                                  final imageUrl =
                                      "${AuthService.baseUrl}${faceImages[index]["image_url"]}";
                                  final faceId = faceImages[index]["id"];

                                  return Padding(
                                    padding: const EdgeInsets.only(right: 14),
                                    child: Stack(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.1,
                                                ),
                                                blurRadius: 8,
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            child: Image.network(
                                              imageUrl,
                                              width: 110,
                                              height: 110,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 6,
                                          right: 6,
                                          child: GestureDetector(
                                            onTap: () => deleteFace(faceId),
                                            child: Container(
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              padding: const EdgeInsets.all(5),
                                              child: const Icon(
                                                Icons.close,
                                                size: 16,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            ),
            // child: Card(
            //   elevation: 6,
            //   shadowColor: Colors.black.withOpacity(0.1),
            //   shape: RoundedRectangleBorder(
            //     borderRadius: BorderRadius.circular(24),
            //   ),

            //   child: Padding(
            //     padding: const EdgeInsets.all(0),

            //   ),
            // ),
          ),

          // ================= LOADING =================
          if (isUploading)
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isUploading ? 1 : 0,
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  Widget detailRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }
}
