import 'package:flutter/material.dart';
import '../../data/models/parcel_model.dart';
import '../../data/repositories/parcel_repository.dart';

const _kCultures = [
  'Blé tendre', 'Blé dur', 'Maïs', 'Colza', 'Orge',
  'Tournesol', 'Pomme de terre', 'Betterave', 'Tournesol', 'Sorgho',
];

const _kSoilTypes = ['Argileux', 'Limoneux', 'Sableux', 'Calcaire', 'Humifère'];

class ParcelBottomSheet extends StatefulWidget {
  final ParcelModel parcel;
  final VoidCallback onParcelUpdated;

  const ParcelBottomSheet({
    Key? key,
    required this.parcel,
    required this.onParcelUpdated,
  }) : super(key: key);

  @override
  State<ParcelBottomSheet> createState() => _ParcelBottomSheetState();
}

class _ParcelBottomSheetState extends State<ParcelBottomSheet> {
  bool isDeleting = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECEFF1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),

              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.parcel.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                            color: Color(0xFF1C2B2D),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Créée le ${widget.parcel.createdAt.day}/${widget.parcel.createdAt.month}/${widget.parcel.createdAt.year}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF546E7A),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: const Color(0xFF2E7D32).withOpacity(0.3),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      'Optimal',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF388E3C),
                        letterSpacing: -0.1,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Tags
              Wrap(
                spacing: 6,
                children: [
                  _ChipTag(
                    icon: '🌾',
                    label: widget.parcel.cultureType,
                    color: 'primary',
                  ),
                  _ChipTag(
                    icon: '📏',
                    label: '${widget.parcel.areaHa} ha',
                    color: 'neutral',
                  ),
                  if (widget.parcel.region != null)
                    _ChipTag(
                      icon: '📍',
                      label: widget.parcel.region!,
                      color: 'neutral',
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Mini weather grid
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  children: [
                    _WeatherCell(icon: '🌡️', value: '18°', label: 'Temp'),
                    _WeatherCell(icon: '🌧️', value: '12mm', label: 'Pluie'),
                    _WeatherCell(icon: '💧', value: '65%', label: 'Humid.'),
                    _WeatherCell(icon: '💨', value: '15', label: 'km/h'),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Last prediction (if available)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFF2E7D32).withOpacity(0.2),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.flash_on,
                        color: Color(0xFF2E7D32),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DERNIÈRE PRÉDICTION • il y a 2h',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF546E7A),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: const [
                              Text(
                                '7.2',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2E7D32),
                                  letterSpacing: -0.6,
                                ),
                              ),
                              SizedBox(width: 3),
                              Text(
                                't/ha',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF546E7A),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '78%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.flash_on,
                      label: 'Nouvelle\nprédiction',
                      onPressed: () {
                        Navigator.pop(context);
                        // context.go('/predict/${widget.parcel.id}');
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.edit,
                      label: 'Modifier',
                      onPressed: () => _openEditSheet(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.delete,
                      label: 'Supprimer',
                      isDanger: true,
                      onPressed: _deleteParcel,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _ParcelEditSheet(
        parcel: widget.parcel,
        onSaved: () {
          Navigator.pop(context); // ferme le bottom sheet de détail
          widget.onParcelUpdated();
        },
      ),
    );
  }

  Future<void> _deleteParcel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer la parcelle "${widget.parcel.name}" ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => isDeleting = true);
    try {
      await ParcelRepository.deleteParcel(widget.parcel.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Parcelle supprimée')),
        );
        widget.onParcelUpdated();
      }
    } catch (e) {
      setState(() => isDeleting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : ${e.toString()}')),
        );
      }
    }
  }
}

class _ChipTag extends StatelessWidget {
  final String icon;
  final String label;
  final String color;

  const _ChipTag({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    switch (color) {
      case 'primary':
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        break;
      case 'amber':
        bgColor = const Color(0xFFFFF8E1);
        textColor = const Color(0xFFC77800);
        break;
      default:
        bgColor = const Color(0xFFECEFF1);
        textColor = const Color(0xFF546E7A);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$icon $label',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
          letterSpacing: -0.1,
        ),
      ),
    );
  }
}

class _WeatherCell extends StatelessWidget {
  final String icon;
  final String value;
  final String label;

  const _WeatherCell({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2E7D32),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            color: Color(0xFF546E7A),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isDanger;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDanger ? const Color(0xFFFDECEC) : Colors.white;
    final textColor = isDanger ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32);
    final borderColor = isDanger
        ? const Color(0xFFD32F2F).withOpacity(0.2)
        : const Color(0xFF2E7D32).withOpacity(0.15);

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: textColor, size: 18),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: textColor,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Formulaire d'édition d'une parcelle
// ─────────────────────────────────────────────────────────────────────────────

class _ParcelEditSheet extends StatefulWidget {
  final ParcelModel parcel;
  final VoidCallback onSaved;

  const _ParcelEditSheet({required this.parcel, required this.onSaved});

  @override
  State<_ParcelEditSheet> createState() => _ParcelEditSheetState();
}

class _ParcelEditSheetState extends State<_ParcelEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _regionCtrl;
  late String? _selectedCulture;
  late String? _selectedSoil;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl    = TextEditingController(text: widget.parcel.name);
    _regionCtrl  = TextEditingController(text: widget.parcel.region ?? '');
    _selectedCulture = _kCultures.contains(widget.parcel.cultureType)
        ? widget.parcel.cultureType
        : null;
    _selectedSoil = _kSoilTypes.contains(widget.parcel.soilType)
        ? widget.parcel.soilType
        : null;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _regionCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await ParcelRepository.updateParcel(
        widget.parcel.id,
        name: _nameCtrl.text.trim(),
        cultureType: _selectedCulture,
        soilType: _selectedSoil,
        region: _regionCtrl.text.trim().isEmpty ? null : _regionCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Parcelle mise à jour')),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 48, height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECEFF1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const Text(
                  'Modifier la parcelle',
                  style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w700,
                    color: Color(0xFF1C2B2D), letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 20),

                // Nom
                _FieldLabel('Nom de la parcelle'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: _inputDeco('Ex : Champ Nord'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                ),
                const SizedBox(height: 16),

                // Type de culture
                _FieldLabel('Type de culture'),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedCulture,
                  decoration: _inputDeco('Sélectionner une culture'),
                  items: _kCultures.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => _selectedCulture = v),
                ),
                const SizedBox(height: 16),

                // Type de sol
                _FieldLabel('Type de sol (optionnel)'),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedSoil,
                  decoration: _inputDeco('Sélectionner un type de sol'),
                  items: _kSoilTypes.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setState(() => _selectedSoil = v),
                ),
                const SizedBox(height: 16),

                // Région
                _FieldLabel('Région (optionnel)'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _regionCtrl,
                  decoration: _inputDeco('Ex : Île-de-France'),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Enregistrer',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF90A4AE), fontSize: 14),
    filled: true,
    fillColor: const Color(0xFFF5F7F8),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
    ),
  );
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1C2B2D),
      ),
    );
  }
}
