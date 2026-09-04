import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/extensions/utility_extension.dart';
import '../../../../app/validators.dart';
import '../../../home/data/models/property_model.dart';
import '../../../home_rent_post/presentations/widgets/amenities_dropdown.dart';
import '../../../home_rent_post/presentations/widgets/counter_dropdown.dart';
import '../../../home_rent_post/presentations/widgets/distance_dropdown.dart';
import '../../../home_rent_post/presentations/widgets/electricity_bill_dropdown.dart';
import '../../../home_rent_post/presentations/widgets/property_location_picker_card.dart';
import '../../../home_rent_post/presentations/widgets/validated_text_area.dart';
import '../../../shared/data/models/area_model.dart';
import '../../../shared/data/models/district_model.dart';
import '../../../shared/data/models/division_model.dart';
import '../../../shared/data/models/search_filter_model.dart';
import '../../../shared/data/models/sub_area_model.dart';
import '../../../shared/data/repository/location_repository.dart';
import '../../../shared/presentation/widgets/app_bar.dart';
import '../../../shared/presentation/widgets/app_network_image.dart';
import '../../../shared/presentation/widgets/belcony_dropdown_button.dart';
import '../../../shared/presentation/widgets/decorated_section_header.dart';
import '../../../shared/presentation/widgets/floor_number_dropdown_button.dart';
import '../../../shared/presentation/widgets/house_type_dropdown_button.dart';
import '../../../shared/presentation/widgets/lift_dropdown_button.dart';
import '../../../shared/presentation/widgets/location_dropdown.dart';
import '../../../shared/presentation/widgets/month_dropdown_button.dart';
import '../../../shared/presentation/widgets/number_of_room_or_seat_dropdown_button.dart';
import '../../../shared/presentation/widgets/parking_dropdown_button.dart';
import '../../../shared/presentation/widgets/tenant_type_dropdown_button.dart';
import '../../../ai_assistant/presentation/providers/ai_assistant_provider.dart';
import '../providers/my_post_provider.dart';

class EditRentPostScreen extends StatefulWidget {
  const EditRentPostScreen({super.key, required this.property});

  final PropertyModel property;
  static const String name = '/edit-rent-post';

  @override
  State<EditRentPostScreen> createState() => _EditRentPostScreenState();
}

class _EditRentPostScreenState extends State<EditRentPostScreen> {
  final LocationRepository _repository = LocationRepository();
  final _formKey = GlobalKey<FormState>();

  late List<dynamic> _images; // Contains String (URL/base64/path) or File objects
  late String? _selectedMonth;
  late HouseType? _selectedHouseType;
  late TenantType? _selectedTenantType;
  late String? _selectedRoomOrSeat;
  late String _contactName;
  late String _amount;
  late String _userMobile;
  late String _userWhatsApp;

  late DivisionModel? _selectedDivision;
  late DistrictModel? _selectedDistrict;
  late UpazilaModel? _selectedArea;
  late UnionModel? _selectedSubArea;

  late String _shortAddress;
  late String _detailedDescription;

  late int? _commonBathrooms;
  late int? _attachedBathrooms;
  late int? _kitchenCount;
  late int? _balconies;
  late int? _floorNumber;
  late String? _electricityBillType;
  late bool? _hasCctv;
  late bool? _hasWifi;
  late bool? _hasGenerator;
  late bool? _hasSecurityGuard;
  late bool? _hasLift;
  late bool? _hasParking;
  late String? _marketDistance;
  double? _latitude;
  double? _longitude;

  List<DivisionModel> _divisions = [];
  List<DistrictModel> _districts = [];
  List<UpazilaModel> _upazilas = [];
  List<UnionModel> _subAreas = [];

  bool _isLoadingDivisions = true;
  bool _isLoadingDistricts = false;
  bool _isLoadingUpazilas = false;
  bool _isLoadingAreas = false;
  bool _isSaving = false;

  static const List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.property;
    _images = List<dynamic>.from(p.images);
    _selectedMonth = p.month;
    _selectedHouseType = p.houseType;
    _selectedTenantType = p.tenantType;
    _selectedRoomOrSeat = p.roomOrSeat;
    _contactName = p.contactName;
    _amount = p.amount;
    _userMobile = p.userMobile;
    _userWhatsApp = p.userWhatsApp;

    _selectedDivision = p.division;
    _selectedDistrict = p.district;
    _selectedArea = p.area;
    _selectedSubArea = p.subArea;

