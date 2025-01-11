// Zum Kodieren von Barcode-Daten in JSON
import 'dart:io'; // Für Dateioperationen
import 'package:flutter/material.dart'; // Flutter UI-Bibliothek
import 'package:image_picker/image_picker.dart'; // Für Bildaufnahme
import 'package:path_provider/path_provider.dart'; // Für Zugriff auf Speicherverzeichnisse
import 'package:gallery_saver/gallery_saver.dart'; // Zum Speichern von Bildern in der Galerie
import 'package:shared_preferences/shared_preferences.dart'; // Zum Speichern von Barcode-Daten und Bildpfaden

class ResultPage extends StatefulWidget {
  const ResultPage({super.key, required this.barcodeResults});

  // Ändere den Typ von List<BarcodeResult> zu List<String>
  final List<String> barcodeResults;

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  final List<File> _imageFiles = []; // Liste zur Speicherung aufgenommener Bilddateien

  Future<void> _captureImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);

    if (photo != null) {
      File savedImage =
          await _saveImageToGallery(File(photo.path), _imageFiles.length);
      setState(() {
        _imageFiles.add(savedImage); // Füge das gespeicherte Bild zur Liste hinzu
      });
    }
  }

  Future<File> _saveImageToGallery(File image, int index) async {
    final List<Directory>? externalDirs =
        await getExternalStorageDirectories(type: StorageDirectory.pictures);

    if (externalDirs == null || externalDirs.isEmpty) {
      throw Exception('Externe Speicherverzeichnisse nicht verfügbar');
    }

    final Directory ccScanDir = Directory('${externalDirs[0].path}/CCScan');
    if (!await ccScanDir.exists()) {
      await ccScanDir.create(recursive: true);
    }

    String fileName =
        '${widget.barcodeResults.length}_$index${DateTime.now().millisecondsSinceEpoch}.png';
    final String newPath = '${ccScanDir.path}/$fileName';
    final File newImage = await image.copy(newPath);
    await GallerySaver.saveImage(newPath);

    return newImage; // Gib die neue Bilddatei zurück
  }

  void _saveData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList(
        'barcode_data', widget.barcodeResults); // Speichere Barcode-Daten

    List<String> imagePaths = _imageFiles.map((file) => file.path).toList();
    prefs.setStringList('image_paths', imagePaths); // Speichere Bildpfade
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ergebnisse'),
      ),
      body: Column(
        children: [
          Text('Gesamtanzahl Barcodes: ${widget.barcodeResults.length}'),
          Expanded(
            child: ListView.builder(
              itemCount: widget.barcodeResults.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text('Barcode: ${widget.barcodeResults[index]}'),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: _captureImage,
            child: Text('Bild aufnehmen'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _imageFiles.length,
              itemBuilder: (context, index) {
                return Image.file(_imageFiles[index], height: 100);
              },
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _saveData(); // Speichere Barcode-Daten und aufgenommene Bilder
              Navigator.pop(context); // Zurück zum vorherigen Bildschirm
            },
            child: Text('Speichern und Fortfahren'),
          ),
        ],
      ),
    );
  }
}
