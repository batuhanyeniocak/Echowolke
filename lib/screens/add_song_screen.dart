import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_app/services/firebase_service.dart';
import '../models/track.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

class AddSongScreen extends StatefulWidget {
  const AddSongScreen({Key? key}) : super(key: key);

  @override
  State<AddSongScreen> createState() => _AddSongScreenState();
}

class _AddSongScreenState extends State<AddSongScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseService _firebaseService = FirebaseService();

  final titleController = TextEditingController();
  final artistController = TextEditingController();
  final durationController = TextEditingController();

  File? selectedMp3File;
  File? selectedCoverImage;
  Uint8List? selectedMp3Bytes;
  Uint8List? selectedCoverBytes;
  String? mp3FileName;
  String? coverFileName;

  bool isUploading = false;
  double uploadProgress = 0.0;

  Future<void> pickMp3File() async {
    final AudioPlayer player = AudioPlayer();
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
        withData: kIsWeb,
        withReadStream: !kIsWeb,
      );

      if (result != null) {
        String fileName = result.files.single.name;
        titleController.text = fileName.replaceAll('.mp3', '');
        mp3FileName = fileName;

        final tempMediaItem = MediaItem(
          id: fileName,
          title: fileName.replaceAll('.mp3', ''),
          artist: 'Bilinmiyor',
        );

        AudioSource audioSource;

        if (kIsWeb) {
          selectedMp3Bytes = result.files.single.bytes;
          setState(() {});

          if (selectedMp3Bytes != null && selectedMp3Bytes!.isNotEmpty) {
            audioSource = AudioSource.uri(
              Uri.dataFromBytes(selectedMp3Bytes!, mimeType: 'audio/mpeg'),
              tag: tempMediaItem,
            );
          } else {
            durationController.text = '0';
            return;
          }
        } else {
          if (result.files.single.path != null) {
            selectedMp3File = File(result.files.single.path!);
            setState(() {});

            if (await selectedMp3File!.exists()) {
              audioSource = AudioSource.file(
                selectedMp3File!.path,
                tag: tempMediaItem,
              );
            } else {
              durationController.text = '0';
              return;
            }
          } else {
            durationController.text = '0';
            return;
          }
        }

        await player.setAudioSource(audioSource);
        await player.load();

        await player.processingStateStream
            .firstWhere((state) => state == ProcessingState.ready);

        if (player.duration != null) {
          durationController.text = player.duration!.inSeconds.toString();
        } else {
          durationController.text = '0';
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Dosya seçme veya süre alma hatası: $e")),
      );
      durationController.text = '0';
    } finally {
      await player.dispose();
      if (mounted) setState(() {});
    }
  }

  Future<void> pickCoverImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: kIsWeb,
        withReadStream: !kIsWeb,
      );

      if (result != null) {
        coverFileName = result.files.single.name;
        if (kIsWeb) {
          setState(() {
            selectedCoverBytes = result.files.single.bytes;
          });
        } else {
          if (result.files.single.path != null) {
            setState(() {
              selectedCoverImage = File(result.files.single.path!);
            });
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Resim seçme hatası: $e")),
      );
    }
  }

  bool get hasSelectedMp3 {
    return kIsWeb ? selectedMp3Bytes != null : selectedMp3File != null;
  }

  bool get hasSelectedCover {
    return kIsWeb ? selectedCoverBytes != null : selectedCoverImage != null;
  }

  String get selectedMp3DisplayName {
    if (kIsWeb) {
      return mp3FileName ?? 'Bilinmeyen dosya';
    } else {
      return selectedMp3File?.path.split('/').last ?? '';
    }
  }

  Future<void> uploadTrack() async {
    if (!_formKey.currentState!.validate() ||
        !hasSelectedMp3 ||
        durationController.text == '0') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                "Lütfen tüm alanları doldurun ve MP3 dosyası seçin. Şarkı süresi alınamadı.")),
      );
      return;
    }

    setState(() {
      isUploading = true;
      uploadProgress = 0.0;
    });

    try {
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String audioFileName = '${timestamp}_${titleController.text}.mp3';
      String coverImageName = '${timestamp}_${titleController.text}_cover.jpg';

      String audioUrl;
      audioUrl = await _firebaseService.uploadMp3File(
        kIsWeb ? selectedMp3Bytes! : selectedMp3File!,
        audioFileName,
      );

      String coverUrl = '';
      if (hasSelectedCover) {
        coverUrl = await _firebaseService.uploadCoverImage(
          kIsWeb ? selectedCoverBytes! : selectedCoverImage!,
          coverImageName,
        );
      } else {
        coverUrl = 'https://via.placeholder.com/300x300?text=No+Cover';
      }

      final newTrack = Track(
        id: timestamp,
        title: titleController.text,
        artist: artistController.text,
        audioUrl: audioUrl,
        coverUrl: coverUrl,
        duration: int.tryParse(durationController.text) ?? 0,
        playCount: 0,
        releaseDate: DateTime.now(),
      );

      await _firebaseService.saveTrackToFirestore(newTrack);

      setState(() {
        isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Şarkı başarıyla yüklendi!")),
      );

      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Yükleme hatası: $e")),
      );
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    artistController.dispose();
    durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Şarkı Yükle"),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(Icons.audiotrack,
                          size: 48, color: Colors.orange),
                      const SizedBox(height: 8),
                      Text(
                        hasSelectedMp3
                            ? 'Seçilen dosya: ${selectedMp3DisplayName}'
                            : 'MP3 dosyası seçin',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: hasSelectedMp3 ? Colors.green : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: isUploading ? null : pickMp3File,
                        icon: const Icon(Icons.file_upload),
                        label: const Text('MP3 Seç'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      hasSelectedCover
                          ? kIsWeb
                              ? Image.memory(
                                  selectedCoverBytes!,
                                  height: 100,
                                  width: 100,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  selectedCoverImage!,
                                  height: 100,
                                  width: 100,
                                  fit: BoxFit.cover,
                                )
                          : const Icon(Icons.image,
                              size: 48, color: Colors.orange),
                      const SizedBox(height: 8),
                      Text(
                        hasSelectedCover
                            ? 'Kapak resmi seçildi'
                            : 'Kapak resmi seçin (opsiyonel)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: hasSelectedCover ? Colors.green : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: isUploading ? null : pickCoverImage,
                        icon: const Icon(Icons.image),
                        label: const Text('Kapak Seç'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Şarkı Adı',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.music_note),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Şarkı adı gerekli' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: artistController,
                decoration: const InputDecoration(
                  labelText: 'Sanatçı',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Sanatçı adı gerekli' : null,
              ),
              const SizedBox(height: 24),
              if (isUploading) ...[
                const Text(
                  'Yükleniyor...',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  backgroundColor: Colors.grey[300],
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
                const SizedBox(height: 16),
              ],
              ElevatedButton(
                onPressed: isUploading ? null : uploadTrack,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: isUploading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Yükleniyor...'),
                        ],
                      )
                    : const Text('Şarkıyı Yükle'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
