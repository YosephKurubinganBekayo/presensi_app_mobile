import 'package:presensi_app/services/auth_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:presensi_app/pages/tabs/guru_detail_page.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class AdminService {
  // kelas
  static Future<List<dynamic>> getKelas() async {
    final response = await AuthService.getWithAuth("/api/admin/kelas");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Gagal ambil data kelas");
    }
  }

  // guru
  static Future<List<dynamic>> getGuru() async {
    final response = await AuthService.getWithAuth("/api/admin/guru");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Gagal ambil data guru");
    }
  }

  static Future<void> tambahGuru(
    String nama,
    String email,
    String mapel,
    String nip, // 🔥 Tambahkan NIP
    String password,
  ) async {
    final response = await AuthService.postWithAuth("/api/admin/guru", {
      "nama": nama,
      "email": email,
      "mapel": mapel,
      "nip": nip, // 🔥 Tambahkan NI P
      "password": password, // 🔥 Tambahkan password
    });
  }

  // ================= UPDATE =================
  static Future<void> updateGuru(
    int id,
    String nama,
    String email,
    String mapel,
  ) async {
    await AuthService.postWithAuth("/api/admin/guru/$id", {
      "nama": nama,
      "email": email,
      "mapel": mapel,
    });
  }

  // siswa
  // ================= LIST =================
  static Future<List<dynamic>> getSiswa() async {
    final response = await AuthService.getWithAuth("/api/admin/siswa");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Gagal ambil data siswa");
    }
  }

  // ================= TAMBAH =================
  static Future<void> tambahSiswa(String nama, String nis, int kelasId) async {
    final response = await AuthService.postWithAuth("/api/admin/siswa", {
      "nama": nama,
      "nis": nis,
      "kelas_id": kelasId,
    });

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data["detail"]);
    }
  }

  // ================= UPDATE =================
  static Future<void> updateSiswa(
    int id,
    String nama,
    String nis,
    int kelasId,
  ) async {
    final response = await AuthService.putWithAuth("/api/admin/siswa/$id", {
      "nama": nama,
      "nis": nis,
      "kelas_id": kelasId is int
          ? kelasId
          : int.parse(kelasId.toString()), // 🔥 FIX PASTI
    });

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception("Gagal update siswa");
    }
  }

  // ================= DELETE =================
  static Future<void> deleteAllSiswa() async {
    final token = await AuthService.getToken();

    await http.delete(
      Uri.parse("${AuthService.baseUrl}/api/admin/siswa/delete-all"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );
  }

  static Future<void> deleteSiswa(int id) async {
    final token = await AuthService.getToken();

    final response = await http.delete(
      Uri.parse("${AuthService.baseUrl}/api/admin/siswa/$id"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Gagal hapus siswa");
    }
  }
}
