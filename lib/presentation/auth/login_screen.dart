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
      backgroundColor: AppConstants.lightGrey,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // En-tête mycologique
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.eco,
                    size: 64,
                    color: AppConstants.primaryGreen,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  AppConstants.appName,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryGreen,
                  ),
                ),
                const Text(
                  AppConstants.farmSubtitle,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 32),

                // Formulaire de connexion
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Connexion à l\'exploitation',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),

                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.red.shade800),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Adresse Email',
                              prefixIcon: Icon(Icons.email_outlined),
                              border: OutlineInputBorder(),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Veuillez saisir votre adresse email.';
                              }
                              if (!val.contains('@')) {
                                return 'Adresse email non valide.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Mot de passe',
                              prefixIcon: Icon(Icons.lock_outlined),
                              border: OutlineInputBorder(),
                            ),
                            validator: (val) {
                              if (val == null || val.length < 6) {
                                return 'Le mot de passe doit comporter au moins 6 caractères.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          MycoButton(
                            label: 'Se Connecter',
                            icon: Icons.login,
                            isLoading: _isLoading,
                            onPressed: _handleLogin,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Accès Rapide Test de Rôles (Mode Démo) :',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blueGrey),
                ),
                const SizedBox(height: 12),

                // Boutons d'accès rapide par rôle
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.admin_panel_settings, size: 18),
                      label: const Text('Admin Ferme'),
                      backgroundColor: Colors.blue.shade50,
                      onPressed: () {
                        ref.read(authRepositoryProvider).switchDemoRole(UserRole.admin);
                      },
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.grass, size: 18),
                      label: const Text('Responsable Culture'),
                      backgroundColor: Colors.green.shade50,
                      onPressed: () {
                        ref.read(authRepositoryProvider).switchDemoRole(UserRole.productionManager);
                      },
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.delivery_dining, size: 18),
                      label: const Text('Livreur Terrain'),
                      backgroundColor: Colors.orange.shade50,
                      onPressed: () {
                        ref.read(authRepositoryProvider).switchDemoRole(UserRole.deliveryPerson);
                      },
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
