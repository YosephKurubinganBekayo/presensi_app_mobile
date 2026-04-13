import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'auth_service.dart';

class PresensiService {
  static const String baseUrl = "http://192.168.1.23:8000";

  // =========================================================
  // 🔥 YOLO MODEL
  // =========================================================
  static late Interpreter yolo;
  static bool _isModelLoaded = false;

  static Future<void> initYolo() async {
    if (_isModelLoaded) return;

    yolo = await Interpreter.fromAsset('lib/assets/yolofacedetect.tflite');
    _isModelLoaded = true;
  }

  // =========================================================
  // 🖼 DEBUG HELPER
  // =========================================================
  static Future<void> saveDebugImage(img.Image image, String name) async {
    final dir = Directory('/storage/emulated/0/Download/debug_faces');

    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final file = File('${dir.path}/$name.jpg');
    file.writeAsBytesSync(img.encodeJpg(image));

    print("DEBUG IMAGE SAVED: ${file.path}");
  }

  static img.Image drawBoxes(
    img.Image image,
    List<Map<String, dynamic>> boxes,
  ) {
    for (var box in boxes) {
      img.drawRect(
        image,
        x1: box['x'].toInt(),
        y1: box['y'].toInt(),
        x2: (box['x'] + box['w']).toInt(),
        y2: (box['y'] + box['h']).toInt(),
        color: img.ColorRgb8(255, 0, 0),
        thickness: 3,
      );
    }
    return image;
  }

  static late Interpreter facenet;

  static Future<void> initFaceNet() async {
    facenet = await Interpreter.fromAsset('lib/assets/mobilefacenet.tflite');
  }

  // =========================================================
  // ✅ PRESENSI (SINGLE)
  // =========================================================
  static Future<String> kirimPresensi(File image) async {
    try {
      await initYolo();

      final faces = await detectFacesLocal(image.path);

      if (faces.isEmpty) {
        return "❌ Tidak ada wajah";
      }

      return "✅ Wajah terdeteksi (${faces.length})";
    } catch (e) {
      return "❌ Error: $e";
    }
  }

  // =========================================================
  // 📊 LIST PRESENSI (API)
  // =========================================================
  static Future<List<dynamic>> getPresensi({
    int? kelasId,
    int? mapelId,
    int? guruId,
    String? tanggal,
  }) async {
    String url = "/api/admin/presensi?";

    if (kelasId != null) url += "kelas_id=$kelasId&";
    if (mapelId != null) url += "mapel_id=$mapelId&";
    if (guruId != null) url += "guru_id=$guruId&";
    if (tanggal != null) url += "tanggal=$tanggal";

    final response = await AuthService.getWithAuth(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Gagal ambil data presensi");
    }
  }

