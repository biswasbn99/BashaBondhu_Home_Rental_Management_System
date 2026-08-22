import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../app/app_colors.dart';
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
  String _areaSearchQuery = '';
  String _subAreaSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
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

  Future<void> _saveDivisionToFirestore() async {
    if (_selectedDivision == null || _activeDivisionMap == null) return;
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('locations')
          .doc(_selectedDivision!.id.toLowerCase())
          .set(_activeDivisionMap!);

      _repository.clearCache();
      _showSnackbar('✅ Successfully saved changes to Firestore!');
    } catch (e) {
      _showSnackbar('❌ Failed to save to Firestore: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // --- Add / Edit Dialogs ---

  void _showAddOrEditAreaDialog({Map<String, dynamic>? existingArea}) {
    final isEdit = existingArea != null;
    final idController = TextEditingController(text: existingArea?['id'] ?? '');
    final nameEnController = TextEditingController(text: existingArea?['name_en'] ?? '');
    final nameBnController = TextEditingController(text: existingArea?['name_bn'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit Area / Upazila' : 'Add New Area / Upazila'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isEdit)
                TextField(
                  controller: idController,
                  decoration: const InputDecoration(
                    labelText: 'Area ID (e.g. uttara, gulshan)',
                    hintText: 'lowercase_with_underscores',
                  ),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: nameEnController,
                decoration: const InputDecoration(
                  labelText: 'Name in English',
                  hintText: 'e.g. Uttara',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameBnController,
                decoration: const InputDecoration(
                  labelText: 'Name in Bengali (বাংলা)',
                  hintText: 'e.g. উত্তরা',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.themeColor, foregroundColor: Colors.white),
            onPressed: () {
              final id = idController.text.trim().toLowerCase().replaceAll(' ', '_');
              final nameEn = nameEnController.text.trim();
              final nameBn = nameBnController.text.trim();

              if (nameEn.isEmpty || nameBn.isEmpty || (!isEdit && id.isEmpty)) {
                _showSnackbar('Please fill all fields', isError: true);
                return;
              }

              Navigator.pop(ctx);
              _performAddOrEditArea(id: isEdit ? existingArea['id'] : id, nameEn: nameEn, nameBn: nameBn, isEdit: isEdit);
            },
            child: Text(isEdit ? 'Update' : 'Add Area'),
          ),
        ],
      ),
    );
  }

  void _performAddOrEditArea({required String id, required String nameEn, required String nameBn, required bool isEdit}) {
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
    _saveDivisionToFirestore();
  }

  void _deleteArea(String areaId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Area?'),
        content: const Text('Are you sure you want to delete this Area and all its Sub-Areas?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
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
              _saveDivisionToFirestore();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddOrEditSubAreaDialog({Map<String, dynamic>? existingSubArea}) {
    if (_selectedAreaId == null) {
      _showSnackbar('Please select an Area first', isError: true);
      return;
    }
    final isEdit = existingSubArea != null;
    final idController = TextEditingController(text: existingSubArea?['id'] ?? '');
    final nameEnController = TextEditingController(text: existingSubArea?['name_en'] ?? '');
    final nameBnController = TextEditingController(text: existingSubArea?['name_bn'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit Sub-Area / Union' : 'Add New Sub-Area / Union'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isEdit)
                TextField(
                  controller: idController,
                  decoration: const InputDecoration(
                    labelText: 'Sub-Area ID',
                    hintText: 'e.g. uttara_sector_1',
                  ),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: nameEnController,
                decoration: const InputDecoration(
                  labelText: 'Name in English',
                  hintText: 'e.g. Uttara Sector 1',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameBnController,
                decoration: const InputDecoration(
                  labelText: 'Name in Bengali (বাংলা)',
                  hintText: 'e.g. উত্তরা সেক্টর ১',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.themeColor, foregroundColor: Colors.white),
            onPressed: () {
              final id = idController.text.trim().toLowerCase().replaceAll(' ', '_');
              final nameEn = nameEnController.text.trim();
              final nameBn = nameBnController.text.trim();

              if (nameEn.isEmpty || nameBn.isEmpty || (!isEdit && id.isEmpty)) {
                _showSnackbar('Please fill all fields', isError: true);
                return;
              }

              Navigator.pop(ctx);
              _performAddOrEditSubArea(id: isEdit ? existingSubArea['id'] : id, nameEn: nameEn, nameBn: nameBn, isEdit: isEdit);
            },
            child: Text(isEdit ? 'Update' : 'Add Sub-Area'),
          ),
        ],
      ),
    );
  }

  void _performAddOrEditSubArea({required String id, required String nameEn, required String nameBn, required bool isEdit}) {
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
    _saveDivisionToFirestore();
  }

  void _deleteSubArea(String subAreaId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Sub-Area?'),
        content: const Text('Are you sure you want to delete this Sub-Area?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
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
              _saveDivisionToFirestore();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final areas = _getCurrentAreas()
        .where((a) => (a['name_en'] ?? '').toString().toLowerCase().contains(_areaSearchQuery.toLowerCase()) ||
                      (a['name_bn'] ?? '').toString().contains(_areaSearchQuery))
        .toList();

    final subAreas = _getCurrentSubAreas()
        .where((sa) => (sa['name_en'] ?? '').toString().toLowerCase().contains(_subAreaSearchQuery.toLowerCase()) ||
                       (sa['name_bn'] ?? '').toString().contains(_subAreaSearchQuery))
        .toList();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Location Management',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage Divisions, Districts, Areas, and Sub-Areas directly in Cloud Firestore in real-time.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
              Row(
                children: [
                  if (_isSaving)
                    const Padding(
                      padding: EdgeInsets.only(right: 12.0),
                      child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.themeColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh from Firestore'),
                    onPressed: _isLoading || _isSaving ? null : _loadInitialData,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Selector Card (Division & District)
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Division Selector
                  Expanded(
                    child: DropdownButtonFormField<DivisionModel>(
                      initialValue: _selectedDivision,
                      decoration: const InputDecoration(
                        labelText: 'Select Division',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: _divisions
                          .map((d) => DropdownMenuItem(
                                value: d,
                                child: Text('${d.name} (${d.bnName})'),
                              ))
                          .toList(),
                      onChanged: (division) async {
                        if (division != null) {
                          setState(() {
                            _selectedDivision = division;
                            _isLoading = true;
                          });
                          await _loadDivisionDetails(division.id);
                          if (mounted) setState(() => _isLoading = false);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 20),

                  // District Selector
                  Expanded(
                    child: DropdownButtonFormField<DistrictModel>(
                      initialValue: _selectedDistrict,
                      decoration: const InputDecoration(
                        labelText: 'Select District',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: _districts
                          .map((d) => DropdownMenuItem(
                                value: d,
                                child: Text('${d.name} (${d.bnName})'),
                              ))
                          .toList(),
                      onChanged: (district) {
                        if (district != null) {
                          setState(() {
                            _selectedDistrict = district;
                            final currentAreas = _getCurrentAreas();
                            _selectedAreaId = currentAreas.isNotEmpty ? currentAreas.first['id'] : null;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Two-Pane Content: Areas (Left) & Sub-Areas (Right)
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- LEFT PANE: AREAS ---
                Expanded(
                  flex: 5,
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Areas / Upazilas (${areas.length})',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.themeColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Add Area'),
                                onPressed: () => _showAddOrEditAreaDialog(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            decoration: InputDecoration(
                              hintText: 'Search Area (English or বাংলা)...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onChanged: (val) => setState(() => _areaSearchQuery = val),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: areas.isEmpty
                                ? const Center(child: Text('No Areas found.'))
                                : ListView.separated(
                                    itemCount: areas.length,
                                    separatorBuilder: (c, i) => const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final area = areas[index];
                                      final areaId = area['id']?.toString() ?? '';
                                      final isSelected = areaId.toLowerCase() == _selectedAreaId?.toLowerCase();
                                      final subAreaCount = (area['sub_areas'] as List?)?.length ?? 0;

                                      return ListTile(
                                        selected: isSelected,
                                        selectedTileColor: AppColors.themeColor.withValues(alpha: 0.08),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        title: Text(
                                          '${area['name_en']} (${area['name_bn']})',
                                          style: TextStyle(
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            color: isSelected ? AppColors.themeColor : Colors.black87,
                                          ),
                                        ),
                                        subtitle: Text('ID: $areaId | $subAreaCount Sub-Areas'),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blueGrey),
                                              onPressed: () => _showAddOrEditAreaDialog(existingArea: area),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                                              onPressed: () => _deleteArea(areaId),
                                            ),
                                          ],
                                        ),
                                        onTap: () {
                                          setState(() => _selectedAreaId = areaId);
                                        },
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // --- RIGHT PANE: SUB-AREAS ---
                Expanded(
                  flex: 5,
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Sub-Areas / Unions (${subAreas.length})',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Add Sub-Area'),
                                onPressed: _selectedAreaId == null ? null : () => _showAddOrEditSubAreaDialog(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            decoration: InputDecoration(
                              hintText: 'Search Sub-Area (English or বাংলা)...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onChanged: (val) => setState(() => _subAreaSearchQuery = val),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: _selectedAreaId == null
                                ? const Center(child: Text('Select an Area on the left to view Sub-Areas.'))
                                : subAreas.isEmpty
                                    ? const Center(child: Text('No Sub-Areas found in this Area.'))
                                    : ListView.separated(
                                        itemCount: subAreas.length,
                                        separatorBuilder: (c, i) => const Divider(height: 1),
                                        itemBuilder: (context, index) {
                                          final subArea = subAreas[index];
                                          final subAreaId = subArea['id']?.toString() ?? '';

                                          return ListTile(
                                            title: Text('${subArea['name_en']} (${subArea['name_bn']})'),
                                            subtitle: Text('ID: $subAreaId'),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blueGrey),
                                                  onPressed: () => _showAddOrEditSubAreaDialog(existingSubArea: subArea),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                                                  onPressed: () => _deleteSubArea(subAreaId),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
