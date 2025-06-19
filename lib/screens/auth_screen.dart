import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/services/firebase_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();

  bool _isLogin = true;
  bool _isLoading = false;

  void _submitAuthForm() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }
    _formKey.currentState!.save();

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      if (_isLogin) {
        await _firebaseService.signInWithUsernameAndPassword(
          _usernameController.text.trim(),
          _passwordController.text.trim(),
        );
      } else {
        await _firebaseService.registerWithUsernameEmailAndPassword(
          _usernameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(_isLogin
                  ? 'Giriş başarılı!'
                  : 'Kayıt başarılı! Hoş geldiniz.'),
              backgroundColor: Theme.of(context).colorScheme.onBackground),
        );
      }
    } on FirebaseAuthException catch (error) {
      String errorMessage = _firebaseService.getErrorMessage(error.code);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(errorMessage),
              backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(error.toString()),
              backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Giriş Yap' : 'Kayıt Ol',
            style:
                textTheme.titleLarge?.copyWith(color: colorScheme.onSurface)),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/echowolke_logo.png',
                height: 200,
                width: 200,
                fit: BoxFit.contain,
              ),
              Card(
                margin: const EdgeInsets.all(20),
                color: colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          key: const ValueKey('username'),
                          controller: _usernameController,
                          keyboardType: TextInputType.text,
                          style: textTheme.bodyLarge
                              ?.copyWith(color: colorScheme.onSurface),
                          decoration: InputDecoration(
                            labelText: 'Kullanıcı Adı',
                            labelStyle: textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.8)),
                            prefixIcon: Icon(Icons.person,
                                color: colorScheme.onSurface.withOpacity(0.8)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color:
                                      colorScheme.onSurface.withOpacity(0.5)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color:
                                      colorScheme.onSurface.withOpacity(0.5)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color: colorScheme.primary, width: 2),
                            ),
                            fillColor: colorScheme.background,
                            filled: true,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().length < 4) {
                              return 'Kullanıcı adı en az 4 karakter olmalı.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        if (!_isLogin)
                          TextFormField(
                            key: const ValueKey('email'),
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: textTheme.bodyLarge
                                ?.copyWith(color: colorScheme.onSurface),
                            decoration: InputDecoration(
                              labelText: 'E-posta Adresi',
                              labelStyle: textTheme.bodyLarge?.copyWith(
                                  color:
                                      colorScheme.onSurface.withOpacity(0.8)),
                              prefixIcon: Icon(Icons.email,
                                  color:
                                      colorScheme.onSurface.withOpacity(0.8)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                    color:
                                        colorScheme.onSurface.withOpacity(0.5)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                    color:
                                        colorScheme.onSurface.withOpacity(0.5)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                    color: colorScheme.primary, width: 2),
                              ),
                              fillColor: colorScheme.background,
                              filled: true,
                            ),
                            validator: (value) {
                              if (value == null || !value.contains('@')) {
                                return 'Geçerli bir e-posta adresi girin.';
                              }
                              return null;
                            },
                          ),
                        if (!_isLogin) const SizedBox(height: 12),
                        TextFormField(
                          key: const ValueKey('password'),
                          controller: _passwordController,
                          obscureText: true,
                          style: textTheme.bodyLarge
                              ?.copyWith(color: colorScheme.onSurface),
                          decoration: InputDecoration(
                            labelText: 'Şifre',
                            labelStyle: textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.8)),
                            prefixIcon: Icon(Icons.lock,
                                color: colorScheme.onSurface.withOpacity(0.8)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color:
                                      colorScheme.onSurface.withOpacity(0.5)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color:
                                      colorScheme.onSurface.withOpacity(0.5)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color: colorScheme.primary, width: 2),
                            ),
                            fillColor: colorScheme.background,
                            filled: true,
                          ),
                          validator: (value) {
                            if (value == null || value.length < 6) {
                              return 'Şifre en az 6 karakter olmalı.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        if (_isLoading)
                          CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  colorScheme.primary))
                        else ...[
                          ElevatedButton(
                            onPressed: _submitAuthForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(_isLogin ? 'Giriş Yap' : 'Kayıt Ol',
                                style: textTheme.labelLarge),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () {
                              if (mounted) {
                                setState(() {
                                  _isLogin = !_isLogin;
                                });
                              }
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: colorScheme.primary,
                            ),
                            child: Text(
                              _isLogin
                                  ? 'Hesabınız yok mu? Şimdi Kayıt Olun'
                                  : 'Zaten bir hesabınız var mı? Giriş Yapın',
                              style: textTheme.bodyMedium
                                  ?.copyWith(color: colorScheme.primary),
                            ),
                          ),
                        ],
                      ],
                    ),
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
