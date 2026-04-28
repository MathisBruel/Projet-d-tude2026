import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:agrisense/core/theme/app_theme.dart';
import 'package:agrisense/core/services/api_service.dart';
import 'package:agrisense/core/services/auth_storage_service.dart';

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
      // Sauvegarder le token et l'ID utilisateur
      await AuthStorageService.saveToken(result['token'] as String);
      await AuthStorageService.saveUserId(result['user']['_id'] as String);

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
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.neutreLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back, size: 20, color: AppColors.neutreDark),
                    ),
                  ),
                ),
              // Stepper
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: const [
                        _StepBadge(active: true, label: '1'),
                        SizedBox(width: 10),
                        Text('Compte', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.neutreDark)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SizedBox(
                      height: 2,
                      child: Stack(
                        children: [
                          Container(decoration: BoxDecoration(color: AppColors.neutreLight, borderRadius: BorderRadius.circular(1))),
                          Container(width: 40, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(1))),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: const [
                        Text('Exploitation', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.neutreMedium)),
                        SizedBox(width: 10),
                        _StepBadge(active: false, label: '2'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Créer votre compte',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.5),
              ),
              const SizedBox(height: 4),
              const Text(
                'Vos informations personnelles',
                style: TextStyle(fontSize: 13, color: AppColors.neutreMedium),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _AgriTextField(
                      controller: _firstNameController,
                      hintText: 'Pierre',
                      textCapitalization: TextCapitalization.words,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AgriTextField(
                      controller: _lastNameController,
                      hintText: 'Moreau',
                      inputFormatters: [UpperCaseTextFormatter()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _AgriTextField(
                controller: _emailController,
                hintText: 'pierre.moreau@beauce.fr',
                prefixIcon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              _AgriTextField(
                controller: _passwordController,
                hintText: '••••••••••',
                prefixIcon: Icons.lock_outline,
                obscureText: _obscurePassword,
                suffix: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: AppColors.neutreMedium,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              const SizedBox(height: 10),
              _PasswordStrength(strength: _passwordStrength),
              const SizedBox(height: 24),
              const Text('Je suis', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildRoleCard(
                      'Agriculteur',
                      'Gérer mes parcelles et obtenir des prédictions',
                      Icons.eco_rounded,
                      _selectedRole == 'Agriculteur',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildRoleCard(
                      'Agronome',
                      'Expertise technique et conseils',
                      Icons.smart_toy_rounded,
                      _selectedRole == 'Agronome',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleContinue,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text('Continuer'),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 18),
                        ],
                      ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildRoleCard(String title, String sub, IconData icon, bool selected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = title),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.surfacePrimary : AppColors.white,
          border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 2 : 1.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: selected ? AppColors.primary : AppColors.neutreMedium, size: 22),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.neutreDark)),
            const SizedBox(height: 4),
            Text(sub, style: const TextStyle(fontSize: 11, color: AppColors.neutreMedium, height: 1.3)),
          ],
        ),
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge({required this.active, required this.label});

  final bool active;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: active ? AppColors.primary : AppColors.neutreLight, width: 1.5),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: active ? AppColors.white : AppColors.neutreMedium,
          ),
        ),
      ),
    );
  }
}

class _PasswordStrength extends StatelessWidget {
  const _PasswordStrength({required this.strength});

  final int strength;

  @override
  Widget build(BuildContext context) {
    final isStrong = strength >= 3;
    final activeColor = isStrong ? AppColors.success : AppColors.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (index) {
            final filled = strength > index;
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: index == 3 ? 0 : 4),
                decoration: BoxDecoration(
                  color: filled ? activeColor : AppColors.neutreLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Text(
          isStrong
              ? 'Fort — 12 caractères, majuscules, chiffres ✓'
              : 'Moyen — 8+ caractères, majuscules, chiffres',
          style: TextStyle(fontSize: 11, color: activeColor, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _AgriTextField extends StatelessWidget {
  const _AgriTextField({
    required this.controller,
    required this.hintText,
    this.prefixIcon,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.suffix,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final bool obscureText;
  final Widget? suffix;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        obscureText: obscureText,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: prefixIcon == null
              ? null
              : Icon(prefixIcon, color: AppColors.neutreMedium, size: 18),
          suffixIcon: suffix,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
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