  // =========================================================
  // 🗑 DELETE PRESENSI (API)
  // =========================================================
  static Future<void> deletePresensi(int id) async {
    final token = await AuthService.getToken();

    final response = await http.delete(
      Uri.parse("${AuthService.baseUrl}/api/admin/presensi/$id"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Gagal hapus presensi");
    }
  }

  // =========================================================
  // 📈 STATISTIK (API)
  // =========================================================
  static Future<Map<String, dynamic>> getStatistikPresensi({
    int? kelasId,
    String? tanggal,
  }) async {
    String url = "/api/admin/presensi/statistik?";

    if (kelasId != null) url += "kelas_id=$kelasId&";
    if (tanggal != null) url += "tanggal=$tanggal";

    final response = await AuthService.getWithAuth(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Gagal ambil statistik");
    }
  }

  // =========================================================
  // 🤖 YOLO DETECT
  // =========================================================
  static Future<List<Map<String, dynamic>>> detectFacesLocal(
    String imagePath,
  ) async {
    final image = img.decodeImage(File(imagePath).readAsBytesSync())!;

    final resized = img.copyResize(image, width: 640, height: 640);

    final input = [
      List.generate(640, (y) {
        return List.generate(640, (x) {
          final pixel = resized.getPixel(x, y);

          return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
        });
      }),
    ];

    var output = List.generate(
      1,
      (_) => List.generate(5, (_) => List.filled(8400, 0.0)),
    );

    yolo.run(input, output);

    final results = _processYolo(output[0], image.width, image.height);

    // 🔥 DEBUG: bounding box
    final debugImage = drawBoxes(image.clone(), results);
    await saveDebugImage(debugImage, "2_detected");

    // 🔥 DEBUG INPUT
    await saveDebugImage(resized, "1_resized");
    return results;
  }

  // =========================================================
  // 🧠 MULTI FACE RECOGNITION
  // =========================================================
  static Future<List<Map<String, dynamic>>> getDatabaseWajah() async {
    final response = await AuthService.getWithAuth(
      "/api/admin/siswa/embeddings",
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception("Gagal ambil database wajah");
    }
  }

  static Future<Map<String, dynamic>> recognizePresensi({
    required String imagePath,
  }) async {
    try {
      await initYolo();
      await initFaceNet();
      final image = img.decodeImage(File(imagePath).readAsBytesSync());

      if (image == null) {
        throw Exception("Gagal membaca gambar");
      }

      final faces = await detectFacesLocal(imagePath);

      int totalFaces = faces.length;
      int recognized = 0;
      List<int> siswaIds = [];
      final database = await getDatabaseWajah();
      print("TOTAL DATABASE: ${database.length}");
      int faceIndex = 0;

      for (var face in faces) {
        final cropped = img.copyCrop(
          image,
          x: face['x'].toInt(),
          y: face['y'].toInt(),
          width: face['w'].toInt(),
          height: face['h'].toInt(),
        );

        // 🔥 DEBUG FACE
        await saveDebugImage(cropped, "face_$faceIndex");
        faceIndex++;

        final embedding = getEmbedding(cropped);

        print("EMBEDDING FACE (first 5): ${embedding.take(5).toList()}");
        print(
          "DB EMBEDDING (first 5): ${database[0]['embedding'].take(5).toList()}",
        );

        double bestScore = 0;
        int? bestId;

        for (var siswa in database) {
          double sim = cosineSimilarity(embedding, siswa["embedding"]);
          print("COMPARE ID ${siswa["id"]} => $sim");

          if (sim > bestScore) {
            bestScore = sim;
            bestId = siswa["id"];
          }
        }

        if (bestScore > 0.7 && bestId != null) {
          recognized++;
          siswaIds.add(bestId);
        }
      }

      // 🔥 SAVE KE API
      final response = await AuthService.postWithAuth(
        "/api/admin/presensi/local",
        {"siswa_ids": siswaIds, "status": "Hadir"},
      );

      if (response.statusCode != 200) {
        throw Exception("Gagal kirim ke server");
      }

      return {"total_faces": totalFaces, "recognized_count": recognized};
    } catch (e) {
      throw Exception("Error: $e");
    }
  }

  // =========================================================
  // 🧮 EMBEDDING (SEMENTARA)
  // =========================================================
  static List<double> getEmbedding(img.Image face) {
    final resized = img.copyResize(face, width: 112, height: 112);

    var input = List.generate(
      1,
      (_) => List.generate(
        112,
        (y) => List.generate(112, (x) {
          final pixel = resized.getPixel(x, y);
          return [
            (pixel.r - 128) / 128,
            (pixel.g - 128) / 128,
            (pixel.b - 128) / 128,
          ];
        }),
      ),
    );

    var output = List.generate(1, (_) => List.filled(192, 0.0));

    facenet.run(input, output);

    return List<double>.from(output[0]);
  }

  // =========================================================
  // 📏 SIMILARITY
  // =========================================================
  static double cosineSimilarity(List<double> a, List<dynamic> b) {
    List<double> v2 = b.map((e) => (e as num).toDouble()).toList();

    double dot = 0, normA = 0, normB = 0;

    for (int i = 0; i < a.length && i < v2.length; i++) {
      dot += a[i] * v2[i];
      normA += a[i] * a[i];
      normB += v2[i] * v2[i];
    }

    if (normA == 0 || normB == 0) return 0;

    return dot / (sqrt(normA) * sqrt(normB));
  }

  // =========================================================
  // 🔍 YOLO POST PROCESS
  // =========================================================
  static List<Map<String, dynamic>> applySoftNMS(
    List<Map<String, dynamic>> boxes, {
    double iouThreshold = 0.7,
    double sigma = 0.5,
    double scoreThreshold = 0.3,
  }) {
    List<Map<String, dynamic>> result = [];

    while (boxes.isNotEmpty) {
      // 🔥 Ambil box dengan confidence tertinggi
      boxes.sort((a, b) => b['conf'].compareTo(a['conf']));
      var best = boxes.removeAt(0);

      result.add(best);

      List<Map<String, dynamic>> updatedBoxes = [];

      for (var box in boxes) {
        double iou = calculateIoU(best, box);

        if (iou > iouThreshold) {
          // 🔥 Soft decay (Gaussian)
          box['conf'] = box['conf'] * exp(-(iou * iou) / sigma);
        }

        if (box['conf'] > scoreThreshold) {
          updatedBoxes.add(box);
        }
      }

      boxes = updatedBoxes;
    }

    return result;
  }

  static double calculateIoU(a, b) {
    double x1 = max(a['x'], b['x']);
    double y1 = max(a['y'], b['y']);
    double x2 = min(a['x'] + a['w'], b['x'] + b['w']);
    double y2 = min(a['y'] + a['h'], b['y'] + b['h']);

    double interArea = max(0, x2 - x1) * max(0, y2 - y1);

    double areaA = a['w'] * a['h'];
    double areaB = b['w'] * b['h'];

    return interArea / (areaA + areaB - interArea + 1e-6);
  }

  static List<Map<String, dynamic>> _processYolo(
    List detections,
    int w,
    int h,
  ) {
    List<Map<String, dynamic>> results = [];

    for (int i = 0; i < detections[0].length; i++) {
      double conf = detections[4][i];

      if (conf > 0.3) {
        // 🔥 turunkan threshold (biar Soft-NMS kerja)
        double x = detections[0][i];
        double y = detections[1][i];
        double wBox = detections[2][i];
        double hBox = detections[3][i];

        // 🔥 filter noise kecil
        if (wBox * hBox < 0.02) continue;

        results.add({
          "x": (x - wBox / 2) * w,
          "y": (y - hBox / 2) * h,
          "w": wBox * w,
          "h": hBox * h,
          "conf": conf, // 🔥 WAJIB untuk Soft-NMS
        });
      }
    }

    // 🔥 APPLY SOFT-NMS DI SINI
    return applySoftNMS(
      results,
      iouThreshold: 0.3,
      sigma: 0.5,
      scoreThreshold: 0.4,
    );
  }

  // upload wajah ke server
  static Future<void> registerFaceToServer({
    required String imagePath,
    required int siswaId,
  }) async {
    await initYolo();
    await initFaceNet();

    final image = img.decodeImage(File(imagePath).readAsBytesSync());

    if (image == null) throw Exception("Gagal baca gambar");

    final faces = await detectFacesLocal(imagePath);

    if (faces.isEmpty) throw Exception("Tidak ada wajah");

    final face = faces.first;

    // 🔥 VALIDASI & CLAMP (ANTI ERROR)
    double x = face['x'];
    double y = face['y'];
    double w = face['w'];
    double h = face['h'];

    if (w < 10 || h < 10) {
      throw Exception("Wajah terlalu kecil");
    }

    x = max(0, x);
    y = max(0, y);
    w = min(w, image.width - x);
    h = min(h, image.height - y);

    final cropped = img.copyCrop(
      image,
      x: x.toInt(),
      y: y.toInt(),
      width: w.toInt(),
      height: h.toInt(),
    );

    // 🔥 DEBUG (biar bisa dicek hasil crop)
    await saveDebugImage(cropped, "register_face");

    final embedding = getEmbedding(cropped);

    print("EMBEDDING (first 5): ${embedding.take(5).toList()}");

    // 🔥 KIRIM KE SERVER
    final response = await AuthService.postWithAuth("/api/ai/save-embedding", {
      "siswa_id": siswaId,
      "embedding": embedding,
    });

    if (response.statusCode != 200) {
      throw Exception("Gagal simpan embedding");
    }
  }
}
