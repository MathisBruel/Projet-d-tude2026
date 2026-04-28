import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:image_picker/image_picker.dart';
import 'package:agrisense/core/theme/app_theme.dart';
import 'package:agrisense/core/services/api_service.dart';
import 'package:agrisense/core/services/profile_image_service.dart';
import 'package:agrisense/core/config/app_config.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<ProfileViewData> _profileFuture;
  bool _isEditing = false;
  final _imagePicker = ImagePicker();
  File? _selectedProfileImage;

  // Formulaire fields
  late TextEditingController _firstNameCtrl;
  late TextEditingController _lastNameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _locationCtrl;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
    _firstNameCtrl = TextEditingController();
    _lastNameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _locationCtrl = TextEditingController();
  }

  Future<void> _pickAndUploadProfilePhoto() async {
    try {
      final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null && mounted) {
        final imageFile = File(pickedFile.path);
        setState(() {
          _selectedProfileImage = imageFile;
        });

        // Upload to backend
        final uploadResponse = await ApiService.uploadAvatar(imageFile);

        if (uploadResponse['error'] == null && mounted) {
          // Store the local image for display
          await ProfileImageService().setProfileImage(imageFile);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo de profil mise à jour ✓')),
          );
          // Reload profile to refresh the UI
          setState(() => _profileFuture = _loadProfile());
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: ${uploadResponse['error']}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<ProfileViewData> _loadProfile() async {
    final response = await ApiService.getProfile();
    if (response['error'] != null) {
      throw Exception(response['error']);
    }
    return ProfileViewData.fromJson(response);
  }

  Future<void> _saveProfile() async {
    final resp = await ApiService.updateProfile({
      'first_name': _firstNameCtrl.text,
      'last_name': _lastNameCtrl.text,
      'phone': _phoneCtrl.text,
      'location_name': _locationCtrl.text,
    });

    if (mounted) {
      if (resp['error'] == null) {
        setState(() {
          _isEditing = false;
          _profileFuture = _loadProfile();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour ✓')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${resp['error']}')),
        );
      }
    }
  }

  void _initEditFields(ProfileViewData data) {
    _firstNameCtrl.text = data.firstName;
    _lastNameCtrl.text = data.lastName;
    _phoneCtrl.text = data.phone;
    _locationCtrl.text = data.location;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<ProfileViewData>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_off, size: 48, color: AppColors.neutreMedium),
                    const SizedBox(height: 10),
                    Text(
                      'Profil indisponible',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => setState(() => _profileFuture = _loadProfile()),
                      child: const Text('Reessayer'),
                    ),
                  ],
                ),
              );
            }

            final data = snapshot.data!;
            if (_isEditing && _firstNameCtrl.text.isEmpty) {
              _initEditFields(data);
            }
            return SingleChildScrollView(
              child: Column(
                children: [
                  _HeaderCard(
                    onBack: () => context.go('/home'),
                    onSettings: _isEditing
                        ? () => setState(() => _isEditing = false)
                        : () => setState(() => _isEditing = true),
                    onAvatarTap: _pickAndUploadProfilePhoto,
                    name: data.name,
                    role: data.roleLabel,
                    location: data.location,
                    badgeLabel: data.badgeLabel,
                    initials: data.initials,
                    isEditing: _isEditing,
                    profileImage: _selectedProfileImage,
                    avatarUrl: data.avatarUrl,
                  ),
                  _isEditing
                      ? _EditProfileForm(
                          firstNameCtrl: _firstNameCtrl,
                          lastNameCtrl: _lastNameCtrl,
                          phoneCtrl: _phoneCtrl,
                          locationCtrl: _locationCtrl,
                          onSave: _saveProfile,
                          onCancel: () => setState(() => _isEditing = false),
                        )
                      : Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          const _SectionTitle('Mon exploitation'),
                          const SizedBox(height: 8),
                          _FarmStatsCard(
                            parcels: data.parcelsCount,
                            areaHa: data.totalAreaHa,
                            mainCrop: data.mainCrop,
                            onTap: () => _showSnack('Stats exploitation'),
                          ),
                          const SizedBox(height: 18),
                          const _SectionTitle('Mes statistiques'),
                          const SizedBox(height: 8),
                          _StatsCard(
                            predictionsCount: data.predictionsCount,
                            avgYield: data.avgYield,
                            bestParcel: data.bestParcelLabel,
                            bestYield: data.bestParcelYield,
                            onTap: (label) => _showSnack(label),
                          ),
                          const SizedBox(height: 16),
                          _ActionTile(
                            icon: Icons.edit_outlined,
                            title: 'Modifier mes informations',
                            onTap: () => setState(() => _isEditing = true),
                          ),
                          const SizedBox(height: 10),
                          _ActionTile(
                            icon: Icons.notifications_none,
                            title: 'Notifications',
                            trailing: data.notificationsLabel,
                            onTap: () => _showSnack('Notifications'),
                          ),
                        ],
                          ),
                        ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.onBack,
    required this.onSettings,
    required this.onAvatarTap,
    required this.name,
    required this.role,
    required this.location,
    required this.badgeLabel,
    required this.initials,
    this.isEditing = false,
    this.profileImage,
    this.avatarUrl,
  });

  final VoidCallback onBack;
  final VoidCallback onSettings;
  final VoidCallback onAvatarTap;
  final String name;
  final String role;
  final String location;
  final String badgeLabel;
  final String initials;
  final bool isEditing;
  final File? profileImage;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(24),
        bottomRight: Radius.circular(24),
      ),
      child: Container(
          height: 240,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF2E7D32),
                Color(0xFF1F5F26),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                left: -30,
                right: -30,
                bottom: -40,
                child: Container(
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                top: 12,
                child: _HeaderIconButton(
                  icon: Icons.arrow_back,
                  onTap: onBack,
                ),
              ),
              Positioned(
                right: 12,
                top: 12,
                child: _HeaderIconButton(
                  icon: isEditing ? Icons.close : Icons.settings,
                  onTap: onSettings,
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: onAvatarTap,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 46,
                            backgroundColor: Colors.white,
                            backgroundImage: avatarUrl != null
                                ? NetworkImage('${AppConfig.apiUrl}$avatarUrl') as ImageProvider<Object>
                                : (profileImage != null
                                    ? FileImage(profileImage!) as ImageProvider<Object>
                                    : null),
                            child: (avatarUrl == null && profileImage == null)
                                ? Text(
                                    initials,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1C2B2D),
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E7D32),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$role · $location',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const _StatusDot(),
                          const SizedBox(width: 6),
                          Text(
                            badgeLabel,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: Color(0xFFF9A825),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.neutreDark,
          ),
    );
  }
}

