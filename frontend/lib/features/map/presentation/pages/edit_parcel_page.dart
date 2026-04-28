import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/parcel_model.dart';
import '../../data/repositories/parcel_repository.dart';

class EditParcelPage extends StatefulWidget {
  final ParcelModel parcel;

  const EditParcelPage({
    Key? key,
    required this.parcel,
  }) : super(key: key);

  @override
  State<EditParcelPage> createState() => _EditParcelPageState();
}

class _EditParcelPageState extends State<EditParcelPage> {
  late TextEditingController nameController;
  late TextEditingController soilTypeController;
  late TextEditingController regionController;
  String? selectedCultureType;
  bool isLoading = false;

  final List<String> cultureTypes = [
    'Blé tendre',
    'Maïs',
    'Colza',
    'Orge',
    'Seigle',
  ];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.parcel.name);
    soilTypeController = TextEditingController(text: widget.parcel.soilType ?? '');
    regionController = TextEditingController(text: widget.parcel.region ?? '');
    selectedCultureType = widget.parcel.cultureType;
  }

  @override
  void dispose() {
    nameController.dispose();
    soilTypeController.dispose();
    regionController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le nom de la parcelle est requis')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await ParcelRepository.updateParcel(
        widget.parcel.id,
        name: nameController.text,
        cultureType: selectedCultureType ?? widget.parcel.cultureType,
        soilType: soilTypeController.text.isNotEmpty ? soilTypeController.text : null,
        region: regionController.text.isNotEmpty ? regionController.text : null,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Parcelle mise à jour avec succès')),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier la parcelle'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1C2B2D),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nom de la parcelle
            const Text(
              'Nom de la parcelle',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1C2B2D),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: 'Ex: Parcelle Nord',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Type de culture
            const Text(
              'Type de culture',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1C2B2D),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedCultureType,
              items: cultureTypes
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() => selectedCultureType = value);
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Type de sol
            const Text(
              'Type de sol (optionnel)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1C2B2D),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: soilTypeController,
              decoration: InputDecoration(
                hintText: 'Ex: Limon, Calcaire',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Région
            const Text(
              'Région (optionnel)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1C2B2D),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: regionController,
              decoration: InputDecoration(
                hintText: 'Ex: Beauce, Eure-et-Loir',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Info parcelle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF2E7D32).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informations de la parcelle',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2E7D32),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: 'Surface',
                    value: '${widget.parcel.areaHa} ha',
                  ),
                  const SizedBox(height: 4),
                  _InfoRow(
                    label: 'Créée le',
                    value:
                        '${widget.parcel.createdAt.day}/${widget.parcel.createdAt.month}/${widget.parcel.createdAt.year}',
                  ),
                  const SizedBox(height: 4),
                  _InfoRow(
                    label: 'Points',
                    value: '${widget.parcel.coordinates.length}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Enregistrer les modifications',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF2E7D32),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF2E7D32),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
