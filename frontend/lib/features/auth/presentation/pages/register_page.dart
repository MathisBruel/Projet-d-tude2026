import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:agrisense/core/theme/app_theme.dart';
import 'package:agrisense/core/services/api_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  String _selectedRole = 'Agriculteur';
  bool _obscurePassword = true;
  bool _isLoading = false;
  int _passwordStrength = 0; // 0 à 4

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updatePasswordStrength);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _updatePasswordStrength() {
    final password = _passwordController.text;
    int strength = 0;
    if (password.length >= 8) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;
    
    setState(() {
      _passwordStrength = strength;
    });
  }

  Future<void> _handleContinue() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }
    
    if (_passwordStrength < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mot de passe trop faible')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await ApiService.register({
      'email': _emailController.text,
      'password': _passwordController.text,
      'first_name': _firstNameController.text,
      'last_name': _lastNameController.text,
      'role': _selectedRole == 'Agriculteur' ? 'farmer' : 'agronomist',
    });

    setState(() => _isLoading = false);

    if (result.containsKey('token') && result.containsKey('message') && result['message'].toString().contains('succès')) {
      if (mounted) {
        // Auto-login réussi (token reçu)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            content: Text('Compte créé ! Bienvenue ${_firstNameController.text}'),
          ),
        );
        context.go('/register-success');
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? result['error'] ?? 'Erreur inconnue')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.neutreDark),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stepper
              Row(
                children: [
                  _buildStepCircle('1', true),
                  const SizedBox(width: 8),
                  const Text('Compte', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  Expanded(child: Container(height: 2, color: AppColors.primary)),
                  const SizedBox(width: 12),
                  const Text('Exploitation', style: TextStyle(color: AppColors.neutreMedium)),
                  const SizedBox(width: 8),
                  _buildStepCircle('2', false),
                ],
              ),
              const SizedBox(height: 32),
              
              Text(
                'Créer votre compte',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
              ),
              const SizedBox(height: 8),
              Text(
                'Vos informations personnelles',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.neutreMedium),
              ),
              const SizedBox(height: 32),
              
              // Name Row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _firstNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(hintText: 'Pierre'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _lastNameController,
                      inputFormatters: [
                        UpperCaseTextFormatter(),
                      ],
                      decoration: const InputDecoration(hintText: 'MOREAU'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Email
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.mail_outline),
                  hintText: 'pierre.moreau@beauce.fr',
                ),
              ),
              const SizedBox(height: 16),
              
              // Password
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline),
                  hintText: '••••••••••••',
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              // Password strength dynamic
              Row(
                children: [
                  Expanded(child: _buildStrengthBar(_passwordStrength >= 1 ? AppColors.primary : AppColors.border)),
                  const SizedBox(width: 4),
                  Expanded(child: _buildStrengthBar(_passwordStrength >= 2 ? AppColors.primary : AppColors.border)),
                  const SizedBox(width: 4),
                  Expanded(child: _buildStrengthBar(_passwordStrength >= 3 ? AppColors.primary : AppColors.border)),
                  const SizedBox(width: 4),
                  Expanded(child: _buildStrengthBar(_passwordStrength >= 4 ? AppColors.primary : AppColors.border)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    _passwordStrength < 2 ? 'Faible' : (_passwordStrength < 4 ? 'Moyen' : 'Fort'), 
                    style: TextStyle(
                      color: _passwordStrength < 2 ? AppColors.error : AppColors.primary, 
                      fontSize: 12, 
                      fontWeight: FontWeight.bold
                    )
                  ),
                  const Text(' — Min. 8 carac. + maj. + chiffres', style: TextStyle(color: AppColors.neutreMedium, fontSize: 12)),
                  const Spacer(),
                  if (_passwordStrength >= 3) const Icon(Icons.check_circle, color: AppColors.primary, size: 14),
                ],
              ),
              
              const SizedBox(height: 32),
              Text('Je suis', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              // Role selection
              Row(
                children: [
                  Expanded(
                    child: _buildRoleCard(
                      'Agriculteur',
                      'Gérer mes parcelles et obtenir des prédictions',
                      Icons.eco_outlined,
                      _selectedRole == 'Agriculteur',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildRoleCard(
                      'Agronome',
                      'Expertise technique et conseils',
                      Icons.architecture_outlined,
                      _selectedRole == 'Agronome',
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              
              ElevatedButton(
                onPressed: _isLoading ? null : _handleContinue,
                child: _isLoading 
                  ? const SizedBox(
                      height: 20, 
                      width: 20, 
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text('Continuer'),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 20),
                      ],
                    ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepCircle(String text, bool active) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.white,
        border: Border.all(color: active ? AppColors.primary : AppColors.border, width: 1.5),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: active ? AppColors.white : AppColors.neutreMedium,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStrengthBar(Color color) {
    return Container(height: 4, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)));
  }

  Widget _buildRoleCard(String title, String sub, IconData icon, bool selected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = title),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.surfacePrimary : AppColors.white,
          border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: selected ? AppColors.primary : AppColors.neutreMedium),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text(sub, style: const TextStyle(fontSize: 11, color: AppColors.neutreMedium)),
          ],
        ),
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
