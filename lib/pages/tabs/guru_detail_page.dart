import 'package:flutter/material.dart';
import 'package:presensi_app/services/auth_service.dart';
import '../../services/admin_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dio/dio.dart';

class GuruDetailPage extends StatefulWidget {
  final Map guru;

  const GuruDetailPage({super.key, required this.guru});
  @override
  State<GuruDetailPage> createState() => _GuruDetailPageState();
}

class _GuruDetailPageState extends State<GuruDetailPage> {
  List<Map<String, dynamic>> faceImages = [];
  bool hasEmbedding = false;
  double uploadProgress = 0.0;
  bool isUploading = false;

  @override
  Widget build(BuildContext context) {
    final initial = widget.guru["nama"].toString().isNotEmpty
        ? widget.guru["nama"][0].toUpperCase()
        : "?";

    return Scaffold(
      appBar: AppBar(title: const Text("Detail Guru")),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ================= HEADER =================
                    Center(
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.1),
                        child: Text(
                          initial,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Center(
                      child: Text(
                        widget.guru["nama"],
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                    Center(child: Text(widget.guru["nip"] ?? "NIP : -")),

                    const SizedBox(height: 20),
                    detailRow("Email", widget.guru["email"] ?? "-"),
                    const SizedBox(height: 20),
                    detailRow("Guru Mapel", widget.guru["mapel"] ?? "-"),
                    const SizedBox(height: 20),
                    detailRow("No HP", widget.guru["no_hp"] ?? "-"),
                    const SizedBox(height: 20),
                    detailRow(
                      "Jenis Kelamin",
                      widget.guru["jenis_kelamin"] ?? "-",
                    ),
                    const SizedBox(height: 20),
                    detailRow("Alamat", widget.guru["alamat"] ?? "-"),
                    const SizedBox(height: 12),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),

          // ================= LOADING =================
          if (isUploading)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(child: CircularProgressIndicator()),
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
