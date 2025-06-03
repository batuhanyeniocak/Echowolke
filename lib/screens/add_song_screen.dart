import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddSongScreen extends StatefulWidget {
  const AddSongScreen({Key? key}) : super(key: key);

  @override
  State<AddSongScreen> createState() => _AddSongScreenState();
}

class _AddSongScreenState extends State<AddSongScreen> {
  final _formKey = GlobalKey<FormState>();

  final artistController = TextEditingController();
  final audioUrlController = TextEditingController();
  final coverUrlController = TextEditingController();
  final durationController = TextEditingController();
  final playCountController = TextEditingController();
  final titleController = TextEditingController();

  Future<void> addSongToFirestore() async {
    if (_formKey.currentState!.validate()) {
      final tracks = FirebaseFirestore.instance.collection('tracks');

      try {
        final newDoc = tracks.doc(); // otomatik ID
        final newId = newDoc.id;

        Map<String, dynamic> songData = {
          "artist": artistController.text,
          "audioUrl": audioUrlController.text,
          "coverUrl": coverUrlController.text,
          "duration": int.parse(durationController.text),
          "id": newId, // verinin içine de yaz
          "playCount": int.parse(playCountController.text),
          "title": titleController.text,
          "releaseDate": Timestamp.now(),
        };

        await newDoc.set(songData);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Şarkı başarıyla eklendi")),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata oluştu: $e")),
        );
      }
    }
  }

  @override
  void dispose() {
    artistController.dispose();
    audioUrlController.dispose();
    coverUrlController.dispose();
    durationController.dispose();
    playCountController.dispose();
    titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Şarkı Ekle")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: artistController,
                decoration: const InputDecoration(labelText: 'Sanatçı'),
                validator: (value) => value!.isEmpty ? 'Gerekli alan' : null,
              ),
              TextFormField(
                controller: audioUrlController,
                decoration: const InputDecoration(labelText: 'Audio URL'),
                validator: (value) => value!.isEmpty ? 'Gerekli alan' : null,
              ),
              TextFormField(
                controller: coverUrlController,
                decoration: const InputDecoration(labelText: 'Kapak URL'),
                validator: (value) => value!.isEmpty ? 'Gerekli alan' : null,
              ),
              TextFormField(
                controller: durationController,
                decoration: const InputDecoration(labelText: 'Süre (saniye)'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Gerekli alan' : null,
              ),
              TextFormField(
                controller: playCountController,
                decoration: const InputDecoration(labelText: 'Dinlenme Sayısı'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Gerekli alan' : null,
              ),
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Şarkı Adı'),
                validator: (value) => value!.isEmpty ? 'Gerekli alan' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: addSongToFirestore,
                child: const Text('Kaydet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
