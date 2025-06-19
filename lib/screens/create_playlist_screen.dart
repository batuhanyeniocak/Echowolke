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
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: kIsWeb,
        withReadStream: !kIsWeb,
      );

      if (result != null) {
        final platformFile = result.files.single;
        if (mounted) {
          setState(() {
            if (kIsWeb) {
              _pickedImageBytes = platformFile.bytes;
              _pickedImageFile = null;
            } else {
              if (platformFile.path != null) {
                _pickedImageFile = File(platformFile.path!);
                _pickedImageBytes = null;
              }
            }
            _existingImageUrl = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Resim seçme hatası: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _savePlaylist() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Kullanıcı girişi yapılmamış!'),
              backgroundColor: Theme.of(context).colorScheme.error),
        );
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      String? imageUrl;
      if (kIsWeb
          ? (_pickedImageBytes != null && _pickedImageBytes!.isNotEmpty)
          : (_pickedImageFile != null && await _pickedImageFile!.exists())) {
        final String imageFileName = 'playlists/${const Uuid().v4()}.jpg';

        imageUrl = await firebaseService.uploadCoverImage(
          kIsWeb ? _pickedImageBytes : _pickedImageFile,
          imageFileName,
        );
      } else if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
        imageUrl = _existingImageUrl;
      } else {
        imageUrl = 'https://via.placeholder.com/300x300?text=Playlist+Cover';
      }

      if (widget.playlistToEdit == null) {
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
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Çalma listesi başarıyla oluşturuldu!'),
              backgroundColor: Theme.of(context).colorScheme.onBackground),
        );
      } else {
        final Map<String, dynamic> updateData = {
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
          'imageUrl': imageUrl ?? '',
        };
        await firebaseService.updatePlaylist(
            widget.playlistToEdit!.id, updateData);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Çalma listesi başarıyla güncellendi!'),
              backgroundColor: Theme.of(context).colorScheme.onBackground),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata oluştu: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildImageDisplay() {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    if (_pickedImageFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(
          _pickedImageFile!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    } else if (_pickedImageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.memory(
          _pickedImageBytes!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    } else if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: CachedNetworkImage(
          imageUrl: _existingImageUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          placeholder: (context, url) => Container(
            color: colorScheme.surface.withOpacity(0.5),
            child: Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(colorScheme.primary))),
          ),
          errorWidget: (context, url, error) => Container(
            color: colorScheme.surface.withOpacity(0.7),
            child: Icon(Icons.broken_image,
                size: 50, color: colorScheme.onSurface.withOpacity(0.7)),
          ),
        ),
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_alt,
              size: 50, color: colorScheme.onSurface.withOpacity(0.7)),
          const SizedBox(height: 8),
          Text(
            'Kapak Fotoğrafı Seç',
            style: textTheme.bodyMedium
                ?.copyWith(color: colorScheme.onSurface.withOpacity(0.7)),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.playlistToEdit == null
                ? 'Yeni Çalma Listesi Oluştur'
                : 'Çalma Listesini Düzenle,',
            style:
                textTheme.titleLarge?.copyWith(color: colorScheme.onSurface)),
        backgroundColor: colorScheme.surface,
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
                    color: colorScheme.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: colorScheme.onSurface.withOpacity(0.5)),
                  ),
                  child: _buildImageDisplay(),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                style:
                    textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'Çalma Listesi Adı',
                  labelStyle: textTheme.bodyLarge
                      ?.copyWith(color: colorScheme.onSurface.withOpacity(0.8)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                        color: colorScheme.onSurface.withOpacity(0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: colorScheme.primary, width: 2),
                  ),
                  prefixIcon: Icon(Icons.playlist_add_check,
                      color: colorScheme.onSurface.withOpacity(0.8)),
                  fillColor: colorScheme.surface,
                  filled: true,
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
                style:
                    textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'Açıklama (isteğe bağlı)',
                  labelStyle: textTheme.bodyLarge
                      ?.copyWith(color: colorScheme.onSurface.withOpacity(0.8)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                        color: colorScheme.onSurface.withOpacity(0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: colorScheme.primary, width: 2),
                  ),
                  prefixIcon: Icon(Icons.notes,
                      color: colorScheme.onSurface.withOpacity(0.8)),
                  fillColor: colorScheme.surface,
                  filled: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 25),
              _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.primary)))
                  : ElevatedButton.icon(
                      onPressed: _savePlaylist,
                      icon: Icon(
                          widget.playlistToEdit == null
                              ? Icons.add
                              : Icons.save,
                          color: colorScheme.onPrimary),
                      label: Text(
                          widget.playlistToEdit == null
                              ? 'Çalma Listesi Oluştur'
                              : 'Değişiklikleri Kaydet',
                          style: textTheme.labelLarge),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
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
