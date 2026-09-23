import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../providers/app_providers.dart';
import '../shared/myco_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'admin@ferme-myco.dz');
  final _passwordController = TextEditingController(text: 'MotDePasse123');
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signInWithEmailPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundDark,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // En-tête MycoTrack
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppConstants.cardDark,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppConstants.borderDark),
                  ),
                  child: const Text('🍄', style: TextStyle(fontSize: 48)),
                ),
                const SizedBox(height: 16),
                const Text(
                  'MycoTrack',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  AppConstants.farmSubtitle,
                  style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
                ),
                const SizedBox(height: 32),

                // Carte formulaire style sombre MycoTrack
                Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: AppConstants.cardDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppConstants.borderDark),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Connexion',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 18),

                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A1A1A),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF5A2A2A)),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: AppConstants.alertRed, fontSize: 13),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Adresse Email',
                            labelStyle: const TextStyle(color: Color(0xFF888888)),
                            prefixIcon: const Icon(Icons.email_outlined, color: AppConstants.accentGreen),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: AppConstants.borderDark),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: AppConstants.accentGreen),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Veuillez saisir votre email.';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Mot de passe',
                            labelStyle: const TextStyle(color: Color(0xFF888888)),
                            prefixIcon: const Icon(Icons.lock_outlined, color: AppConstants.accentGreen),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: AppConstants.borderDark),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: AppConstants.accentGreen),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.length < 6) return 'Minimum 6 caractères requis.';
                            return null;
                          },
                        ),
                        const SizedBox(height: 22),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _isLoading ? null : _handleLogin,
                          child: _isLoading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Se connecter', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                const Text(
                  'Accès rapide par rôle (Mode Démo) :',
                  style: TextStyle(color: Color(0xFF888888), fontSize: 12),
                ),
                const SizedBox(height: 10),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.admin_panel_settings, size: 16, color: AppConstants.accentGreen),
                      label: const Text('Admin', style: TextStyle(color: Colors.white, fontSize: 12)),
                      backgroundColor: AppConstants.cardDark,
                      side: const BorderSide(color: AppConstants.borderDark),
                      onPressed: () => ref.read(authRepositoryProvider).switchDemoRole(UserRole.admin),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.grass, size: 16, color: AppConstants.accentGreen),
                      label: const Text('Opérateur', style: TextStyle(color: Colors.white, fontSize: 12)),
                      backgroundColor: AppConstants.cardDark,
                      side: const BorderSide(color: AppConstants.borderDark),
                      onPressed: () => ref.read(authRepositoryProvider).switchDemoRole(UserRole.productionManager),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.delivery_dining, size: 16, color: AppConstants.alertYellow),
                      label: const Text('Livreur', style: TextStyle(color: Colors.white, fontSize: 12)),
                      backgroundColor: AppConstants.cardDark,
                      side: const BorderSide(color: AppConstants.borderDark),
                      onPressed: () => ref.read(authRepositoryProvider).switchDemoRole(UserRole.deliveryPerson),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
