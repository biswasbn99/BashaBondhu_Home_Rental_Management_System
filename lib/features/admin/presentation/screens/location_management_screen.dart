import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../data/providers/admin_provider.dart';
import '../../../shared/data/models/division_model.dart';
import '../../../shared/data/models/district_model.dart';
import '../../../shared/data/repository/location_repository.dart';

class LocationManagementView extends StatefulWidget {
  const LocationManagementView({super.key});

  @override
  State<LocationManagementView> createState() => _LocationManagementViewState();
}

class _LocationManagementViewState extends State<LocationManagementView> {
  final LocationRepository _repository = LocationRepository();

  bool _isLoading = true;
  bool _isSaving = false;

  List<DivisionModel> _divisions = [];
  DivisionModel? _selectedDivision;
  List<DistrictModel> _districts = [];
  DistrictModel? _selectedDistrict;

  // Raw active division data map from Firestore
  Map<String, dynamic>? _activeDivisionMap;

  // Selected Area ID for viewing its sub-areas
  String? _selectedAreaId;
  final TextEditingController _areaSearchController = TextEditingController();
  final TextEditingController _subAreaSearchController = TextEditingController();
  String _areaSearchQuery = '';
  String _subAreaSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _areaSearchController.dispose();
    _subAreaSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      _divisions = await _repository.getDivisions(forceRefresh: true);
      if (_divisions.isNotEmpty) {
        _selectedDivision = _divisions.first;
        await _loadDivisionDetails(_selectedDivision!.id);
      }
    } catch (e) {
      _showSnackbar('Error loading divisions: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDivisionDetails(String divisionId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('locations').doc(divisionId.toLowerCase()).get();
      if (doc.exists && doc.data() != null) {
        _activeDivisionMap = doc.data()!;
        _districts = await _repository.getDistrictsByDivision(divisionId);
        if (_districts.isNotEmpty) {
          _selectedDistrict = _districts.first;
          final areas = _getCurrentAreas();
          _selectedAreaId = areas.isNotEmpty ? areas.first['id']?.toString() : null;
        } else {
          _selectedDistrict = null;
          _selectedAreaId = null;
        }
      }
    } catch (e) {
      _showSnackbar('Error loading division details: $e', isError: true);
    }
  }

  List<Map<String, dynamic>> _getCurrentAreas() {
    if (_activeDivisionMap == null || _selectedDistrict == null) return [];
    final districtsRaw = _activeDivisionMap!['districts'];
    if (districtsRaw is! List) return [];

    for (final d in districtsRaw) {
      if ((d['id']?.toString() ?? '').toLowerCase() == _selectedDistrict!.id.toLowerCase()) {
        final areasRaw = d['areas'];
        if (areasRaw is List) {
          return areasRaw.map((a) => Map<String, dynamic>.from(a as Map)).toList();
        }
      }
    }
    return [];
  }

  List<Map<String, dynamic>> _getCurrentSubAreas() {
    if (_selectedAreaId == null) return [];
    final areas = _getCurrentAreas();
    for (final a in areas) {
      if ((a['id']?.toString() ?? '').toLowerCase() == _selectedAreaId!.toLowerCase()) {
        final subAreasRaw = a['sub_areas'];
        if (subAreasRaw is List) {
          return subAreasRaw.map((sa) => Map<String, dynamic>.from(sa as Map)).toList();
        }
      }
    }
    return [];
  }

  Future<void> _saveDivisionToFirestore({bool isBn = false}) async {
    if (_selectedDivision == null || _activeDivisionMap == null) return;
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('locations')
          .doc(_selectedDivision!.id.toLowerCase())
          .set(_activeDivisionMap!);

      _repository.clearCache();
      _showSnackbar(isBn ? '✅ সফলভাবে পরিবর্তন সংরক্ষিত হয়েছে!' : '✅ Changes successfully saved to Firestore!');
    } catch (e) {
      _showSnackbar(isBn ? '❌ সংরক্ষণ ব্যর্থ হয়েছে: $e' : '❌ Failed to save changes: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // --- Add / Edit Dialogs ---

  void _showAddOrEditAreaDialog({Map<String, dynamic>? existingArea, required bool isBn, required bool isDark}) {
    final isEdit = existingArea != null;
    final idController = TextEditingController(text: existingArea?['id'] ?? '');
    final nameEnController = TextEditingController(text: existingArea?['name_en'] ?? '');
    final nameBnController = TextEditingController(text: existingArea?['name_bn'] ?? '');
    final formKey = GlobalKey<FormState>();

    final cardBg = isDark ? const Color(0xFF112320) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final inputFill = isDark ? const Color(0xFF0B1917) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF1F3D37) : const Color(0xFFE2E8F0);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: cardBg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: borderColor, width: 1.2),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dialog Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.themeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isEdit ? Icons.edit_location_alt_rounded : Icons.add_location_alt_rounded,
                          color: AppColors.themeColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEdit
                                  ? (isBn ? 'এরিয়া / উপজেলা সম্পাদনা' : 'Edit Area / Upazila')
                                  : (isBn ? 'নতুন এরিয়া / উপজেলা যোগ করুন' : 'Add New Area / Upazila'),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _selectedDistrict != null
                                  ? '${isBn ? 'জেলা' : 'District'}: ${_selectedDistrict!.name} (${_selectedDistrict!.bnName})'
                                  : '',
                              style: TextStyle(fontSize: 12, color: textSecondary),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: textSecondary, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Divider(color: borderColor, height: 1),
                  const SizedBox(height: 20),

                  // Area ID field (only when creating new)
                  if (!isEdit) ...[
                    _buildFormLabel(isBn ? 'এরিয়া আইডি (Area ID)' : 'Area ID', textPrimary),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: idController,
                      style: TextStyle(color: textPrimary, fontSize: 14),
                      decoration: _buildInputDecoration(
                        hintText: isBn ? 'যেমন: mirpur, uttara, gulshan' : 'e.g. mirpur, uttara, gulshan',
                        prefixIcon: Icons.tag_rounded,
                        inputFill: inputFill,
                        borderColor: borderColor,
                        isDark: isDark,
                        helperText: isBn ? 'ছোট হাতের অক্ষর ও স্পেস ছাড়া লিখুন' : 'Lowercase letters and underscores only',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return isBn ? 'এরিয়া আইডি দিন' : 'Please enter Area ID';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                  ],

                  // English Name field
                  _buildFormLabel(isBn ? 'এরিয়ার নাম (ইংরেজিতে)' : 'Area Name (in English)', textPrimary),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: nameEnController,
                    style: TextStyle(color: textPrimary, fontSize: 14),
                    decoration: _buildInputDecoration(
                      hintText: isBn ? 'যেমন: Mirpur, Uttara' : 'e.g. Mirpur, Uttara',
                      prefixIcon: Icons.language_rounded,
                      inputFill: inputFill,
                      borderColor: borderColor,
                      isDark: isDark,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return isBn ? 'ইংরেজিতে নাম লিখুন' : 'Please enter English name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  // Bengali Name field
                  _buildFormLabel(isBn ? 'এরিয়ার নাম (বাংলায়)' : 'Area Name (in Bengali)', textPrimary),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: nameBnController,
                    style: TextStyle(color: textPrimary, fontSize: 14),
                    decoration: _buildInputDecoration(
                      hintText: isBn ? 'যেমন: মিরপুর, উত্তরা' : 'e.g. মিরপুর, উত্তরা',
                      prefixIcon: Icons.translate_rounded,
                      inputFill: inputFill,
                      borderColor: borderColor,
                      isDark: isDark,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return isBn ? 'বাংলায় নাম লিখুন' : 'Please enter Bengali name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Dialog Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textSecondary,
                          side: BorderSide(color: borderColor),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(isBn ? 'বাতিল' : 'Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.themeColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        icon: Icon(isEdit ? Icons.check_rounded : Icons.add_rounded, size: 18),
                        label: Text(
                          isEdit
                              ? (isBn ? 'আপডেট করুন' : 'Update Area')
                              : (isBn ? 'যোগ করুন' : 'Add Area'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          if (formKey.currentState?.validate() ?? false) {
                            final id = isEdit
                                ? existingArea['id']
                                : idController.text.trim().toLowerCase().replaceAll(' ', '_');
                            final nameEn = nameEnController.text.trim();
                            final nameBn = nameBnController.text.trim();

                            Navigator.pop(ctx);
                            _performAddOrEditArea(
                              id: id,
                              nameEn: nameEn,
                              nameBn: nameBn,
                              isEdit: isEdit,
                              isBn: isBn,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _performAddOrEditArea({
    required String id,
    required String nameEn,
    required String nameBn,
    required bool isEdit,
    required bool isBn,
  }) {
    if (_activeDivisionMap == null || _selectedDistrict == null) return;
    final districtsRaw = _activeDivisionMap!['districts'] as List;

    for (int i = 0; i < districtsRaw.length; i++) {
      if ((districtsRaw[i]['id']?.toString() ?? '').toLowerCase() == _selectedDistrict!.id.toLowerCase()) {
        final List areasList = List.from(districtsRaw[i]['areas'] ?? []);
        if (isEdit) {
          for (int j = 0; j < areasList.length; j++) {
            if (areasList[j]['id'] == id) {
              areasList[j]['name_en'] = nameEn;
              areasList[j]['name_bn'] = nameBn;
              break;
            }
          }
        } else {
          areasList.add({
            'id': id,
            'name_en': nameEn,
            'name_bn': nameBn,
            'sub_areas': [],
          });
          _selectedAreaId = id;
        }
        districtsRaw[i]['areas'] = areasList;
        break;
      }
    }

    setState(() {});
    _saveDivisionToFirestore(isBn: isBn);
  }

  void _deleteArea(String areaId, String areaName, {required bool isBn, required bool isDark}) {
    final cardBg = isDark ? const Color(0xFF112320) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF1F3D37) : const Color(0xFFE2E8F0);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: cardBg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: borderColor, width: 1.2),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                isBn ? 'এরিয়া ডিলিট করবেন?' : 'Delete Area?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
              ),
              const SizedBox(height: 10),
              Text(
                isBn
                    ? 'আপনি কি নিশ্চিত যে "$areaName" এরিয়া এবং এর অধীনে থাকা সকল সাব-এরিয়া মুছে ফেলতে চান?'
                    : 'Are you sure you want to delete "$areaName" and all associated sub-areas?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, color: textSecondary, height: 1.4),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textSecondary,
                      side: BorderSide(color: borderColor),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(isBn ? 'বাতিল' : 'Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      if (_activeDivisionMap == null || _selectedDistrict == null) return;
                      final districtsRaw = _activeDivisionMap!['districts'] as List;

                      for (int i = 0; i < districtsRaw.length; i++) {
                        if ((districtsRaw[i]['id']?.toString() ?? '').toLowerCase() == _selectedDistrict!.id.toLowerCase()) {
                          final List areasList = List.from(districtsRaw[i]['areas'] ?? []);
                          areasList.removeWhere((a) => a['id'] == areaId);
                          districtsRaw[i]['areas'] = areasList;
                          break;
                        }
                      }
                      if (_selectedAreaId == areaId) {
                        final remaining = _getCurrentAreas();
                        _selectedAreaId = remaining.isNotEmpty ? remaining.first['id'] : null;
                      }
                      setState(() {});
                      _saveDivisionToFirestore(isBn: isBn);
                    },
                    child: Text(isBn ? 'ডিলিট করুন' : 'Delete'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddOrEditSubAreaDialog({Map<String, dynamic>? existingSubArea, required bool isBn, required bool isDark}) {
    if (_selectedAreaId == null) {
      _showSnackbar(
        isBn ? 'প্রথমে একটি এরিয়া নির্বাচন করুন' : 'Please select an Area first',
        isError: true,
      );
      return;
    }
    final isEdit = existingSubArea != null;
    final idController = TextEditingController(text: existingSubArea?['id'] ?? '');
    final nameEnController = TextEditingController(text: existingSubArea?['name_en'] ?? '');
    final nameBnController = TextEditingController(text: existingSubArea?['name_bn'] ?? '');
    final formKey = GlobalKey<FormState>();

    final cardBg = isDark ? const Color(0xFF112320) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final inputFill = isDark ? const Color(0xFF0B1917) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF1F3D37) : const Color(0xFFE2E8F0);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: cardBg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: borderColor, width: 1.2),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dialog Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.teal.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isEdit ? Icons.edit_road_rounded : Icons.add_road_rounded,
                          color: Colors.tealAccent.shade700,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEdit
                                  ? (isBn ? 'সাব-এরিয়া / ইউনিয়ন সম্পাদনা' : 'Edit Sub-Area / Union')
                                  : (isBn ? 'নতুন সাব-এরিয়া / ইউনিয়ন যোগ করুন' : 'Add New Sub-Area / Union'),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${isBn ? 'এরিয়া' : 'Area'}: $_selectedAreaId',
                              style: TextStyle(fontSize: 12, color: textSecondary),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: textSecondary, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Divider(color: borderColor, height: 1),
                  const SizedBox(height: 20),

                  // Sub-Area ID (when creating)
                  if (!isEdit) ...[
                    _buildFormLabel(isBn ? 'সাব-এরিয়া আইডি (Sub-Area ID)' : 'Sub-Area ID', textPrimary),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: idController,
                      style: TextStyle(color: textPrimary, fontSize: 14),
                      decoration: _buildInputDecoration(
                        hintText: isBn ? 'যেমন: sector_1, block_c' : 'e.g. sector_1, block_c',
                        prefixIcon: Icons.tag_rounded,
                        inputFill: inputFill,
                        borderColor: borderColor,
                        isDark: isDark,
                        helperText: isBn ? 'ছোট হাতের অক্ষর ও আন্ডারস্কোর ব্যবহার করুন' : 'Lowercase letters and underscores only',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return isBn ? 'সাব-এরিয়া আইডি দিন' : 'Please enter Sub-Area ID';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                  ],

                  // English Name field
                  _buildFormLabel(isBn ? 'সাব-এরিয়ার নাম (ইংরেজিতে)' : 'Sub-Area Name (in English)', textPrimary),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: nameEnController,
                    style: TextStyle(color: textPrimary, fontSize: 14),
                    decoration: _buildInputDecoration(
                      hintText: isBn ? 'যেমন: Sector 1, Block C' : 'e.g. Sector 1, Block C',
                      prefixIcon: Icons.language_rounded,
                      inputFill: inputFill,
                      borderColor: borderColor,
                      isDark: isDark,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return isBn ? 'ইংরেজিতে নাম লিখুন' : 'Please enter English name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  // Bengali Name field
                  _buildFormLabel(isBn ? 'সাব-এরিয়ার নাম (বাংলায়)' : 'Sub-Area Name (in Bengali)', textPrimary),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: nameBnController,
                    style: TextStyle(color: textPrimary, fontSize: 14),
                    decoration: _buildInputDecoration(
                      hintText: isBn ? 'যেমন: সেক্টর ১, ব্লক সি' : 'e.g. সেক্টর ১, ব্লক সি',
                      prefixIcon: Icons.translate_rounded,
                      inputFill: inputFill,
                      borderColor: borderColor,
                      isDark: isDark,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return isBn ? 'বাংলায় নাম লিখুন' : 'Please enter Bengali name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Dialog Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textSecondary,
                          side: BorderSide(color: borderColor),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(isBn ? 'বাতিল' : 'Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        icon: Icon(isEdit ? Icons.check_rounded : Icons.add_rounded, size: 18),
                        label: Text(
                          isEdit
                              ? (isBn ? 'আপডেট করুন' : 'Update Sub-Area')
                              : (isBn ? 'যোগ করুন' : 'Add Sub-Area'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          if (formKey.currentState?.validate() ?? false) {
                            final id = isEdit
                                ? existingSubArea['id']
                                : idController.text.trim().toLowerCase().replaceAll(' ', '_');
                            final nameEn = nameEnController.text.trim();
                            final nameBn = nameBnController.text.trim();

                            Navigator.pop(ctx);
                            _performAddOrEditSubArea(
                              id: id,
                              nameEn: nameEn,
                              nameBn: nameBn,
                              isEdit: isEdit,
                              isBn: isBn,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _performAddOrEditSubArea({
    required String id,
    required String nameEn,
    required String nameBn,
    required bool isEdit,
    required bool isBn,
  }) {
    if (_activeDivisionMap == null || _selectedDistrict == null || _selectedAreaId == null) return;
    final districtsRaw = _activeDivisionMap!['districts'] as List;

    for (int i = 0; i < districtsRaw.length; i++) {
      if ((districtsRaw[i]['id']?.toString() ?? '').toLowerCase() == _selectedDistrict!.id.toLowerCase()) {
        final List areasList = List.from(districtsRaw[i]['areas'] ?? []);
        for (int j = 0; j < areasList.length; j++) {
          if ((areasList[j]['id']?.toString() ?? '').toLowerCase() == _selectedAreaId!.toLowerCase()) {
            final List subAreasList = List.from(areasList[j]['sub_areas'] ?? []);
            if (isEdit) {
              for (int k = 0; k < subAreasList.length; k++) {
                if (subAreasList[k]['id'] == id) {
                  subAreasList[k]['name_en'] = nameEn;
                  subAreasList[k]['name_bn'] = nameBn;
                  break;
                }
              }
            } else {
              subAreasList.add({
                'id': id,
                'name_en': nameEn,
                'name_bn': nameBn,
              });
            }
            areasList[j]['sub_areas'] = subAreasList;
            break;
          }
        }
        districtsRaw[i]['areas'] = areasList;
        break;
      }
    }

    setState(() {});
    _saveDivisionToFirestore(isBn: isBn);
  }

  void _deleteSubArea(String subAreaId, String subAreaName, {required bool isBn, required bool isDark}) {
    final cardBg = isDark ? const Color(0xFF112320) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF1F3D37) : const Color(0xFFE2E8F0);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: cardBg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: borderColor, width: 1.2),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                isBn ? 'সাব-এরিয়া ডিলিট করবেন?' : 'Delete Sub-Area?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
              ),
              const SizedBox(height: 10),
              Text(
                isBn
                    ? 'আপনি কি নিশ্চিত যে "$subAreaName" সাব-এরিয়াটি মুছে ফেলতে চান?'
                    : 'Are you sure you want to delete the sub-area "$subAreaName"?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, color: textSecondary, height: 1.4),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textSecondary,
                      side: BorderSide(color: borderColor),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(isBn ? 'বাতিল' : 'Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      if (_activeDivisionMap == null || _selectedDistrict == null || _selectedAreaId == null) return;
                      final districtsRaw = _activeDivisionMap!['districts'] as List;

                      for (int i = 0; i < districtsRaw.length; i++) {
                        if ((districtsRaw[i]['id']?.toString() ?? '').toLowerCase() == _selectedDistrict!.id.toLowerCase()) {
                          final List areasList = List.from(districtsRaw[i]['areas'] ?? []);
                          for (int j = 0; j < areasList.length; j++) {
                            if ((areasList[j]['id']?.toString() ?? '').toLowerCase() == _selectedAreaId!.toLowerCase()) {
                              final List subAreasList = List.from(areasList[j]['sub_areas'] ?? []);
                              subAreasList.removeWhere((sa) => sa['id'] == subAreaId);
                              areasList[j]['sub_areas'] = subAreasList;
                              break;
                            }
                          }
                          districtsRaw[i]['areas'] = areasList;
                          break;
                        }
                      }
                      setState(() {});
                      _saveDivisionToFirestore(isBn: isBn);
                    },
                    child: Text(isBn ? 'ডিলিট করুন' : 'Delete'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widget Builders ---

  Widget _buildFormLabel(String label, Color color) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.2,
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    required Color inputFill,
    required Color borderColor,
    required bool isDark,
    String? helperText,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
        fontSize: 13.5,
      ),
      helperText: helperText,
      helperStyle: TextStyle(
        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
        fontSize: 11.5,
      ),
      prefixIcon: Icon(prefixIcon, size: 20, color: AppColors.themeColor),
      filled: true,
      fillColor: inputFill,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.themeColor, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final isBn = adminProvider.isBangla;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color bgColor = isDark ? const Color(0xFF0B1917) : const Color(0xFFF8FAFC);
    final Color cardBg = isDark ? const Color(0xFF112320) : Colors.white;
    final Color surfaceAlt = isDark ? const Color(0xFF162D28) : const Color(0xFFF1F5F9);
    final Color borderColor = isDark ? const Color(0xFF1F3D37) : const Color(0xFFE2E8F0);
    final Color textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final Color textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.themeColor),
            const SizedBox(height: 16),
            Text(
              isBn ? 'লোকেশন ডাটা লোড হচ্ছে...' : 'Loading location data...',
              style: TextStyle(color: textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    final allAreas = _getCurrentAreas();
    final areas = allAreas
        .where((a) =>
            (a['name_en'] ?? '').toString().toLowerCase().contains(_areaSearchQuery.toLowerCase()) ||
            (a['name_bn'] ?? '').toString().contains(_areaSearchQuery) ||
            (a['id'] ?? '').toString().toLowerCase().contains(_areaSearchQuery.toLowerCase()))
        .toList();

    final allSubAreas = _getCurrentSubAreas();
    final subAreas = allSubAreas
        .where((sa) =>
            (sa['name_en'] ?? '').toString().toLowerCase().contains(_subAreaSearchQuery.toLowerCase()) ||
            (sa['name_bn'] ?? '').toString().contains(_subAreaSearchQuery) ||
            (sa['id'] ?? '').toString().toLowerCase().contains(_subAreaSearchQuery.toLowerCase()))
        .toList();

    return Container(
      color: bgColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 880;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 16.0 : 24.0,
              vertical: 20.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header Banner
                _buildHeader(isBn, isDark, textPrimary, textSecondary, cardBg, borderColor),
                const SizedBox(height: 18),

                // 2. Metric Overview KPIs
                _buildMetricCards(
                  isBn: isBn,
                  isDark: isDark,
                  cardBg: cardBg,
                  borderColor: borderColor,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  totalDivisions: _divisions.length,
                  totalDistricts: _districts.length,
                  totalAreas: allAreas.length,
                  totalSubAreas: allSubAreas.length,
                ),
                const SizedBox(height: 18),

                // 3. Selection Dropdowns Bar (Division & District)
                _buildSelectorCard(
                  isBn: isBn,
                  isDark: isDark,
                  cardBg: cardBg,
                  surfaceAlt: surfaceAlt,
                  borderColor: borderColor,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  isCompact: isCompact,
                ),
                const SizedBox(height: 18),

                // 4. Master-Detail Work Area (Areas & Sub-Areas)
                if (isCompact) ...[
                  // Mobile / Narrow layout: Vertical Stack
                  _buildAreasPane(
                    areas: areas,
                    allAreasCount: allAreas.length,
                    isBn: isBn,
                    isDark: isDark,
                    cardBg: cardBg,
                    surfaceAlt: surfaceAlt,
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                  const SizedBox(height: 18),
                  _buildSubAreasPane(
                    subAreas: subAreas,
                    allSubAreasCount: allSubAreas.length,
                    isBn: isBn,
                    isDark: isDark,
                    cardBg: cardBg,
                    surfaceAlt: surfaceAlt,
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                ] else ...[
                  // Desktop / Tablet layout: Dual Pane Side-by-Side
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: _buildAreasPane(
                          areas: areas,
                          allAreasCount: allAreas.length,
                          isBn: isBn,
                          isDark: isDark,
                          cardBg: cardBg,
                          surfaceAlt: surfaceAlt,
                          borderColor: borderColor,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        flex: 6,
                        child: _buildSubAreasPane(
                          subAreas: subAreas,
                          allSubAreasCount: allSubAreas.length,
                          isBn: isBn,
                          isDark: isDark,
                          cardBg: cardBg,
                          surfaceAlt: surfaceAlt,
                          borderColor: borderColor,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Header Widget ---

  Widget _buildHeader(
    bool isBn,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color cardBg,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 12,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.themeColor,
                      AppColors.themeColor.withValues(alpha: 0.75),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.themeColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.explore_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isBn ? 'লোকেশন ও ভৌগোলিক ব্যবস্থাপনা' : 'Location & Territory Management',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isBn
                        ? 'বিভাগ, জেলা, এরিয়া ও সাব-এরিয়া রিয়েলটাইম ক্লাউড ফায়ারস্টোরে পরিচালনা করুন'
                        : 'Manage divisions, districts, areas, and sub-areas in real-time Cloud Firestore.',
                    style: TextStyle(fontSize: 13, color: textSecondary),
                  ),
                ],
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isSaving)
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isBn ? 'সংরক্ষণ হচ্ছে...' : 'Saving to Cloud...',
                        style: const TextStyle(fontSize: 12, color: Colors.amber, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF162D28) : const Color(0xFFF1F5F9),
                  foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: borderColor),
                  ),
                ),
                icon: Icon(Icons.refresh_rounded, size: 18, color: isDark ? Colors.tealAccent : AppColors.themeColor),
                label: Text(
                  isBn ? 'রিফ্রেশ' : 'Refresh',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: _isLoading || _isSaving ? null : _loadInitialData,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Metric KPI Cards ---

  Widget _buildMetricCards({
    required bool isBn,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required int totalDivisions,
    required int totalDistricts,
    required int totalAreas,
    required int totalSubAreas,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 650;

        final metrics = [
          {
            'title': isBn ? 'মোট বিভাগ' : 'Divisions',
            'value': '$totalDivisions',
            'icon': Icons.map_rounded,
            'color': const Color(0xFF3B82F6),
          },
          {
            'title': isBn ? 'নির্বাচিত বিভাগের জেলা' : 'Districts',
            'value': '$totalDistricts',
            'icon': Icons.location_city_rounded,
            'color': const Color(0xFF8B5CF6),
          },
          {
            'title': isBn ? 'নির্বাচিত জেলার এরিয়া' : 'Areas / Upazilas',
            'value': '$totalAreas',
            'icon': Icons.domain_rounded,
            'color': AppColors.themeColor,
          },
          {
            'title': isBn ? 'নির্বাচিত এরিয়ার সাব-এরিয়া' : 'Sub-Areas / Unions',
            'value': '$totalSubAreas',
            'icon': Icons.near_me_rounded,
            'color': const Color(0xFF06B6D4),
          },
        ];

        if (isSmall) {
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.2,
            ),
            itemCount: metrics.length,
            itemBuilder: (ctx, i) => _buildMetricTile(
              metrics[i]['title'] as String,
              metrics[i]['value'] as String,
              metrics[i]['icon'] as IconData,
              metrics[i]['color'] as Color,
              cardBg,
              borderColor,
              textPrimary,
              textSecondary,
              isDark,
            ),
          );
        }

        return Row(
          children: metrics.map((m) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.5),
                child: _buildMetricTile(
                  m['title'] as String,
                  m['value'] as String,
                  m['icon'] as IconData,
                  m['color'] as Color,
                  cardBg,
                  borderColor,
                  textPrimary,
                  textSecondary,
                  isDark,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildMetricTile(
    String title,
    String value,
    IconData icon,
    Color accentColor,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(fontSize: 11.5, color: textSecondary, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Selector Bar (Division & District) ---

  Widget _buildSelectorCard({
    required bool isBn,
    required bool isDark,
    required Color cardBg,
    required Color surfaceAlt,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required bool isCompact,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hierarchy Indicator Breadcrumbs
          Row(
            children: [
              Icon(Icons.hub_rounded, size: 16, color: AppColors.themeColor),
              const SizedBox(width: 8),
              Text(
                isBn ? 'বর্তমান লোকেশন পথ:' : 'Active Location Hierarchy:',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: textSecondary),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.themeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _selectedDivision != null ? '${_selectedDivision!.name} (${_selectedDivision!.bnName})' : 'N/A',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.themeColor),
                ),
              ),
              if (_selectedDistrict != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.chevron_right_rounded, size: 14, color: textSecondary),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${_selectedDistrict!.name} (${_selectedDistrict!.bnName})',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6)),
                  ),
                ),
              ],
              if (_selectedAreaId != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.chevron_right_rounded, size: 14, color: textSecondary),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _selectedAreaId!,
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.teal),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Dropdowns
          if (isCompact) ...[
            _buildDivisionDropdown(isBn, isDark, surfaceAlt, borderColor, textPrimary, textSecondary),
            const SizedBox(height: 14),
            _buildDistrictDropdown(isBn, isDark, surfaceAlt, borderColor, textPrimary, textSecondary),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: _buildDivisionDropdown(isBn, isDark, surfaceAlt, borderColor, textPrimary, textSecondary),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: _buildDistrictDropdown(isBn, isDark, surfaceAlt, borderColor, textPrimary, textSecondary),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDivisionDropdown(
    bool isBn,
    bool isDark,
    Color surfaceAlt,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return DropdownButtonFormField<DivisionModel>(
      key: ValueKey('div_${_selectedDivision?.id}'),
      initialValue: _selectedDivision,
      style: TextStyle(color: textPrimary, fontSize: 13.5, fontWeight: FontWeight.w600),
      dropdownColor: isDark ? const Color(0xFF162D28) : Colors.white,
      decoration: InputDecoration(
        labelText: isBn ? 'বিভাগ নির্বাচন করুন' : 'Select Division',
        labelStyle: TextStyle(color: textSecondary, fontSize: 13),
        prefixIcon: const Icon(Icons.map_rounded, color: Color(0xFF3B82F6), size: 20),
        filled: true,
        fillColor: surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.8)),
      ),
      items: _divisions
          .map((d) => DropdownMenuItem(
                value: d,
                child: Text('${d.name} (${d.bnName})', overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: (division) async {
        if (division != null && division != _selectedDivision) {
          setState(() {
            _selectedDivision = division;
            _isLoading = true;
          });
          await _loadDivisionDetails(division.id);
          if (mounted) setState(() => _isLoading = false);
        }
      },
    );
  }

  Widget _buildDistrictDropdown(
    bool isBn,
    bool isDark,
    Color surfaceAlt,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return DropdownButtonFormField<DistrictModel>(
      key: ValueKey('dist_${_selectedDistrict?.id}'),
      initialValue: _selectedDistrict,
      style: TextStyle(color: textPrimary, fontSize: 13.5, fontWeight: FontWeight.w600),
      dropdownColor: isDark ? const Color(0xFF162D28) : Colors.white,
      decoration: InputDecoration(
        labelText: isBn ? 'জেলা নির্বাচন করুন' : 'Select District',
        labelStyle: TextStyle(color: textSecondary, fontSize: 13),
        prefixIcon: const Icon(Icons.location_city_rounded, color: Color(0xFF8B5CF6), size: 20),
        filled: true,
        fillColor: surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 1.8)),
      ),
      items: _districts
          .map((d) => DropdownMenuItem(
                value: d,
                child: Text('${d.name} (${d.bnName})', overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: (district) {
        if (district != null && district != _selectedDistrict) {
          setState(() {
            _selectedDistrict = district;
            final currentAreas = _getCurrentAreas();
            _selectedAreaId = currentAreas.isNotEmpty ? currentAreas.first['id'] : null;
          });
        }
      },
    );
  }

  // --- Left Pane: Areas / Upazilas ---

  Widget _buildAreasPane({
    required List<Map<String, dynamic>> areas,
    required int allAreasCount,
    required bool isBn,
    required bool isDark,
    required Color cardBg,
    required Color surfaceAlt,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pane Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.themeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.domain_rounded, color: AppColors.themeColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isBn ? 'এরিয়া / উপজেলাসমূহ' : 'Areas / Upazilas',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        '${areas.length} / $allAreasCount ${isBn ? 'টি এরিয়া' : 'Areas'}',
                        style: TextStyle(fontSize: 11.5, color: textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.themeColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  isBn ? 'নতুন এরিয়া' : 'Add Area',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: _selectedDistrict == null
                    ? null
                    : () => _showAddOrEditAreaDialog(isBn: isBn, isDark: isDark),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search Field
          TextField(
            controller: _areaSearchController,
            style: TextStyle(color: textPrimary, fontSize: 13.5),
            decoration: InputDecoration(
              hintText: isBn ? 'এরিয়া খুঁজুন (নাম বা বাংলা)...' : 'Search area (English or বাংলা)...',
              hintStyle: TextStyle(color: textSecondary, fontSize: 13),
              prefixIcon: Icon(Icons.search_rounded, color: textSecondary, size: 20),
              suffixIcon: _areaSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear_rounded, size: 18, color: textSecondary),
                      onPressed: () {
                        _areaSearchController.clear();
                        setState(() => _areaSearchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: surfaceAlt,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.themeColor, width: 1.6)),
            ),
            onChanged: (val) => setState(() => _areaSearchQuery = val),
          ),
          const SizedBox(height: 14),

          // Areas List
          areas.isEmpty
              ? Container(
                  height: 280,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_off_rounded, size: 44, color: textSecondary.withValues(alpha: 0.5)),
                      const SizedBox(height: 10),
                      Text(
                        _areaSearchQuery.isNotEmpty
                            ? (isBn ? 'কোনো এরিয়া মেলেনি' : 'No matching areas found')
                            : (isBn ? 'এই জেলায় কোনো এরিয়া যোগ করা হয়নি' : 'No areas added in this district yet'),
                        style: TextStyle(fontSize: 13.5, color: textSecondary, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                )
              : ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 460),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: areas.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final area = areas[index];
                      final areaId = area['id']?.toString() ?? '';
                      final isSelected = areaId.toLowerCase() == _selectedAreaId?.toLowerCase();
                      final subAreaCount = (area['sub_areas'] as List?)?.length ?? 0;
                      final nameEn = area['name_en'] ?? '';
                      final nameBn = area['name_bn'] ?? '';

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => setState(() => _selectedAreaId = areaId),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.themeColor.withValues(alpha: isDark ? 0.18 : 0.09)
                                  : (isDark ? const Color(0xFF0F221E) : const Color(0xFFFAFAFA)),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.themeColor
                                    : borderColor,
                                width: isSelected ? 1.6 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Radio-like active icon
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.themeColor : surfaceAlt,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isSelected ? Icons.check_rounded : Icons.location_on_rounded,
                                    size: 14,
                                    color: isSelected ? Colors.white : textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Area Names & Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              nameEn,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                                color: isSelected ? (isDark ? Colors.tealAccent : AppColors.themeColor) : textPrimary,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (nameBn.isNotEmpty) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: (isSelected ? AppColors.themeColor : textSecondary).withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                nameBn,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: isSelected ? (isDark ? Colors.tealAccent : AppColors.themeColor) : textSecondary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            'ID: $areaId',
                                            style: TextStyle(fontSize: 11, color: textSecondary, fontFamily: 'monospace'),
                                          ),
                                          const SizedBox(width: 10),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: Colors.teal.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '$subAreaCount ${isBn ? 'সাব-এরিয়া' : 'Sub-Areas'}',
                                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.teal),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Action Buttons
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 18),
                                      color: Colors.blueGrey,
                                      tooltip: isBn ? 'সম্পাদনা' : 'Edit',
                                      splashRadius: 18,
                                      onPressed: () => _showAddOrEditAreaDialog(
                                        existingArea: area,
                                        isBn: isBn,
                                        isDark: isDark,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                                      color: Colors.redAccent,
                                      tooltip: isBn ? 'ডিলিট' : 'Delete',
                                      splashRadius: 18,
                                      onPressed: () => _deleteArea(
                                        areaId,
                                        '$nameEn ($nameBn)',
                                        isBn: isBn,
                                        isDark: isDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }

  // --- Right Pane: Sub-Areas / Unions ---

  Widget _buildSubAreasPane({
    required List<Map<String, dynamic>> subAreas,
    required int allSubAreasCount,
    required bool isBn,
    required bool isDark,
    required Color cardBg,
    required Color surfaceAlt,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pane Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.near_me_rounded, color: Colors.teal, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isBn ? 'সাব-এরিয়া / ইউনিয়নসমূহ' : 'Sub-Areas / Unions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        _selectedAreaId == null
                            ? (isBn ? 'কোনো এরিয়া নির্বাচিত নয়' : 'No area selected')
                            : '${subAreas.length} / $allSubAreasCount ${isBn ? 'টি সাব-এরিয়া' : 'Sub-Areas'} ($_selectedAreaId!)',
                        style: TextStyle(fontSize: 11.5, color: textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add_location_alt_rounded, size: 18),
                label: Text(
                  isBn ? 'নতুন সাব-এরিয়া' : 'Add Sub-Area',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: _selectedAreaId == null
                    ? null
                    : () => _showAddOrEditSubAreaDialog(isBn: isBn, isDark: isDark),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // If no area is selected
          if (_selectedAreaId == null) ...[
            Container(
              height: 320,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.touch_app_rounded, size: 48, color: textSecondary.withValues(alpha: 0.4)),
                  const SizedBox(height: 14),
                  Text(
                    isBn ? 'প্রথমে বাম পাশ থেকে একটি এরিয়া নির্বাচন করুন' : 'Select an Area from the left pane first',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isBn
                        ? 'নির্বাচিত এরিয়ার আওতাধীন সকল সাব-এরিয়া এখানে প্রদর্শিত হবে'
                        : 'All sub-areas and unions under the selected area will appear here.',
                    style: TextStyle(fontSize: 12, color: textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ] else ...[
            // Search Field
            TextField(
              controller: _subAreaSearchController,
              style: TextStyle(color: textPrimary, fontSize: 13.5),
              decoration: InputDecoration(
                hintText: isBn ? 'সাব-এরিয়া খুঁজুন (নাম বা বাংলা)...' : 'Search sub-area (English or বাংলা)...',
                hintStyle: TextStyle(color: textSecondary, fontSize: 13),
                prefixIcon: Icon(Icons.search_rounded, color: textSecondary, size: 20),
                suffixIcon: _subAreaSearchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear_rounded, size: 18, color: textSecondary),
                        onPressed: () {
                          _subAreaSearchController.clear();
                          setState(() => _subAreaSearchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: surfaceAlt,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.teal, width: 1.6)),
              ),
              onChanged: (val) => setState(() => _subAreaSearchQuery = val),
            ),
            const SizedBox(height: 14),

            // Sub-Areas List
            subAreas.isEmpty
                ? Container(
                    height: 280,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_city_rounded, size: 44, color: textSecondary.withValues(alpha: 0.5)),
                        const SizedBox(height: 10),
                        Text(
                          _subAreaSearchQuery.isNotEmpty
                              ? (isBn ? 'কোনো সাব-এরিয়া মেলেনি' : 'No matching sub-areas found')
                              : (isBn ? 'এই এরিয়ায় কোনো সাব-এরিয়া যোগ করা হয়নি' : 'No sub-areas added to this area yet'),
                          style: TextStyle(fontSize: 13.5, color: textSecondary, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  )
                : ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 460),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: subAreas.length,
                      separatorBuilder: (c, i) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final subArea = subAreas[index];
                        final subAreaId = subArea['id']?.toString() ?? '';
                        final nameEn = subArea['name_en'] ?? '';
                        final nameBn = subArea['name_bn'] ?? '';

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F221E) : const Color(0xFFFAFAFA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor, width: 1.0),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: Colors.teal.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.place_rounded, size: 16, color: Colors.teal),
                              ),
                              const SizedBox(width: 12),

                              // Sub-Area Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            nameEn,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: textPrimary,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (nameBn.isNotEmpty) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.teal.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              nameBn,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.teal,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'ID: $subAreaId',
                                      style: TextStyle(fontSize: 11, color: textSecondary, fontFamily: 'monospace'),
                                    ),
                                  ],
                                ),
                              ),

                              // Action Buttons
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 18),
                                    color: Colors.blueGrey,
                                    tooltip: isBn ? 'সম্পাদনা' : 'Edit',
                                    splashRadius: 18,
                                    onPressed: () => _showAddOrEditSubAreaDialog(
                                      existingSubArea: subArea,
                                      isBn: isBn,
                                      isDark: isDark,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                                    color: Colors.redAccent,
                                    tooltip: isBn ? 'ডিলিট' : 'Delete',
                                    splashRadius: 18,
                                    onPressed: () => _deleteSubArea(
                                      subAreaId,
                                      '$nameEn ($nameBn)',
                                      isBn: isBn,
                                      isDark: isDark,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ],
      ),
    );
  }
}
