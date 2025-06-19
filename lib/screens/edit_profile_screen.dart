import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'auth_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final User? _currentUser = FirebaseAuth.instance.currentUser;

  String? _profileImageUrl;
  File? _profileImageFile;
  Uint8List? _profileImageBytes;
  String _initialUsername = '';

  bool _isLoading = false;
  bool _isFetchingData = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (_currentUser == null) {
      if (mounted) setState(() => _isFetchingData = false);
      return;
    }
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();
      if (mounted && userDoc.exists) {
        final data = userDoc.data()!;
        _initialUsername = data['username'] ?? '';
        _usernameController.text = _initialUsername;
        if (mounted) {
          setState(() {
            _profileImageUrl = data['profileImageUrl'];
          });
        }
      }
    } catch (e) {
      _showSnackBar("Kullanıcı verileri yüklenemedi: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isFetchingData = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: kIsWeb,
        withReadStream: !kIsWeb,
      );

      if (result != null) {
        if (mounted) {
          setState(() {
            if (kIsWeb) {
              _profileImageBytes = result.files.single.bytes;
              _profileImageFile = null;
            } else {
              if (result.files.single.path != null) {
                _profileImageFile = File(result.files.single.path!);
                _profileImageBytes = null;
              }
            }
            _profileImageUrl = null;
          });
        }
      }
    } catch (e) {
      _showSnackBar("Resim seçilemedi: $e", isError: true);
    }
  }

  Future<String?> _uploadFile(dynamic fileData, String path) async {
    if (fileData == null) return null;
    try {
      final ref = FirebaseStorage.instance.ref(path);
      UploadTask uploadTask;

      if (kIsWeb) {
        uploadTask = ref.putData(fileData as Uint8List);
      } else {
        uploadTask = ref.putFile(fileData as File);
      }

      await uploadTask;
      final downloadUrl = await ref.getDownloadURL();
      print("DEBUG: Resim yüklendi, URL: $downloadUrl");
      return downloadUrl;
    } catch (e) {
      _showSnackBar("Dosya yüklenemedi: $e", isError: true);
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentUser == null) return;

    if (mounted) setState(() => _isLoading = true);
    final String newUsername = _usernameController.text.trim().toLowerCase();
    final String newEmail = _emailController.text.trim();
    final String newPassword = _newPasswordController.text.trim();
    final String currentPassword = _currentPasswordController.text.trim();

    final bool isUsernameChanged =
        newUsername != _initialUsername.toLowerCase();
    final bool isEmailChanged = newEmail.isNotEmpty;
    final bool isPasswordChanged = newPassword.isNotEmpty;
    final bool isSensitiveChange =
        isUsernameChanged || isEmailChanged || isPasswordChanged;

    try {
      if (isSensitiveChange && currentPassword.isEmpty) {
        throw Exception(
            "Değişiklik yapmak için mevcut şifrenizi girmelisiniz.");
      }

      if (isSensitiveChange) {
        final cred = EmailAuthProvider.credential(
          email: _currentUser!.email!,
          password: currentPassword,
        );
        await _currentUser!.reauthenticateWithCredential(cred);
      }

      String? newProfileImageUrl;
      if (kIsWeb) {
        if (_profileImageBytes != null && _profileImageBytes!.isNotEmpty) {
          newProfileImageUrl = await _uploadFile(
              _profileImageBytes, 'profile_images/${_currentUser!.uid}');
        }
      } else {
        if (_profileImageFile != null) {
          newProfileImageUrl = await _uploadFile(
              _profileImageFile, 'profile_images/${_currentUser!.uid}');
        }
      }

      Map<String, dynamic> dataToUpdate = {'username': newUsername};
      if (newProfileImageUrl != null) {
        dataToUpdate['profileImageUrl'] = newProfileImageUrl;
      }
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .update(dataToUpdate);

      if (isEmailChanged) {
        await _currentUser!.verifyBeforeUpdateEmail(newEmail);
        _showSnackBar("E-posta güncelleme linki yeni adresinize gönderildi.",
            isError: false);
      }

      if (isPasswordChanged) {
        await _currentUser!.updatePassword(newPassword);
        _showSnackBar("Şifreniz başarıyla güncellendi.", isError: false);
      }

      _showSnackBar("Profil başarıyla güncellendi!", isError: false);
      if (mounted) Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      _showSnackBar(e.message ?? "Bir kimlik doğrulama hatası oluştu.",
          isError: true);
    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAccount(String currentPassword) async {
    if (_currentUser == null) return;

    if (mounted) setState(() => _isLoading = true);

    try {
      final cred = EmailAuthProvider.credential(
          email: _currentUser!.email!, password: currentPassword);
      await _currentUser!.reauthenticateWithCredential(cred);

      if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
        try {
          await FirebaseStorage.instance.refFromURL(_profileImageUrl!).delete();
        } catch (e) {
          print("Storage dosyası silinirken hata (önemsiz): $e");
        }
      }
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .delete();

      await _currentUser!.delete();

      _showSnackBar("Hesabınız kalıcı olarak silindi.", isError: false);
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      _showSnackBar(e.message ?? "Hesap silinirken bir hata oluştu.",
          isError: true);
    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _censorEmail(String? email) {
    if (email == null || email.isEmpty) return "E-posta bulunamadı";
    final parts = email.split('@');
    if (parts.length != 2) return "Geçersiz e-posta";
    final localPart = parts[0];
    final domain = parts[1];
    if (localPart.isEmpty) return "@$domain";
    return '${localPart[0]}*****@$domain';
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.onBackground,
      ),
    );
  }

  void _showDeleteConfirmationDialog() {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        final ColorScheme colorScheme = Theme.of(context).colorScheme;
        final TextTheme textTheme = Theme.of(context).textTheme;

        return AlertDialog(
          backgroundColor: colorScheme.surface,
          title: Text("Hesabı Silmeyi Onayla",
              style:
                  textTheme.titleLarge?.copyWith(color: colorScheme.onSurface)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Bu işlem geri alınamaz. Devam etmek için lütfen mevcut şifrenizi girin.",
                style: textTheme.bodyMedium
                    ?.copyWith(color: colorScheme.onSurface.withOpacity(0.8)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                style:
                    textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: "Mevcut Şifre",
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
                  fillColor: colorScheme.background,
                  filled: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
              child: Text("İptal",
                  style: textTheme.labelLarge
                      ?.copyWith(color: colorScheme.primary)),
            ),
            TextButton(
              onPressed: () {
                final password = passwordController.text.trim();
                if (password.isNotEmpty) {
                  Navigator.of(context).pop();
                  _deleteAccount(password);
                }
              },
              style: TextButton.styleFrom(foregroundColor: colorScheme.error),
              child: Text("Hesabı Sil",
                  style:
                      textTheme.labelLarge?.copyWith(color: colorScheme.error)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text("Profili Düzenle",
            style:
                textTheme.titleLarge?.copyWith(color: colorScheme.onSurface)),
        backgroundColor: colorScheme.surface,
        actions: [
          IconButton(
            icon: Icon(Icons.save, color: colorScheme.onSurface),
            onPressed: _isLoading ? null : _saveProfile,
          ),
        ],
      ),
      body: _isFetchingData
          ? Center(
              child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(colorScheme.primary)))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  const SizedBox(height: 20),
                  _buildProfileImagePicker(),
                  const SizedBox(height: 30),
                  _buildSecuritySection(),
                  const SizedBox(height: 16),
                  _buildDeleteSection(),
                  const SizedBox(height: 32),
                  if (_isLoading)
                    Center(
                        child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                colorScheme.primary)))
                  else
                    ElevatedButton.icon(
                      onPressed: _saveProfile,
                      icon: Icon(Icons.save_alt_outlined,
                          color: colorScheme.onPrimary),
                      label: Text("Değişiklikleri Kaydet",
                          style: textTheme.labelLarge),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: textTheme.labelLarge?.copyWith(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileImagePicker() {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 64,
            backgroundColor: colorScheme.surface.withOpacity(0.5),
            backgroundImage: _profileImageFile != null
                ? FileImage(_profileImageFile!) as ImageProvider<Object>
                : (_profileImageBytes != null && _profileImageBytes!.isNotEmpty)
                    ? MemoryImage(_profileImageBytes!) as ImageProvider<Object>
                    : (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
                        ? CachedNetworkImageProvider(_profileImageUrl!)
                            as ImageProvider<Object>
                        : null,
            child: (_profileImageUrl == null || _profileImageUrl!.isEmpty) &&
                    _profileImageFile == null &&
                    _profileImageBytes == null
                ? Icon(Icons.person,
                    size: 60, color: colorScheme.onSurface.withOpacity(0.7))
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: InkWell(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 20,
                backgroundColor: colorScheme.primary,
                child: Icon(Icons.edit, color: colorScheme.onPrimary, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection() {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return ExpansionTile(
      initiallyExpanded: false,
      title: Text("Hesap Güvenliği",
          style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
      subtitle: Text("Kullanıcı adı, e-posta ve şifre",
          style: textTheme.bodyMedium
              ?.copyWith(color: colorScheme.onSurface.withOpacity(0.7))),
      leading: Icon(Icons.security_outlined,
          color: colorScheme.onSurface.withOpacity(0.8)),
      children: [
        Padding(
          padding: const EdgeInsets.only(
              top: 16.0, bottom: 8.0, left: 8.0, right: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _usernameController,
                style:
                    textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: "Kullanıcı Adı",
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
                  fillColor: colorScheme.background,
                  filled: true,
                ),
                validator: (value) => (value == null || value.trim().length < 4)
                    ? "Kullanıcı adı en az 4 karakter olmalı."
                    : null,
              ),
              const SizedBox(height: 20),
              Divider(color: colorScheme.onSurface.withOpacity(0.3)),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.email_outlined,
                    color: colorScheme.onSurface.withOpacity(0.8)),
                title: Text("Mevcut E-posta",
                    style: textTheme.titleMedium
                        ?.copyWith(color: colorScheme.onSurface)),
                subtitle: Text(_censorEmail(_currentUser?.email),
                    style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7))),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _emailController,
                style:
                    textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: "Yeni E-posta Adresi",
                  labelStyle: textTheme.bodyLarge
                      ?.copyWith(color: colorScheme.onSurface.withOpacity(0.8)),
                  hintText: "Değiştirmek istemiyorsanız boş bırakın",
                  hintStyle: textTheme.bodyLarge
                      ?.copyWith(color: colorScheme.onSurface.withOpacity(0.5)),
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
                  fillColor: colorScheme.background,
                  filled: true,
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              Divider(color: colorScheme.onSurface.withOpacity(0.3)),
              const SizedBox(height: 10),
              TextFormField(
                controller: _currentPasswordController,
                style:
                    textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: "Mevcut Şifre",
                  labelStyle: textTheme.bodyLarge
                      ?.copyWith(color: colorScheme.onSurface.withOpacity(0.8)),
                  hintText: "Değişiklik yapmak için doldurun",
                  hintStyle: textTheme.bodyLarge
                      ?.copyWith(color: colorScheme.onSurface.withOpacity(0.5)),
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
                  prefixIcon: Icon(Icons.lock_open_outlined,
                      color: colorScheme.onSurface.withOpacity(0.8)),
                  fillColor: colorScheme.background,
                  filled: true,
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordController,
                style:
                    textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: "Yeni Şifre",
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
                  prefixIcon: Icon(Icons.lock_outline,
                      color: colorScheme.onSurface.withOpacity(0.8)),
                  fillColor: colorScheme.background,
                  filled: true,
                ),
                obscureText: true,
                validator: (value) {
                  if (value != null && value.isNotEmpty && value.length < 6) {
                    return "Yeni şifre en az 6 karakter olmalı.";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                style:
                    textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: "Yeni Şifre (Tekrar)",
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
                  prefixIcon: Icon(Icons.lock_outline,
                      color: colorScheme.onSurface.withOpacity(0.8)),
                  fillColor: colorScheme.background,
                  filled: true,
                ),
                obscureText: true,
                validator: (value) {
                  if (_newPasswordController.text.isNotEmpty &&
                      value != _newPasswordController.text) {
                    return "Yeni şifreler eşleşmiyor.";
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeleteSection() {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return ExpansionTile(
      title: Text("Hesabı Sil",
          style: textTheme.titleMedium?.copyWith(
              color: colorScheme.error, fontWeight: FontWeight.bold)),
      subtitle: Text("Bu işlem geri alınamaz",
          style: textTheme.bodyMedium
              ?.copyWith(color: colorScheme.onSurface.withOpacity(0.7))),
      leading: Icon(Icons.delete_forever_outlined, color: colorScheme.error),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Hesabınızı silmek, tüm profil bilgilerinizi, beğenilerinizi ve çalma listelerinizi kalıcı olarak ortadan kaldıracaktır. Bu işlemi onaylıyorsanız, lütfen aşağıdaki butona tıklayın.",
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium
                    ?.copyWith(color: colorScheme.onSurface.withOpacity(0.7)),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _showDeleteConfirmationDialog,
                icon: Icon(Icons.warning_amber_rounded,
                    color: colorScheme.onError),
                label: Text("Hesabımı Kalıcı Olarak Sil",
                    style: textTheme.labelLarge),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
