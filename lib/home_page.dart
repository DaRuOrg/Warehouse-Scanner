import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _scannedBarcode = 'Unbekannt';
  final List<XFile> _capturedImages = [];

  final ImagePicker _picker = ImagePicker();

  // Funktion, um den Barcode zu scannen
  Future<void> scanBarcode() async {
    try {
      String barcode = await FlutterBarcodeScanner.scanBarcode(
          "#ff6666", "Abbrechen", true, ScanMode.BARCODE);

      if (barcode != "-1") {
        setState(() {
          _scannedBarcode = barcode;
        });
      } else {
        setState(() {
          _scannedBarcode = "Fehler beim Scannen!";
        });
      }
    } catch (e) {
      setState(() {
        _scannedBarcode = "Ein Fehler ist aufgetreten!";
      });
    }
  }

  // Funktion, um ein Bild aufzunehmen
  Future<void> captureImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      // Generiere einen benutzerdefinierten Dateinamen mit Barcode und Index
      String fileName =
          "${_scannedBarcode.replaceAll('/', '_')}_${_capturedImages.length + 1}.jpg";

      // Hole das temporäre Verzeichnis
      final Directory tempDir = await getTemporaryDirectory();
      final String newPath = path.join(tempDir.path, fileName);

      // Speichere das aufgenommene Bild im neuen Pfad
      await File(image.path).copy(newPath);

      setState(() {
        _capturedImages.add(XFile(newPath)); // Füge das neue XFile zur Liste hinzu
      });

      // Optional: Speichere das Bild in der Galerie
      await GallerySaver.saveImage(newPath, albumName: 'BarcodeImages');
      print("Bild gespeichert als: $fileName");
    }
  }

  // Funktion, um alle Bilder mit Index und Barcode zu speichern
  Future<void> saveImagesWithBarcode() async {
    if (_capturedImages.isEmpty || _scannedBarcode == 'Unbekannt') {
      return; // Fahre nicht fort, wenn keine Bilder vorhanden sind oder kein Barcode gescannt wurde
    }

    try {
      // Schleife durch die aufgenommenen Bilder und speichere sie
      for (int i = 0; i < _capturedImages.length; i++) {
        String fileName =
            "${_scannedBarcode.replaceAll('/', '_')}_${i + 1}.jpg"; // Format: <scannedBarcode>_<index>.jpg

        // Drucke oder verarbeite den Dateinamen nach Bedarf
        print("Bild gespeichert als: $fileName");
      }

      // Zeige eine Erfolgsnachricht
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Bilder erfolgreich gespeichert!"),
      ));

      // Lösche die aufgenommenen Bilder und setze den Barcode zurück
      setState(() {
        _capturedImages.clear();
        _scannedBarcode = 'Unbekannt'; // Setze den Barcode zurück
      });
    } catch (e) {
      print("Fehler beim Speichern der Bilder: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Fehler beim Speichern der Bilder!"),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Barcode Scanner & Bildaufnahme'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Gescanntes Barcode: $_scannedBarcode',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            Expanded(
              child: _capturedImages.isNotEmpty
                  ? GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                      ),
                      itemCount: _capturedImages.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.file(
                            File(_capturedImages[index].path),
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    )
                  : Text('Keine Bilder aufgenommen'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: scanBarcode,
              child: Text('Barcode scannen'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _scannedBarcode != 'Unbekannt' ? captureImage : null,
              child: Text('Bild aufnehmen'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed:
                  (_capturedImages.isNotEmpty && _scannedBarcode != 'Unbekannt')
                      ? saveImagesWithBarcode
                      : null,
              child: Text('Bilder speichern'),
            ),
          ],
        ),
      ),
    );
  }
}