class _FarmStatsCard extends StatelessWidget {
  const _FarmStatsCard({
    required this.parcels,
    required this.areaHa,
    required this.mainCrop,
    required this.onTap,
  });

  final String parcels;
  final String areaHa;
  final String mainCrop;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 12,
              offset: Offset(0, 6),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _MetricItem(value: parcels, label: 'PARCELLES'),
            _MetricItem(value: areaHa, label: 'HA TOTAL'),
            _MetricItem(value: mainCrop, label: '', icon: Icons.agriculture_rounded),
          ],
        ),
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({required this.value, required this.label, this.icon});

  final String value;
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isText = label.isEmpty;
    return Column(
      children: [
        if (icon != null)
          Icon(icon, size: 18, color: AppColors.secondary),
        if (icon != null)
          const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isText ? 12 : 18,
            fontWeight: FontWeight.w700,
            color: isText ? AppColors.primary : AppColors.primary,
          ),
        ),
        if (!isText)
          const SizedBox(height: 4),
        if (!isText)
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.neutreMedium,
            ),
          ),
      ],
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.predictionsCount,
    required this.avgYield,
    required this.bestParcel,
    required this.bestYield,
    required this.onTap,
  });

  final String predictionsCount;
  final String avgYield;
  final String bestParcel;
  final String bestYield;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          )
        ],
      ),
      child: Column(
        children: [
          _StatRow(
            icon: Icons.monitor_heart_outlined,
            title: 'Predictions lancees',
            value: predictionsCount,
            subtitle: 'cette saison',
            onTap: () => onTap('Predictions'),
          ),
          const SizedBox(height: 12),
          _StatRow(
            icon: Icons.bar_chart_rounded,
            title: 'Rendement moyen',
            value: avgYield,
            subtitle: 'moyenne recent',
            onTap: () => onTap('Rendement'),
          ),
          const SizedBox(height: 12),
          _StatRow(
            icon: Icons.emoji_events_outlined,
            title: 'Meilleure parcelle',
            value: bestParcel,
            subtitle: bestYield,
            onTap: () => onTap('Meilleure parcelle'),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.neutreLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutreMedium,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.neutreDark,
                  ),
                ),
              ],
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.neutreMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.title, required this.onTap, this.trailing});

  final IconData icon;
  final String title;
  final String? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 12,
              offset: Offset(0, 6),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.neutreLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.neutreDark, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.neutreDark,
                ),
              ),
            ),
            if (trailing != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  trailing!,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutreMedium,
                  ),
                ),
              ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.neutreMedium),
          ],
        ),
      ),
    );
  }
}

class _EditProfileForm extends StatelessWidget {
  const _EditProfileForm({
    required this.firstNameCtrl,
    required this.lastNameCtrl,
    required this.phoneCtrl,
    required this.locationCtrl,
    required this.onSave,
    required this.onCancel,
  });

