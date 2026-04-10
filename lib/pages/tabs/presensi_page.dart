import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/presensi_service.dart';

class PresensiScreen extends StatefulWidget {
  @override
  _PresensiScreenState createState() => _PresensiScreenState();
}

class _PresensiScreenState extends State<PresensiScreen> {
  File? _image;
  String? _result;
  bool _loading = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _ambilFoto() async {
    final pickedFile =
        await _picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _result = null;
      });

      _kirimPresensi();
    }
  }

  Future<void> _kirimPresensi() async {
    if (_image == null) return;

    setState(() {
      _loading = true;
    });

    final result =
        await PresensiService.kirimPresensi(_image!);

    setState(() {
      _loading = false;
      _result = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Presensi Wajah"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _image != null
                ? Image.file(_image!, height: 250)
                : Container(
                    height: 250,
                    color: Colors.grey[300],
                    child: Center(
                      child: Text("Belum ada foto"),
                    ),
                  ),
            SizedBox(height: 20),

            _loading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _ambilFoto,
                    child: Text("Ambil Foto"),
                  ),

            SizedBox(height: 20),

            if (_result != null)
              Text(
                _result!,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }
}