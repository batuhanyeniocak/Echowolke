import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../services/firebase_service.dart';
import '../models/playlist.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CreatePlaylistScreen extends StatefulWidget {
  final Playlist? playlistToEdit;

  const CreatePlaylistScreen({super.key, this.playlistToEdit});

  @override
  State<CreatePlaylistScreen> createState() => _CreatePlaylistScreenState();
}

class _CreatePlaylistScreenState extends State<CreatePlaylistScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  File? _pickedImageFile;
  Uint8List? _pickedImageBytes;
  String? _existingImageUrl;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.playlistToEdit?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.playlistToEdit?.description ?? '');
    _existingImageUrl = widget.playlistToEdit?.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    print('DEBUG: _pickImage metodu başladı.');
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: kIsWeb,
        withReadStream: !kIsWeb,
      );

      if (result != null) {
        print('DEBUG: FilePicker sonuç döndürdü.');
        final platformFile = result.files.single;
        print('DEBUG: Seçilen dosya adı: ${platformFile.name}');
        print('DEBUG: Seçilen dosya boyutu: ${platformFile.size} bytes');
        print('DEBUG: kIsWeb değeri: $kIsWeb');

        setState(() {
          if (kIsWeb) {
            _pickedImageBytes = platformFile.bytes;
            _pickedImageFile = null;
            print(
                'DEBUG: Web için _pickedImageBytes ayarlandı. Boyut: ${_pickedImageBytes?.length} bytes');
          } else {
            if (platformFile.path != null) {
              _pickedImageFile = File(platformFile.path!);
              _pickedImageBytes = null;
              print(
                  'DEBUG: Mobil için _pickedImageFile ayarlandı. Yol: ${_pickedImageFile?.path}');
            } else {
              print('HATA: Mobil platformda dosya yolu boş!');
            }
          }
          _existingImageUrl = null;
        });
      } else {
        print('DEBUG: Resim seçimi iptal edildi.');
      }
    } catch (e, stackTrace) {
      print('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
      print('HATA: _pickImage sırasında beklenmedik bir hata oluştu: $e');
      print('Stack Trace (pickImage): $stackTrace');
      print('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Resim seçme hatası: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _savePlaylist() async {
    print('DEBUG: _savePlaylist metodu başladı.');
    if (!_formKey.currentState!.validate()) {
      print('DEBUG: Form validasyonu başarısız.');
      return;
    }

    setState(() {
      _isLoading = true;
      print('DEBUG: _isLoading true olarak ayarlandı.');
    });

    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        print('HATA: Kullanıcı girişi yapılmamış!');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Kullanıcı girişi yapılmamış!'),
              backgroundColor: Colors.red),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      String? imageUrl;
      if (kIsWeb
          ? (_pickedImageBytes != null && _pickedImageBytes!.isNotEmpty)
          : (_pickedImageFile != null && await _pickedImageFile!.exists())) {
        print('DEBUG: Yeni resim yüklemeye başlanıyor...');
        final String imageFileName = 'playlists/${const Uuid().v4()}.jpg';

        imageUrl = await firebaseService.uploadCoverImage(
          kIsWeb ? _pickedImageBytes : _pickedImageFile,
          imageFileName,
        );
        print('DEBUG: Yeni resim yüklendi: $imageUrl');
      } else if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
        imageUrl = _existingImageUrl;
        print('DEBUG: Mevcut resim URL\'si kullanılıyor: $imageUrl');
      } else {
        imageUrl = 'https://via.placeholder.com/300x300?text=Playlist+Cover';
        print('DEBUG: Varsayılan resim URL\'si kullanılıyor: $imageUrl');
      }

      if (widget.playlistToEdit == null) {
        print('DEBUG: Yeni çalma listesi oluşturuluyor...');
        final newPlaylist = Playlist(
          id: const Uuid().v4(),
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
          imageUrl: imageUrl ?? '',
          creatorId: currentUser.uid,
          createdAt: DateTime.now(),
        );
        await firebaseService.createPlaylist(newPlaylist);
        print('DEBUG: Çalma listesi Firebase\'e kaydedildi.');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Çalma listesi başarıyla oluşturuldu!')),
        );
      } else {
        print('DEBUG: Çalma listesi güncelleniyor...');
        final Map<String, dynamic> updateData = {
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
          'imageUrl': imageUrl ?? '',
        };
        await firebaseService.updatePlaylist(
            widget.playlistToEdit!.id, updateData);
        print('DEBUG: Çalma listesi Firebase\'de güncellendi.');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Çalma listesi başarıyla güncellendi!')),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e, stackTrace) {
      print('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
      print('Çalma listesi yükleme/kaydetme sırasında HATA: $e');
      print('Stack Trace: $stackTrace');
      print('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata oluştu: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
        print('DEBUG: _isLoading false olarak ayarlandı.');
      });
    }
  }

  Widget _buildImageDisplay() {
    if (_pickedImageFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(_pickedImageFile!, fit: BoxFit.cover),
      );
    } else if (_pickedImageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.memory(_pickedImageBytes!, fit: BoxFit.cover),
      );
    } else if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: CachedNetworkImage(
          imageUrl: _existingImageUrl!,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[300],
            child:
                const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[400],
            child:
                const Icon(Icons.broken_image, size: 50, color: Colors.white70),
          ),
        ),
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_alt, size: 50, color: Colors.grey[700]),
          const SizedBox(height: 8),
          Text(
            'Kapak Fotoğrafı Seç',
            style: TextStyle(color: Colors.grey[700]),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.playlistToEdit == null
            ? 'Yeni Çalma Listesi Oluştur'
            : 'Çalma Listesini Düzenle'),
        backgroundColor: Colors.orange,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: _buildImageDisplay(),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Çalma Listesi Adı',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.playlist_add_check),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Lütfen bir çalma listesi adı girin.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Açıklama (isteğe bağlı)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.notes),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 25),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _savePlaylist,
                      icon: Icon(widget.playlistToEdit == null
                          ? Icons.add
                          : Icons.save),
                      label: Text(widget.playlistToEdit == null
                          ? 'Çalma Listesi Oluştur'
                          : 'Değişiklikleri Kaydet'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