    _shortAddress = p.shortAddress;
    _detailedDescription = p.detailedDescription;

    _commonBathrooms = p.commonBathrooms;
    _attachedBathrooms = p.attachedBathrooms;
    _kitchenCount = p.kitchenCount;
    _balconies = p.balconies;
    _floorNumber = p.floorNumber;
    _electricityBillType = p.electricityBillType;
    _hasCctv = p.hasCctv;
    _hasWifi = p.hasWifi;
    _hasGenerator = p.hasGenerator;
    _hasSecurityGuard = p.hasSecurityGuard;
    _hasLift = p.hasLift;
    _hasParking = p.hasParking;
    _marketDistance = p.marketDistance;
    _latitude = p.latitude;
    _longitude = p.longitude;

    _loadInitialLocations();
  }

  Future<void> _loadInitialLocations() async {
    setState(() => _isLoadingDivisions = true);
    try {
      _divisions = await _repository.getDivisions();
      if (_selectedDivision != null) {
        _districts = await _repository.getDistrictsByDivision(_selectedDivision!.id);
      }
      if (_selectedDistrict != null) {
        _upazilas = await _repository.getUpazilasByDistrict(_selectedDistrict!.id);
      }
      if (_selectedArea != null) {
        _subAreas = await _repository.getUnionsByUpazila(_selectedArea!.id);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingDivisions = false);
  }

  List<String> _getRoomOrSeatOptions() {
    final l10n = context.localizations;
    switch (_selectedHouseType) {
      case HouseType.flat:
        return List.generate(8, (i) => "${l10n.bedroom} - ${i + 1}");
      case HouseType.room:
        return List.generate(8, (i) => "${l10n.room} - ${i + 1}");
      case HouseType.seat:
        return List.generate(8, (i) => "${l10n.emptySeat} - ${i + 1}");
      case HouseType.unit:
        return List.generate(8, (i) => "${l10n.unit} - ${i + 1}");
      case null:
        return const [];
    }
  }

  // --- Photo Picker Sheet ---
  Future<void> _pickImage({bool isThumbnail = false, int? replaceIndex}) async {
    final picker = ImagePicker();
    final l10n = context.localizations;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                isThumbnail ? l10n.mainThumbnailTitle : l10n.additionalPhotosTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppColors.themeColor),
                title: Text(l10n.galleryOption),
                onTap: () async {
                  Navigator.pop(ctx);
                  if (isThumbnail || replaceIndex != null) {
                    final picked = await picker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 800,
                      maxHeight: 800,
                      imageQuality: 70,
                    );
                    if (picked != null) {
                      setState(() {
                        final file = File(picked.path);
                        if (isThumbnail) {
                          if (_images.isEmpty) {
                            _images.add(file);
                          } else {
                            _images[0] = file;
                          }
                        } else if (replaceIndex != null && replaceIndex < _images.length) {
                          _images[replaceIndex] = file;
                        }
                      });
                    }
                  } else {
                    final pickedList = await picker.pickMultiImage(
                      maxWidth: 800,
                      maxHeight: 800,
                      imageQuality: 70,
                    );
                    if (pickedList.isNotEmpty) {
                      setState(() {
                        for (final xFile in pickedList) {
                          if (_images.length >= 10) break;
                          _images.add(File(xFile.path));
                        }
                      });
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: AppColors.themeColor),
                title: Text(l10n.cameraOption),
                onTap: () async {
                  Navigator.pop(ctx);
                  final picked = await picker.pickImage(
                    source: ImageSource.camera,
                    maxWidth: 800,
                    maxHeight: 800,
                    imageQuality: 70,
                  );
                  if (picked != null) {
                    setState(() {
                      final file = File(picked.path);
                      if (isThumbnail) {
                        if (_images.isEmpty) {
                          _images.add(file);
                        } else {
                          _images[0] = file;
                        }
                      } else if (replaceIndex != null && replaceIndex < _images.length) {
                        _images[replaceIndex] = file;
                      } else {
                        if (_images.length < 10) _images.add(file);
                      }
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    final languageCode = Localizations.localeOf(context).languageCode;
    final isBn = languageCode == 'bn';

    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isBn ? 'প্রধান থাম্বনেইল ছবি যুক্ত করা আবশ্যক' : 'Main thumbnail image is required',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_contactName.trim().isEmpty ||
        _amount.trim().isEmpty ||
        _userMobile.trim().isEmpty ||
        _shortAddress.trim().isEmpty ||
        _detailedDescription.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isBn
                ? 'অনুগ্রহ করে সকল প্রয়োজনীয় তথ্য সঠিকভাবে পূরণ করুন'
                : 'Please fill all required fields correctly',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Bilingual Save Confirmation Dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.edit_note_rounded, color: AppColors.themeColor),
            const SizedBox(width: 8),
            Text(isBn ? 'পরিবর্তন সংরক্ষণ' : 'Confirm Save Changes'),
          ],
        ),
        content: Text(
          isBn
              ? 'আপনি কি এই পোস্টের পরিবর্তনগুলো সংরক্ষণ করতে চান?'
              : 'Are you sure you want to save changes to this post?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(isBn ? 'বাতিল' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.themeColor),
            child: Text(isBn ? 'সংরক্ষণ করুন' : 'Save'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSaving = true);

    // Process images
    final List<String> finalImages = [];
    for (final img in _images) {
      if (img is String) {
        finalImages.add(img);
      } else if (img is File) {
        if (await img.exists()) {
          try {
            final bytes = await img.readAsBytes();
            if (bytes.lengthInBytes <= 1048576) {
              final base64String = base64Encode(bytes);
              final ext = img.path.split('.').last.toLowerCase();
              final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';
              finalImages.add('data:$mimeType;base64,$base64String');
            } else {
              finalImages.add(img.path);
            }
          } catch (_) {
            finalImages.add(img.path);
          }
        }
      }
    }

    final updated = PropertyModel(
      id: widget.property.id,
      ownerId: widget.property.ownerId,
      ownerEmail: widget.property.ownerEmail,
      images: finalImages,
      month: _selectedMonth ?? widget.property.month,
      houseType: _selectedHouseType ?? widget.property.houseType,
      tenantType: _selectedTenantType,
      roomOrSeat: _selectedRoomOrSeat ?? widget.property.roomOrSeat,
      contactName: _contactName.trim(),
      amount: _amount.trim(),
      userMobile: _userMobile.trim(),
      userWhatsApp: _userWhatsApp.trim().isNotEmpty ? _userWhatsApp.trim() : _userMobile.trim(),
      division: _selectedDivision ?? widget.property.division,
      district: _selectedDistrict ?? widget.property.district,
      area: _selectedArea ?? widget.property.area,
      subArea: _selectedSubArea,
      shortAddress: _shortAddress.trim(),
      detailedDescription: _detailedDescription.trim(),
      commonBathrooms: _commonBathrooms,
      attachedBathrooms: _attachedBathrooms,
      kitchenCount: _kitchenCount,
      balconies: _balconies,
      floorNumber: _floorNumber,
      electricityBillType: _electricityBillType,
      hasCctv: _hasCctv,
      hasWifi: _hasWifi,
      hasGenerator: _hasGenerator,
      hasSecurityGuard: _hasSecurityGuard,
      hasLift: _hasLift,
      hasParking: _hasParking,
      marketDistance: _marketDistance,
      latitude: _latitude,
      longitude: _longitude,
      postDate: widget.property.postDate,
    );

    if (!mounted) return;

    try {
      await context.read<MyPostProvider>().updatePost(updated);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isBn ? '🎉 আপনার পোস্ট সফলভাবে আপডেট করা হয়েছে!' : '🎉 Post updated successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isBn ? 'পোস্ট আপডেট করতে সমস্যা হয়েছে: $e' : 'Error updating post: $e',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: MainAppBar(
        automaticallyImplyLeading: true,
        title: Text(
          l10n.editPost,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Photo Editor Section ---
              DecoratedSectionHeader(title: l10n.addPhotos),
              const SizedBox(height: 12),
              _buildPhotoEditor(theme, isDark, l10n),
              const SizedBox(height: 24),

              // --- Accommodation Details Section ---
              DecoratedSectionHeader(title: l10n.accommodationPromptTitle),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: MonthDropdown(
                      value: _selectedMonth,
                      months: _months,
                      onChanged: (val) => setState(() => _selectedMonth = val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: HouseTypeDropdown(
                      value: _selectedHouseType,
                      houseTypes: HouseType.values,
                      onChanged: (val) {
                        setState(() {
                          _selectedHouseType = val;
                          _selectedRoomOrSeat = null;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: RoomOrSeatDropdown(
                      hint: l10n.roomOrSeatNo,
                      value: _selectedRoomOrSeat,
                      enabled: _selectedHouseType != null,
                      options: _getRoomOrSeatOptions(),
                      onChanged: (val) => setState(() => _selectedRoomOrSeat = val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TenantTypeDropdown(
                      value: _selectedTenantType,
                      onChanged: (val) => setState(() => _selectedTenantType = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // --- Contact & Budget Section ---
              DecoratedSectionHeader(title: l10n.budgetTenantPromptTitle),
              const SizedBox(height: 12),
              _buildTextField(
                hint: l10n.contactPerson,
                prefixIcon: Icons.person_outline_rounded,
                initialValue: _contactName,
                onChanged: (val) => _contactName = val,
                validator: (val) => Validators.validateText(val),
              ),
              const SizedBox(height: 12),
              _buildTextField(
                hint: l10n.amount,
                prefixIcon: Icons.attach_money_rounded,
                initialValue: _amount,
                keyboardType: TextInputType.number,
                onChanged: (val) => _amount = val,
                validator: (val) => Validators.validateNumber(val),
              ),
              const SizedBox(height: 12),
              _buildTextField(
                hint: l10n.enterMobile,
                prefixIcon: Icons.phone_outlined,
                initialValue: _userMobile,
                keyboardType: TextInputType.phone,
                onChanged: (val) => _userMobile = val,
                validator: (val) => Validators.validatePhoneNumber(val),
              ),
              const SizedBox(height: 12),
              _buildTextField(
                hint: l10n.enterWhatsApp,
                prefixIcon: Icons.chat_outlined,
                initialValue: _userWhatsApp,
                keyboardType: TextInputType.phone,
                onChanged: (val) => _userWhatsApp = val,
              ),
              const SizedBox(height: 24),

              // --- Location Section ---
              DecoratedSectionHeader(title: l10n.locationPromptTitle),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DivisionDropdown(
                      value: _selectedDivision,
                      divisions: _divisions,
                      isLoading: _isLoadingDivisions,
                      onChanged: (division) async {
                        setState(() {
                          _selectedDivision = division;
                          _selectedDistrict = null;
                          _selectedArea = null;
                          _selectedSubArea = null;
                          _districts = [];
                          _upazilas = [];
                          _subAreas = [];
                          _isLoadingDistricts = true;
                        });
                        if (division != null) {
                          final dists = await _repository.getDistrictsByDivision(division.id);
                          if (mounted) setState(() => _districts = dists);
                        }
                        if (mounted) setState(() => _isLoadingDistricts = false);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DistrictDropdown(
                      value: _selectedDistrict,
                      districts: _districts,
                      enabled: _selectedDivision != null,
                      isLoading: _isLoadingDistricts,
                      onChanged: (district) async {
                        setState(() {
                          _selectedDistrict = district;
                          _selectedArea = null;
                          _selectedSubArea = null;
                          _upazilas = [];
                          _subAreas = [];
                          _isLoadingUpazilas = true;
                        });
                        if (district != null) {
                          final upzs = await _repository.getUpazilasByDistrict(district.id);
                          if (mounted) setState(() => _upazilas = upzs);
                        }
                        if (mounted) setState(() => _isLoadingUpazilas = false);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: UpazilaDropdown(
                      value: _selectedArea,
                      upazilas: _upazilas,
                      enabled: _selectedDistrict != null,
                      isLoading: _isLoadingUpazilas,
                      onChanged: (upazila) async {
                        setState(() {
                          _selectedArea = upazila;
                          _selectedSubArea = null;
                          _subAreas = [];
                          _isLoadingAreas = true;
                        });
                        if (upazila != null) {
                          final subs = await _repository.getUnionsByUpazila(upazila.id);
                          if (mounted) setState(() => _subAreas = subs);
                        }
                        if (mounted) setState(() => _isLoadingAreas = false);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AreaDropdown(
                      value: _selectedSubArea,
                      areas: _subAreas,
                      enabled: _selectedArea != null,
                      isLoading: _isLoadingAreas,
                      onChanged: (subArea) {
                        setState(() => _selectedSubArea = subArea);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ValidatedTextArea(
                hint: l10n.shortAddress,
                maxWords: 200,
                initialValue: _shortAddress,
                onChanged: (val) => _shortAddress = val,
                validator: (val) => Validators.validateText(val),
              ),
              const SizedBox(height: 16),

              // --- Property Exact Location on Map ---
              PropertyLocationPickerCard(
                latitude: _latitude,
                longitude: _longitude,
                onLocationChanged: (lat, lng) {
                  setState(() {
                    _latitude = lat;
                    _longitude = lng;
                  });
                },
              ),
              const SizedBox(height: 24),

              // --- Amenities & Facilities Section ---
              DecoratedSectionHeader(title: l10n.amenitiesPromptTitle),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CounterDropdown(
                      hint: l10n.commonBathroom,
                      value: _commonBathrooms,
                      onChanged: (val) => setState(() => _commonBathrooms = val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CounterDropdown(
                      hint: l10n.attachedBathroom,
                      value: _attachedBathrooms,
                      onChanged: (val) => setState(() => _attachedBathrooms = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CounterDropdown(
                      hint: l10n.kitchen,
                      value: _kitchenCount,
                      onChanged: (val) => setState(() => _kitchenCount = val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: BalconyDropdown(
                      value: _balconies,
                      onChanged: (val) => setState(() => _balconies = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FloorNumberDropdown(
                      value: _floorNumber,
                      onChanged: (val) => setState(() => _floorNumber = val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElectricityBillDropdown(
                      value: _electricityBillType,
                      onChanged: (val) => setState(() => _electricityBillType = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AmenitiesDropdown(
                      hint: l10n.cctv,
                      value: _hasCctv,
                      onChanged: (val) => setState(() => _hasCctv = val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AmenitiesDropdown(
                      hint: l10n.wifi,
                      value: _hasWifi,
                      onChanged: (val) => setState(() => _hasWifi = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AmenitiesDropdown(
                      hint: l10n.generator,
                      value: _hasGenerator,
                      onChanged: (val) => setState(() => _hasGenerator = val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AmenitiesDropdown(
                      hint: l10n.securityGuard,
                      value: _hasSecurityGuard,
                      onChanged: (val) => setState(() => _hasSecurityGuard = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ParkingDropdown(
                      value: _hasParking,
                      onChanged: (val) => setState(() => _hasParking = val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LiftDropdown(
                      value: _hasLift,
                      onChanged: (val) => setState(() => _hasLift = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DistanceDropdown(
                value: _marketDistance,
                onChanged: (val) => setState(() => _marketDistance = val),
              ),
              const SizedBox(height: 24),

              // --- Detailed Description Section with AI Generation Action ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: DecoratedSectionHeader(title: l10n.detailedDescription)),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.themeColor,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    ),
                    icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                    label: Text(
                      Localizations.localeOf(context).languageCode == 'bn' ? 'এআই দিয়ে লিখুন' : 'AI Generate',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                    ),
                    onPressed: () async {
                      final languageCode = Localizations.localeOf(context).languageCode;
                      final isBn = languageCode == 'bn';
                      final division = _selectedDivision?.getLocalizedName(languageCode);
                      final district = _selectedDistrict?.getLocalizedName(languageCode);
                      final area = _selectedArea?.getLocalizedName(languageCode) ?? (isBn ? 'ঢাকা' : 'Dhaka');
                      final subArea = _selectedSubArea?.getLocalizedName(languageCode);
                      final shortAddress = _shortAddress;
                      final houseType = _selectedHouseType?.getLocalizedLabel(l10n) ?? (isBn ? 'ফ্ল্যাট' : 'Flat');
                      final roomOrSeat = _selectedRoomOrSeat ?? (isBn ? '২ বেডরুম' : '2 Bedrooms');
                      final tenantType = _selectedTenantType?.getLocalizedLabel(l10n);
                      final month = _selectedMonth;
                      final floor = _floorNumber?.toString() ?? (isBn ? '৩' : '3');
                      final amount = _amount.isNotEmpty ? _amount : '15000';
                      final electricityBillType = _electricityBillType;
                      final marketDistance = _marketDistance;
                      final commonBathrooms = _commonBathrooms;
                      final attachedBathrooms = _attachedBathrooms;
                      final kitchenCount = _kitchenCount;
                      final balconies = _balconies;
                      final amenities = <String>[
                        if (_hasLift == true) (isBn ? 'লিফট সুবিধা' : 'Lift Access'),
                        if (_hasParking == true) (isBn ? 'গাড়ি পার্কিং' : 'Car Parking'),
                        if (_hasGenerator == true) (isBn ? 'জেনারেটর ব্যাকআপ' : 'Generator Backup'),
                        if (_hasCctv == true) (isBn ? 'সিসিটিভি নিরাপত্তা' : 'CCTV Security'),
                        if (_hasSecurityGuard == true) (isBn ? '২৪ ঘণ্টা দারোয়ান' : '24/7 Security Guard'),
                        if (_hasWifi == true) (isBn ? 'উচ্চগতির ওয়াইফাই' : 'High-speed WiFi'),
                      ];

                      final messenger = ScaffoldMessenger.of(context);
                      final aiProvider = context.read<AIAssistantProvider>();

                      messenger.showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              ),
                              const SizedBox(width: 12),
                              Text(isBn ? 'এআই সুন্দরভাবে বিবরণ তৈরি করছে...' : 'AI is generating decorated description...'),
                            ],
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );

                      final genText = await aiProvider.generateAdDescriptionForOwner(
                            area: area,
                            subArea: subArea,
                            district: district,
                            division: division,
                            shortAddress: shortAddress,
                            houseType: houseType,
                            roomOrSeat: roomOrSeat,
                            tenantType: tenantType,
                            month: month,
                            floor: floor,
                            amount: amount,
                            commonBathrooms: commonBathrooms,
                            attachedBathrooms: attachedBathrooms,
                            kitchenCount: kitchenCount,
                            balconies: balconies,
                            electricityBillType: electricityBillType,
                            amenities: amenities,
                            marketDistance: marketDistance,
                            languageCode: languageCode,
                          );

                      if (!mounted) return;

                      setState(() {
                        _detailedDescription = genText;
                      });
                      messenger.hideCurrentSnackBar();
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(isBn ? '✨ এআই আকর্ষণীয় বিবরণ তৈরি করেছে!' : '✨ AI decorated description generated!'),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ValidatedTextArea(
                hint: l10n.detailedDescription,
                maxWords: 999,
                initialValue: _detailedDescription,
                onChanged: (val) => _detailedDescription = val,
                validator: (val) => Validators.validateText(val),
              ),
              const SizedBox(height: 24),

              // --- Save Changes Button ---
              FilledButton(
                onPressed: _isSaving ? null : _saveChanges,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(l10n.saveChanges),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoEditor(ThemeData theme, bool isDark, dynamic l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Thumbnail Frame
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[850] : Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _images.isNotEmpty ? AppColors.themeColor : Colors.grey.shade400,
              width: 1.5,
            ),
          ),
          child: _images.isNotEmpty
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    AppImageWidget(
                      imageSource: _images.first,
                      borderRadius: BorderRadius.circular(15),
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.themeColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          l10n.mainThumbnailBadge,
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: Row(
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black.withValues(alpha: 0.7),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.edit, size: 14),
                            label: Text(l10n.changePhoto, style: const TextStyle(fontSize: 12)),
                            onPressed: () => _pickImage(isThumbnail: true),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.delete_outline, size: 16),
                            onPressed: () {
                              setState(() => _images.removeAt(0));
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.filled(
                        style: IconButton.styleFrom(backgroundColor: AppColors.themeColor),
                        icon: const Icon(Icons.add_a_photo_outlined, color: Colors.white),
                        onPressed: () => _pickImage(isThumbnail: true),
                      ),
                      const SizedBox(height: 8),
                      Text(l10n.mainThumbnailTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 12),

        // Additional Photos Row
        Text(
          '${l10n.additionalPhotosTitle} (${_images.length > 1 ? _images.length - 1 : 0}/9)',
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 85,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: (_images.length > 1 ? _images.length - 1 : 0) + (_images.length < 10 ? 1 : 0),
            separatorBuilder: (c, i) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final additionalIndex = index + 1;

              // "Add More" Button Slot
              if (additionalIndex > _images.length - 1 || _images.isEmpty) {
                return GestureDetector(
                  onTap: () => _pickImage(isThumbnail: false),
                  child: Container(
                    width: 85,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[850] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
                    ),
                    child: const Center(
                      child: Icon(Icons.add_photo_alternate_outlined, color: AppColors.themeColor, size: 28),
                    ),
                  ),
                );
              }

              // Filled Additional Slot
              final imgSource = _images[additionalIndex];
              return Stack(
                children: [
                  Container(
                    width: 85,
                    height: 85,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: AppImageWidget(
                      imageSource: imgSource,
                      borderRadius: BorderRadius.circular(12),
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _images.removeAt(additionalIndex));
                      },
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String hint,
    required String initialValue,
    required ValueChanged<String> onChanged,
    IconData? prefixIcon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      initialValue: initialValue,
      onChanged: onChanged,
      validator: validator,
      keyboardType: keyboardType,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20, color: AppColors.themeColor) : null,
      ),
    );
  }
}
