import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_app/services/firebase_service.dart';
import '../models/track.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

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

  static Future<int> _calculateDurationInBackground(
      Map<String, dynamic> data) async {
    final AudioPlayer player = AudioPlayer();
    try {
      AudioSource audioSource;
      final bool isWeb = data['isWeb'];

      if (isWeb) {
        final Uint8List bytes = data['bytes'];
        audioSource = AudioSource.uri(
          Uri.dataFromBytes(bytes, mimeType: 'audio/mpeg'),
          tag: MediaItem(id: 'temp', title: 'temp'),
        );
      } else {
        final String path = data['path'];
        audioSource = AudioSource.file(
          path,
          tag: MediaItem(id: 'temp', title: 'temp'),
        );
      }

      await player.setAudioSource(audioSource);
      await player.load();

      await player.processingStateStream
          .firstWhere((state) => state == ProcessingState.ready);

      return player.duration?.inSeconds ?? 0;
    } catch (e) {
      return 0;
    } finally {
      await player.dispose();
    }
  }

  Future<void> pickMp3File() async {
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

        if (kIsWeb) {
          selectedMp3Bytes = result.files.single.bytes;
        } else {
          if (result.files.single.path != null) {
            selectedMp3File = File(result.files.single.path!);
          }
        }
        durationController.text = '';
        if (mounted) setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Dosya seçme hatası: $e"),
              backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
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
        SnackBar(
            content: Text("Resim seçme hatası: $e"),
            backgroundColor: Theme.of(context).colorScheme.error),
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
    if (!_formKey.currentState!.validate() || !hasSelectedMp3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "Lütfen tüm zorunlu alanları doldurun ve MP3 dosyası seçin."),
            backgroundColor: Theme.of(context).colorScheme.error),
      );
      return;
    }

    setState(() {
      isUploading = true;
      uploadProgress = 0.0;
    });

    try {
      int durationInSeconds = 0;
      if (kIsWeb) {
        if (selectedMp3Bytes != null && selectedMp3Bytes!.isNotEmpty) {
          durationInSeconds = await compute(
            _calculateDurationInBackground,
            {'isWeb': true, 'bytes': selectedMp3Bytes!},
          );
        }
      } else {
        if (selectedMp3File != null && await selectedMp3File!.exists()) {
          durationInSeconds = await compute(
            _calculateDurationInBackground,
            {'isWeb': false, 'path': selectedMp3File!.path},
          );
        }
      }

      if (durationInSeconds == 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    "Şarkı süresi alınamadı. Lütfen geçerli bir MP3 dosyası seçin."),
                backgroundColor: Theme.of(context).colorScheme.error),
          );
        }
        return;
      }
      durationController.text = durationInSeconds.toString();

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

      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        setState(() {
          uploadProgress = 1.0;
          isUploading = false;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Şarkı başarıyla yüklendi!"),
            backgroundColor: Theme.of(context).colorScheme.onBackground),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          isUploading = false;
          uploadProgress = 0.0;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Yükleme hatası: $e"),
            backgroundColor: Theme.of(context).colorScheme.error),
      );
    } finally {
      if (mounted) {
        setState(() {
          isUploading = false;
        });
      }
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
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text("Şarkı Yükle",
            style:
                textTheme.titleLarge?.copyWith(color: colorScheme.onSurface)),
        backgroundColor: colorScheme.surface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Card(
                elevation: 4,
                color: colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(Icons.audiotrack,
                          size: 48, color: colorScheme.primary),
                      const SizedBox(height: 8),
                      Text(
                        hasSelectedMp3
                            ? 'Seçilen dosya: ${selectedMp3DisplayName}'
                            : 'MP3 dosyası seçin',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: hasSelectedMp3
                              ? colorScheme.primary
                              : colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: isUploading ? null : pickMp3File,
                        icon: Icon(Icons.file_upload,
                            color: colorScheme.onPrimary),
                        label: Text('MP3 Seç', style: textTheme.labelLarge),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                color: colorScheme.surface,
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
                          : Icon(Icons.image,
                              size: 48, color: colorScheme.primary),
                      const SizedBox(height: 8),
                      Text(
                        hasSelectedCover
                            ? 'Kapak resmi seçildi'
                            : 'Kapak resmi seçin (opsiyonel)',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: hasSelectedCover
                              ? colorScheme.primary
                              : colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: isUploading ? null : pickCoverImage,
                        icon: Icon(Icons.image, color: colorScheme.onPrimary),
                        label: Text('Kapak Seç', style: textTheme.labelLarge),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: titleController,
                style:
                    textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'Şarkı Adı',
                  labelStyle: textTheme.bodyLarge
                      ?.copyWith(color: colorScheme.onSurface.withOpacity(0.8)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color: colorScheme.onSurface.withOpacity(0.5)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color: colorScheme.onSurface.withOpacity(0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: colorScheme.primary, width: 2),
                  ),
                  prefixIcon: Icon(Icons.music_note,
                      color: colorScheme.onSurface.withOpacity(0.8)),
                  fillColor: colorScheme.surface,
                  filled: true,
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Şarkı adı gerekli' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: artistController,
                style:
                    textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'Sanatçı',
                  labelStyle: textTheme.bodyLarge
                      ?.copyWith(color: colorScheme.onSurface.withOpacity(0.8)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color: colorScheme.onSurface.withOpacity(0.5)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color: colorScheme.onSurface.withOpacity(0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: colorScheme.primary, width: 2),
                  ),
                  prefixIcon: Icon(Icons.person,
                      color: colorScheme.onSurface.withOpacity(0.8)),
                  fillColor: colorScheme.surface,
                  filled: true,
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Sanatçı adı gerekli' : null,
              ),
              const SizedBox(height: 24),
              if (isUploading) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Yükleniyor...',
                      textAlign: TextAlign.center,
                      style: textTheme.titleMedium?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onBackground),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(uploadProgress * 100).toInt()}%',
                      style: textTheme.titleMedium?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: uploadProgress,
                  backgroundColor: colorScheme.primary.withOpacity(0.3),
                  valueColor:
                      AlwaysStoppedAnimation<Color>(colorScheme.primary),
                ),
                const SizedBox(height: 16),
              ],
              ElevatedButton(
                onPressed: isUploading ? null : uploadTrack,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: textTheme.labelLarge?.copyWith(fontSize: 18),
                ),
                child: isUploading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  colorScheme.onPrimary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text('Yükleniyor...', style: textTheme.labelLarge),
                        ],
                      )
                    : Text('Şarkıyı Yükle', style: textTheme.labelLarge),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
