import 'package:flutter/material.dart';
import '../../data/models/parcel_model.dart';
import '../../data/repositories/parcel_repository.dart';

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
                      onPressed: () {
                        Navigator.pop(context);
                        // context.go('/map/edit/${widget.parcel.id}');
                      },
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
