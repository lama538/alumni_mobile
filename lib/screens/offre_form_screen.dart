import 'package:flutter/material.dart';
import '../models/offre_model.dart';
import '../services/offre_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OffreFormScreen extends StatefulWidget {
  final String token;
  final Offre? existing;
  const OffreFormScreen({super.key, required this.token, this.existing});

  @override
  State<OffreFormScreen> createState() => _OffreFormScreenState();
}

class _OffreFormScreenState extends State<OffreFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController titreCtrl = TextEditingController();
  final TextEditingController descCtrl = TextEditingController();
  String type = 'emploi';
  DateTime? dateExp;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      titreCtrl.text = widget.existing!.titre;
      descCtrl.text = widget.existing!.description;
      type = widget.existing!.type;
      dateExp = widget.existing!.dateExpiration;
    }
  }

  void submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => loading = true);
    try {
      int? userId;

      if (widget.existing != null) {
        userId = widget.existing!.userId;
      } else {
        final prefs = await SharedPreferences.getInstance();
        userId = prefs.getInt('user_id');
      }

      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      final offre = Offre(
        id: widget.existing?.id ?? 0,
        userId: userId,
        titre: titreCtrl.text.trim(),
        description: descCtrl.text.trim(),
        type: type,
        dateExpiration: dateExp,
      );

      if (widget.existing == null) {
        await OffreService.create(widget.token, offre);
      } else {
        await OffreService.update(widget.token, widget.existing!.id, offre);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existing == null
                  ? 'Offre publiée avec succès !'
                  : 'Offre modifiée avec succès !',
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Erreur submit offre: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Erreur lors de l\'enregistrement'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      setState(() => loading = false);
    }
  }

  Future pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: dateExp ?? now,
      firstDate: now,
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2563EB),
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (d != null) setState(() => dateExp = d);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEdit ? 'Modifier l\'offre' : 'Publier une offre',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.lightbulb_outline_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Remplissez les informations pour publier votre offre',
                        style: TextStyle(
                          color: Color(0xFF1E40AF),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildInputField(
                label: 'Titre de l\'offre',
                icon: Icons.title_rounded,
                controller: titreCtrl,
                hint: 'Ex: Développeur Flutter Senior',
              ),
              const SizedBox(height: 20),
              _buildDescriptionField(),
              const SizedBox(height: 20),
              _buildTypeSelector(),
              const SizedBox(height: 20),
              _buildDatePicker(),
              const SizedBox(height: 32),
              _buildSubmitButton(isEdit),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
              prefixIcon: Icon(icon, color: const Color(0xFF2563EB)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Ce champ est requis' : null,
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description détaillée',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: descCtrl,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: 'Décrivez le poste, les missions, les compétences requises...',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(16),
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Ce champ est requis' : null,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Type d\'offre',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildTypeOption(
                'Emploi',
                'emploi',
                Icons.work_rounded,
                const Color(0xFF3B82F6),
                const Color(0xFFEFF6FF),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTypeOption(
                'Stage',
                'stage',
                Icons.school_rounded,
                const Color(0xFF8B5CF6),
                const Color(0xFFF5F3FF),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeOption(String label, String value, IconData icon, Color color, Color bg) {
    final isSelected = type == value;
    return InkWell(
      onTap: () => setState(() => type = value),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE2E8F0),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? color.withOpacity(0.2) : Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : color,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF0F172A),
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date d\'expiration (optionnelle)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: pickDate,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.calendar_today_rounded,
                    color: Color(0xFF2563EB),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    dateExp == null
                        ? 'Sélectionner une date'
                        : 'Expire le ${dateExp!.toLocal().toString().split(' ')[0]}',
                    style: TextStyle(
                      fontSize: 15,
                      color: dateExp == null ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                      fontWeight: dateExp == null ? FontWeight.w400 : FontWeight.w600,
                    ),
                  ),
                ),
                if (dateExp != null)
                  IconButton(
                    icon: const Icon(Icons.clear_rounded, color: Color(0xFF94A3B8)),
                    onPressed: () => setState(() => dateExp = null),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(bool isEdit) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: loading ? null : submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF94A3B8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: loading
            ? const SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 3,
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isEdit ? Icons.check_circle_outline_rounded : Icons.publish_rounded,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              isEdit ? 'Enregistrer les modifications' : 'Publier l\'offre',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}