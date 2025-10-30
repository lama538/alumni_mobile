import 'package:flutter/material.dart';
import '../models/offre_model.dart';
import '../services/offre_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'offre_form_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class OffreDetailScreen extends StatefulWidget {
  final String token;
  final Offre offre;

  const OffreDetailScreen({
    super.key,
    required this.token,
    required this.offre,
  });

  @override
  State<OffreDetailScreen> createState() => _OffreDetailScreenState();
}

class _OffreDetailScreenState extends State<OffreDetailScreen> {
  bool isApplying = false;
  bool alreadyApplied = false;

  @override
  void initState() {
    super.initState();
    checkAlreadyApplied();
  }

  void checkAlreadyApplied() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId != null) {
      final applied = await OffreService.hasApplied(widget.token, widget.offre.id, userId);
      setState(() {
        alreadyApplied = applied;
      });
    }
  }

  Future<String> getPublisherName() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getInt('user_id');
    final o = widget.offre;

    if (o.userId != null && o.userId == currentUserId) {
      return 'Vous';
    } else if (o.userName != null && o.userName!.isNotEmpty) {
      return o.userName!;
    } else if (o.userId != null) {
      return 'Utilisateur #${o.userId}';
    } else {
      return '—';
    }
  }

  Future<bool> canEditOffer() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getInt('user_id');
    final role = prefs.getString('role') ?? '';
    final isOwner = widget.offre.userId != null && widget.offre.userId == currentUserId;
    final canEditRole = role == 'admin' || role == 'alumni' || role == 'entreprise';
    return isOwner && canEditRole;
  }

  Future<bool> canApply() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('role') ?? '';
    return role == 'etudiant' || role == 'alumni';
  }

  void apply() async {
    if (alreadyApplied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vous avez déjà postulé à cette offre'),
          backgroundColor: Colors.orange[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final studentId = prefs.getInt('user_id');
    if (studentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez vous connecter'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final prenomCtrl = TextEditingController();
    final nomCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final telCtrl = TextEditingController();
    XFile? cvFile;

    final result = await showModalBottomSheet<bool?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.description_rounded,
                          color: Color(0xFF2563EB),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          "Candidature",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildModalTextField(prenomCtrl, 'Prénom', Icons.person_outline_rounded),
                  const SizedBox(height: 14),
                  _buildModalTextField(nomCtrl, 'Nom', Icons.person_outline_rounded),
                  const SizedBox(height: 14),
                  _buildModalTextField(emailCtrl, 'Email', Icons.email_outlined, TextInputType.emailAddress),
                  const SizedBox(height: 14),
                  _buildModalTextField(telCtrl, 'Téléphone', Icons.phone_outlined, TextInputType.phone),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.attach_file_rounded,
                              color: const Color(0xFF2563EB),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Document CV',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final pickerChoice = await showDialog<String>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      title: const Text('Type de fichier'),
                                      content: const Text('Choisissez le format de votre CV'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, 'pdf'),
                                          child: const Text('PDF'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, 'image'),
                                          child: const Text('Image'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (pickerChoice == null) return;

                                  if (pickerChoice == 'pdf') {
                                    final result = await FilePicker.platform.pickFiles(
                                      type: FileType.custom,
                                      allowedExtensions: ['pdf'],
                                    );
                                    if (result != null && result.files.single.path != null) {
                                      setModalState(() => cvFile = XFile(result.files.single.path!));
                                    }
                                  } else if (pickerChoice == 'image') {
                                    final imagePicker = ImagePicker();
                                    final pickedImage = await imagePicker.pickImage(source: ImageSource.gallery);
                                    if (pickedImage != null) {
                                      setModalState(() => cvFile = pickedImage);
                                    }
                                  }
                                },
                                icon: const Icon(Icons.upload_file_rounded),
                                label: const Text('Sélectionner'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF2563EB),
                                  side: const BorderSide(color: Color(0xFF2563EB)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (cvFile != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(0xFF2563EB),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    cvFile!.name,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF2563EB),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 18),
                                  onPressed: () => setModalState(() => cvFile = null),
                                  color: const Color(0xFF64748B),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (prenomCtrl.text.isEmpty ||
                            nomCtrl.text.isEmpty ||
                            emailCtrl.text.isEmpty ||
                            telCtrl.text.isEmpty ||
                            cvFile == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Veuillez remplir tous les champs'),
                              backgroundColor: Color(0xFFEF4444),
                            ),
                          );
                          return;
                        }
                        Navigator.pop(ctx, true);
                      },
                      icon: const Icon(Icons.send_rounded),
                      label: const Text(
                        'Envoyer ma candidature',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );

    if (result != true) return;

    setState(() => isApplying = true);
    try {
      await OffreService.applyWithForm(
        token: widget.token,
        offreId: widget.offre.id,
        studentId: studentId,
        prenom: prenomCtrl.text.trim(),
        nom: nomCtrl.text.trim(),
        email: emailCtrl.text.trim(),
        telephone: telCtrl.text.trim(),
        cvPath: cvFile!.path,
      );

      setState(() => alreadyApplied = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Candidature envoyée avec succès !'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      String message = 'Erreur lors de la candidature';
      if (e.toString().contains('Vous avez déjà postulé')) {
        message = 'Vous avez déjà postulé à cette offre';
        setState(() => alreadyApplied = true);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => isApplying = false);
    }
  }

  Widget _buildModalTextField(
      TextEditingController controller,
      String label,
      IconData icon, [
        TextInputType? keyboardType,
      ]) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF2563EB)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.offre;
    final isEmploi = o.type == 'emploi';
    final typeColor = isEmploi ? const Color(0xFF3B82F6) : const Color(0xFF8B5CF6);
    final typeBg = isEmploi ? const Color(0xFFEFF6FF) : const Color(0xFFF5F3FF);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Détails de l\'offre',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF2563EB),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isEmploi ? Icons.work_rounded : Icons.school_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          o.type.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    o.titre,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<String>(
                    future: getPublisherName(),
                    builder: (context, snapshot) {
                      final publisherName = snapshot.data ?? '—';
                      return Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              publisherName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  if (o.dateExpiration != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.schedule_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Expire le ${o.dateExpiration!.toLocal().toString().split(' ')[0]}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      o.description,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF475569),
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FutureBuilder<bool>(
                    future: canEditOffer(),
                    builder: (context, snapshot) {
                      final canEdit = snapshot.data ?? false;
                      if (!canEdit) return const SizedBox();

                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => OffreFormScreen(
                                          token: widget.token,
                                          existing: widget.offre,
                                        ),
                                      ),
                                    );
                                    if (result == true && mounted) {
                                      Navigator.pop(context, true);
                                    }
                                  },
                                  icon: const Icon(Icons.edit_rounded),
                                  label: const Text('Modifier'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF2563EB),
                                    side: const BorderSide(color: Color(0xFF2563EB), width: 2),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        title: const Text('Supprimer cette offre ?'),
                                        content: const Text('Cette action est irréversible.'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, false),
                                            child: const Text('Annuler'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, true),
                                            style: TextButton.styleFrom(
                                              foregroundColor: const Color(0xFFEF4444),
                                            ),
                                            child: const Text('Supprimer'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirmed == true) {
                                      await OffreService.delete(widget.token, widget.offre.id);
                                      if (mounted) Navigator.pop(context, true);
                                    }
                                  },
                                  icon: const Icon(Icons.delete_rounded),
                                  label: const Text('Supprimer'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFEF4444),
                                    side: const BorderSide(color: Color(0xFFEF4444), width: 2),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  ),
                  FutureBuilder<bool>(
                    future: canApply(),
                    builder: (context, snapshot) {
                      final showButton = snapshot.data ?? false;
                      if (!showButton) return const SizedBox();

                      return SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: (isApplying || alreadyApplied) ? null : apply,
                          icon: isApplying
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : Icon(
                            alreadyApplied
                                ? Icons.check_circle_rounded
                                : Icons.send_rounded,
                          ),
                          label: Text(
                            alreadyApplied ? 'Candidature envoyée' : 'Postuler maintenant',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: alreadyApplied
                                ? const Color(0xFF10B981)
                                : const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFF10B981),
                            disabledForegroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      );
                    },
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