  final TextEditingController firstNameCtrl;
  final TextEditingController lastNameCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController locationCtrl;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Informations personnelles'),
          const SizedBox(height: 12),
          _EditTextField(
            label: 'Prénom',
            controller: firstNameCtrl,
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 10),
          _EditTextField(
            label: 'Nom',
            controller: lastNameCtrl,
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 10),
          _EditTextField(
            label: 'Téléphone',
            controller: phoneCtrl,
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 18),
          const _SectionTitle('Localisation'),
          const SizedBox(height: 12),
          _EditTextField(
            label: 'Adresse / Région',
            controller: locationCtrl,
            icon: Icons.location_on_outlined,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Annuler'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onSave,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Enregistrer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EditTextField extends StatelessWidget {
  const _EditTextField({
    required this.label,
    required this.controller,
    required this.icon,
    this.keyboardType = TextInputType.text,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          label: Text(label),
          labelStyle: const TextStyle(
            color: AppColors.neutreMedium,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icon, color: AppColors.primary, size: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
        style: const TextStyle(
          color: AppColors.neutreDark,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class ProfileViewData {
  final String name;
  final String initials;
  final String roleLabel;
  final String location;
  final String badgeLabel;
  final String parcelsCount;
  final String totalAreaHa;
  final String mainCrop;
  final String predictionsCount;
  final String avgYield;
  final String bestParcelLabel;
  final String bestParcelYield;
  final String notificationsLabel;
  final String firstName;
  final String lastName;
  final String phone;
  final String? avatarUrl;

  ProfileViewData({
    required this.name,
    required this.initials,
    required this.roleLabel,
    required this.location,
    required this.badgeLabel,
    required this.parcelsCount,
    required this.totalAreaHa,
    required this.mainCrop,
    required this.predictionsCount,
    required this.avgYield,
    required this.bestParcelLabel,
    required this.bestParcelYield,
    required this.notificationsLabel,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.avatarUrl,
  });

  factory ProfileViewData.fromJson(Map<String, dynamic> json) {
    final profile = (json['profile'] as Map<String, dynamic>?) ?? {};
    final stats = (json['stats'] as Map<String, dynamic>?) ?? {};

    final firstName = (profile['first_name'] as String?) ?? '';
    final lastName = (profile['last_name'] as String?) ?? '';
    final phone = (profile['phone'] as String?) ?? '';
    final fullName = '${firstName.trim()} ${lastName.trim()}'.trim();
    final name = fullName.isEmpty ? 'Utilisateur' : fullName;
    final initials = _initialsFromName(name);

    final roleLabel = _roleLabel(profile['role'] as String?);
    final location = (stats['region'] as String?) ?? 'France';
    final parcelsCount = '${stats['parcels_count'] ?? 0}';
    final totalArea = stats['total_area_ha'];
    final totalAreaHa = totalArea == null ? '0' : totalArea.toString();
    final mainCrop = (stats['main_crop'] as String?) ?? 'Non renseigne';

    final predictionsCount = '${stats['predictions_count'] ?? 0}';
    final avgYield = stats['avg_yield_t_ha'] == null
        ? '0 t/ha'
        : '${stats['avg_yield_t_ha']} t/ha';
    final bestParcel = (stats['best_parcel_name'] as String?) ?? 'Aucune';
    final bestYield = stats['best_parcel_yield_t_ha'] == null
        ? '0 t/ha'
        : '${stats['best_parcel_yield_t_ha']} t/ha';

    final notificationsCount = stats['notifications_unread'] ?? 0;
    final notificationsLabel = '$notificationsCount actives';
    final avatarUrl = (profile['avatar_url'] as String?);

    return ProfileViewData(
      name: name,
      initials: initials,
      roleLabel: roleLabel,
      location: location,
      badgeLabel: 'MEMBRE PREMIUM · depuis 2023',
      parcelsCount: parcelsCount,
      totalAreaHa: totalAreaHa,
      mainCrop: mainCrop,
      predictionsCount: predictionsCount,
      avgYield: avgYield,
      bestParcelLabel: bestParcel,
      bestParcelYield: bestYield,
      notificationsLabel: notificationsLabel,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      avatarUrl: avatarUrl,
    );
  }
}

String _roleLabel(String? role) {
  switch (role) {
    case 'agronomist':
      return 'Agronome';
    case 'admin':
      return 'Admin';
    case 'farmer':
    default:
      return 'Agriculteur';
  }
}

String _initialsFromName(String name) {
  final parts = name.trim().split(' ');
  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }
  final first = parts.first.isNotEmpty ? parts.first[0] : '';
  final last = parts.last.isNotEmpty ? parts.last[0] : '';
  return (first + last).toUpperCase();
}
