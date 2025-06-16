import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'auth_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
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
      setState(() => _isFetchingData = false);
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
        setState(() {
          _profileImageUrl = data['profileImageUrl'];
        });
      }
    } catch (e) {
      _showSnackBar("Kullanıcı verileri yüklenemedi: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isFetchingData = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null && result.files.single.path != null) {
        setState(() {
          _profileImageFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      _showSnackBar("Resim seçilemedi: $e", isError: true);
    }
  }

  Future<String?> _uploadFile(File? file, String path) async {
    if (file == null) return null;
    try {
      final ref = FirebaseStorage.instance.ref(path);
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      _showSnackBar("Dosya yüklenemedi: $e", isError: true);
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentUser == null) return;

    setState(() => _isLoading = true);
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

      String? newProfileImageUrl = await _uploadFile(
          _profileImageFile, 'profile_images/${_currentUser!.uid}');
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

    setState(() => _isLoading = true);

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
          MaterialPageRoute(builder: (context) => const Text("Giriş Ekranı")),
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
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  void _showDeleteConfirmationDialog() {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Hesabı Silmeyi Onayla"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                  "Bu işlem geri alınamaz. Devam etmek için lütfen mevcut şifrenizi girin."),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Mevcut Şifre",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("İptal"),
            ),
            TextButton(
              onPressed: () {
                final password = passwordController.text.trim();
                if (password.isNotEmpty) {
                  Navigator.of(context).pop();
                  _deleteAccount(password);
                }
              },
              child:
                  const Text("Hesabı Sil", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profili Düzenle"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveProfile,
          ),
        ],
      ),
      body: _isFetchingData
          ? const Center(child: CircularProgressIndicator())
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
                    const Center(child: CircularProgressIndicator())
                  else
                    ElevatedButton.icon(
                      onPressed: _saveProfile,
                      icon: const Icon(Icons.save_alt_outlined),
                      label: const Text("Değişiklikleri Kaydet"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileImagePicker() {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 64,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: _profileImageFile != null
                ? FileImage(_profileImageFile!)
                : (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
                    ? CachedNetworkImageProvider(_profileImageUrl!)
                        as ImageProvider
                    : null,
            child: (_profileImageUrl == null || _profileImageUrl!.isEmpty) &&
                    _profileImageFile == null
                ? Icon(Icons.person, size: 60, color: Colors.grey.shade500)
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: InkWell(
              onTap: _pickImage,
              child: const CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blue,
                child: Icon(Icons.edit, color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection() {
    return ExpansionTile(
      initiallyExpanded: false,
      title: const Text("Hesap Güvenliği",
          style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: const Text("Kullanıcı adı, e-posta ve şifre"),
      leading: const Icon(Icons.security_outlined),
      children: [
        Padding(
          padding: const EdgeInsets.only(
              top: 16.0, bottom: 8.0, left: 8.0, right: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: "Kullanıcı Adı",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) => (value == null || value.trim().length < 4)
                    ? "Kullanıcı adı en az 4 karakter olmalı."
                    : null,
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.email_outlined, color: Colors.grey),
                title: const Text("Mevcut E-posta"),
                subtitle: Text(_censorEmail(_currentUser?.email)),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "Yeni E-posta Adresi",
                  hintText: "Değiştirmek istemiyorsanız boş bırakın",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
              TextFormField(
                controller: _currentPasswordController,
                decoration: const InputDecoration(
                  labelText: "Mevcut Şifre",
                  hintText: "Değişiklik yapmak için doldurun",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_open_outlined),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordController,
                decoration: const InputDecoration(
                  labelText: "Yeni Şifre",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
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
                decoration: const InputDecoration(
                  labelText: "Yeni Şifre (Tekrar)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
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
    return ExpansionTile(
      title: const Text("Hesabı Sil",
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
      subtitle: const Text("Bu işlem geri alınamaz"),
      leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Hesabınızı silmek, tüm profil bilgilerinizi, beğenilerinizi ve çalma listelerinizi kalıcı olarak ortadan kaldıracaktır. Bu işlemi onaylıyorsanız, lütfen aşağıdaki butona tıklayın.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _showDeleteConfirmationDialog,
                icon: const Icon(Icons.warning_amber_rounded),
                label: const Text("Hesabımı Kalıcı Olarak Sil"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
