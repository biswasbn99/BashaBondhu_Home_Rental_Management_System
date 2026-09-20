import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/extensions/utility_extension.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../home/data/models/property_model.dart';
import '../../../home/presentation/screens/property_details_screen.dart';
import '../../../home/presentation/widgets/property_card.dart';
import '../../../shared/data/models/search_filter_model.dart';
import '../../../shared/data/services/property_firestore_service.dart';
import '../../../shared/presentation/widgets/app_bar.dart';
import '../../../shared/presentation/widgets/app_network_image.dart';

class SearchResultScreen extends StatefulWidget {
  const SearchResultScreen({super.key, required this.filter});

  final SearchFilterModel filter;

  @override
  State<SearchResultScreen> createState() => _SearchResultScreenState();
}

class _SearchResultScreenState extends State<SearchResultScreen> {
  final PropertyFirestoreService _service = PropertyFirestoreService();
  static const Distance _distanceCalc = Distance();
  late SearchFilterModel _activeFilter;
  bool _isMapView = false;
  PropertyModel? _selectedMapProperty;
  late final MapController _mapController;
  late final Stream<List<PropertyModel>> _propertiesStream;

  @override
  void initState() {
    super.initState();
    _activeFilter = widget.filter;
    _mapController = MapController();
    _propertiesStream = _service.streamAllProperties();
  }

  int? _parseDigits(String input) {
    const bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    const enDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    String s = input.trim();
    for (int i = 0; i < 10; i++) {
      s = s.replaceAll(bnDigits[i], enDigits[i]);
    }
    return int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), ''));
  }

  bool _matchesBudget(String propertyAmount, String budgetRange) {
    final cleanedAmount = _parseDigits(propertyAmount);
    if (cleanedAmount == null) return true;

    if (budgetRange.contains('+')) {
      final min = _parseDigits(budgetRange) ?? 50000;
      return cleanedAmount >= min;
    }

    final parts = budgetRange.split('-');
    if (parts.length == 2) {
      final min = _parseDigits(parts[0]) ?? 0;
      final max = _parseDigits(parts[1]) ?? 9999999;
      return cleanedAmount >= min && cleanedAmount <= max;
    }

    final single = _parseDigits(budgetRange);
    if (single != null) {
      return cleanedAmount <= single;
    }

    return true;
  }

  bool _matchesMonth(String propMonth, String filterMonth) {
    final p = propMonth.toLowerCase().trim();
    final f = filterMonth.toLowerCase().trim();
    if (p == f) return true;

    const enMonths = [
      'january', 'february', 'march', 'april', 'may', 'june',
      'july', 'august', 'september', 'october', 'november', 'december'
    ];
    const bnMonths = [
      'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
      'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'
    ];

    int? pIdx;
    int? fIdx;
    for (int i = 0; i < 12; i++) {
      if (p.contains(enMonths[i]) || p.contains(bnMonths[i])) pIdx = i;
      if (f.contains(enMonths[i]) || f.contains(bnMonths[i])) fIdx = i;
    }
    if (pIdx != null && fIdx != null) {
      return pIdx == fIdx;
    }
    return p.contains(f) || f.contains(p);
  }

  bool _matchesRoomOrSeat(String propVal, String filterVal) {
    if (propVal.toLowerCase().trim() == filterVal.toLowerCase().trim()) return true;
    final propNum = _parseDigits(propVal);
    final filterNum = _parseDigits(filterVal);
    if (propNum != null && filterNum != null) {
      return propNum == filterNum;
    }
    return propVal.toLowerCase().contains(filterVal.toLowerCase()) ||
        filterVal.toLowerCase().contains(propVal.toLowerCase());
  }

  bool _matchesRadius(PropertyModel property, SearchFilterModel filter) {
    final searchLat = filter.searchLatitude;
    final searchLng = filter.searchLongitude;
    if (searchLat == null || searchLng == null || (searchLat == 0 && searchLng == 0)) {
      return false;
    }

    final propLat = property.effectiveLatitude;
    final propLng = property.effectiveLongitude;

    // Check geographic distance if coordinates are available
    if (propLat != null && propLng != null && propLat != 0 && propLng != 0) {
      final distanceKm = _distanceCalc.as(
        LengthUnit.Kilometer,
        LatLng(searchLat, searchLng),
        LatLng(propLat, propLng),
      );
      if (distanceKm > (filter.searchRadiusKm ?? 5.0)) return false;
    } else {
      // Area-level fallback matching if coordinates couldn't be resolved
      final bool matchesArea = (filter.upazila != null && property.area.id == filter.upazila!.id) ||
          (filter.area != null && property.subArea?.id == filter.area!.id) ||
          (filter.district != null && property.district.id == filter.district!.id);
      if (!matchesArea) return false;
    }

    // Optional Criteria (Only filter when explicitly selected / not null)
    if (filter.month != null && filter.month!.trim().isNotEmpty) {
      if (!_matchesMonth(property.month, filter.month!)) return false;
    }
    if (filter.houseType != null && property.houseType != filter.houseType) {
      return false;
    }
    if (filter.tenantType != null && property.tenantType != null) {
      if (property.tenantType != filter.tenantType) return false;
    }
    if (filter.budgetRange != null && filter.budgetRange!.trim().isNotEmpty) {
      if (!_matchesBudget(property.amount, filter.budgetRange!)) return false;
    }
    if (filter.roomOrSeat != null && filter.roomOrSeat!.trim().isNotEmpty) {
      if (!_matchesRoomOrSeat(property.roomOrSeat, filter.roomOrSeat!)) return false;
    }
    if (filter.bathrooms != null) {
      final totalBaths = (property.attachedBathrooms ?? 0) + (property.commonBathrooms ?? 0);
      if (totalBaths < filter.bathrooms!) return false;
    }
    if (filter.balconies != null && (property.balconies ?? 0) < filter.balconies!) return false;
    if (filter.floorNumber != null && property.floorNumber != null && property.floorNumber != filter.floorNumber) return false;
    if (filter.hasParking != null && property.hasParking != null && property.hasParking != filter.hasParking) return false;
    if (filter.hasLift != null && property.hasLift != null && property.hasLift != filter.hasLift) return false;

    return true;
  }

  bool _matchesTraditionalFilter(PropertyModel property, SearchFilterModel filter) {
    // 1. Division check
    if (filter.division != null && filter.division!.id.isNotEmpty) {
      final divIdMatch = property.division.id.isNotEmpty &&
          property.division.id.toLowerCase() == filter.division!.id.toLowerCase();
      final divNameMatch = property.division.name.isNotEmpty &&
          property.division.name.toLowerCase() == filter.division!.name.toLowerCase();
      final divBnMatch = (property.division.bnName.isNotEmpty && filter.division!.bnName.isNotEmpty &&
              property.division.bnName == filter.division!.bnName) ||
          (property.division.bnName.isNotEmpty &&
              property.division.bnName.toLowerCase() == filter.division!.name.toLowerCase()) ||
          (filter.division!.bnName.isNotEmpty &&
              property.division.name.toLowerCase() == filter.division!.bnName.toLowerCase());
      if (!divIdMatch && !divNameMatch && !divBnMatch) return false;
    }

    // 2. District check
    if (filter.district != null && filter.district!.id.isNotEmpty) {
      final distIdMatch = property.district.id.isNotEmpty &&
          property.district.id.toLowerCase() == filter.district!.id.toLowerCase();
      final distNameMatch = property.district.name.isNotEmpty &&
          property.district.name.toLowerCase() == filter.district!.name.toLowerCase();
      final distBnMatch = (property.district.bnName.isNotEmpty && filter.district!.bnName.isNotEmpty &&
              property.district.bnName == filter.district!.bnName) ||
          (property.district.bnName.isNotEmpty &&
              property.district.bnName.toLowerCase() == filter.district!.name.toLowerCase()) ||
          (filter.district!.bnName.isNotEmpty &&
              property.district.name.toLowerCase() == filter.district!.bnName.toLowerCase());
      if (!distIdMatch && !distNameMatch && !distBnMatch) return false;
    }

    // 3. Upazila/Area check
    if (filter.upazila != null && filter.upazila!.id.isNotEmpty) {
      final upaIdMatch = property.area.id.isNotEmpty &&
          property.area.id.toLowerCase() == filter.upazila!.id.toLowerCase();
      final upaNameMatch = property.area.name.isNotEmpty &&
          property.area.name.toLowerCase() == filter.upazila!.name.toLowerCase();
      final upaBnMatch = (property.area.bnName.isNotEmpty && filter.upazila!.bnName.isNotEmpty &&
              property.area.bnName == filter.upazila!.bnName) ||
          (property.area.bnName.isNotEmpty &&
              property.area.bnName.toLowerCase() == filter.upazila!.name.toLowerCase()) ||
          (filter.upazila!.bnName.isNotEmpty &&
              property.area.name.toLowerCase() == filter.upazila!.bnName.toLowerCase());
      if (!upaIdMatch && !upaNameMatch && !upaBnMatch) return false;
    }

    // 4. Sub-Area check (OPTIONAL: only filter if user selected a sub-area)
    if (filter.area != null && filter.area!.id.isNotEmpty) {
      if (property.subArea == null) return false;
      final subIdMatch = property.subArea!.id.isNotEmpty &&
          property.subArea!.id.toLowerCase() == filter.area!.id.toLowerCase();
      final subNameMatch = property.subArea!.name.isNotEmpty &&
          property.subArea!.name.toLowerCase() == filter.area!.name.toLowerCase();
      final subBnMatch = (property.subArea!.bnName.isNotEmpty && filter.area!.bnName.isNotEmpty &&
              property.subArea!.bnName == filter.area!.bnName) ||
          (property.subArea!.bnName.isNotEmpty &&
              property.subArea!.bnName.toLowerCase() == filter.area!.name.toLowerCase()) ||
          (filter.area!.bnName.isNotEmpty &&
              property.subArea!.name.toLowerCase() == filter.area!.bnName.toLowerCase());
      if (!subIdMatch && !subNameMatch && !subBnMatch) return false;
    }

    // 5. Month check (Supports localized Bengali & English months)
    if (filter.month != null && filter.month!.trim().isNotEmpty) {
      if (!_matchesMonth(property.month, filter.month!)) return false;
    }

    // 6. House Type check
    if (filter.houseType != null && property.houseType != filter.houseType) {
      return false;
    }

    // 7. Tenant Type check
    if (filter.tenantType != null && property.tenantType != null) {
      if (property.tenantType != filter.tenantType) {
        return false;
      }
    }

    // 8. Budget Range check
    if (filter.budgetRange != null && filter.budgetRange!.trim().isNotEmpty) {
      if (!_matchesBudget(property.amount, filter.budgetRange!)) {
        return false;
      }
    }

    // 9. Optional Room/Seat check
    if (filter.roomOrSeat != null && filter.roomOrSeat!.trim().isNotEmpty) {
      if (!_matchesRoomOrSeat(property.roomOrSeat, filter.roomOrSeat!)) {
        return false;
      }
    }

    // 10. Optional Bathroom check
    if (filter.bathrooms != null) {
      final totalBaths = (property.attachedBathrooms ?? 0) + (property.commonBathrooms ?? 0);
      if (totalBaths < filter.bathrooms!) {
        return false;
      }
    }

    // 11. Optional Balconies filter
    if (filter.balconies != null && (property.balconies ?? 0) < filter.balconies!) {
      return false;
    }

    // 12. Optional Floor filter
    if (filter.floorNumber != null && property.floorNumber != null && property.floorNumber != filter.floorNumber) {
      return false;
    }

    // 13. Optional Parking filter
    if (filter.hasParking != null && property.hasParking != null && property.hasParking != filter.hasParking) {
      return false;
    }

    // 14. Optional Lift filter
    if (filter.hasLift != null && property.hasLift != null && property.hasLift != filter.hasLift) {
      return false;
    }

    return true;
  }

  List<PropertyModel> _processResults(List<PropertyModel> allProperties) {
    final f = _activeFilter;
    List<PropertyModel> results = [];

    if (f.isRadiusSearch) {
      results = allProperties.where((p) => _matchesRadius(p, f)).toList();
      final searchLat = f.searchLatitude ?? 23.8103;
      final searchLng = f.searchLongitude ?? 90.4125;
      final searchLatLng = LatLng(searchLat, searchLng);

      results.sort((a, b) {
        final latA = a.effectiveLatitude ?? searchLat;
        final lngA = a.effectiveLongitude ?? searchLng;
        final latB = b.effectiveLatitude ?? searchLat;
        final lngB = b.effectiveLongitude ?? searchLng;

        final distA = _distanceCalc.as(LengthUnit.Meter, searchLatLng, LatLng(latA, lngA));
        final distB = _distanceCalc.as(LengthUnit.Meter, searchLatLng, LatLng(latB, lngB));
        return distA.compareTo(distB);
      });
    } else {
      results = allProperties.where((p) => _matchesTraditionalFilter(p, f)).toList();
    }

    return results;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final languageCode = Localizations.localeOf(context).languageCode;
    final f = _activeFilter;

    final locationSummary = f.isRadiusSearch
        ? '${f.searchRadiusKm?.toInt() ?? 5} km ${l10n.distanceAway}'
        : [
            if (f.area != null) f.area!.getLocalizedName(languageCode),
            if (f.upazila != null) f.upazila!.getLocalizedName(languageCode),
            if (f.district != null) f.district!.getLocalizedName(languageCode),
          ].join(', ');

    return Scaffold(
      appBar: MainAppBar(
        automaticallyImplyLeading: true,
        title: Text(
          l10n.searchResult,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        actions: f.isRadiusSearch
            ? [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: Icon(
                      _isMapView ? Icons.format_list_bulleted_rounded : Icons.map_rounded,
                      color: AppColors.themeColor,
                    ),
                    tooltip: _isMapView ? l10n.listView : l10n.mapView,
                    onPressed: () {
                      setState(() {
                        _isMapView = !_isMapView;
                        _selectedMapProperty = null;
                      });
                    },
                  ),
                ),
              ]
            : null,
      ),
      body: StreamBuilder<List<PropertyModel>>(
        initialData: _service.latestAvailableProperties,
        stream: _propertiesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.themeColor),
            );
          }

          if (snapshot.hasError && !snapshot.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Error loading properties: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            );
          }

          final allProperties = snapshot.data ?? [];
          final results = _processResults(allProperties);

          if (_isMapView && f.isRadiusSearch) {
            return _buildInteractiveMapView(context, results, f, theme, isDark, l10n);
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: results.isEmpty ? 2 : results.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.themeColor.withValues(alpha: isDark ? 0.2 : 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.themeColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.themeColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            f.isRadiusSearch ? Icons.radar_rounded : Icons.location_on_rounded,
                            color: AppColors.themeColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                locationSummary,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${results.length} ${l10n.searchResult}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (f.isRadiusSearch)
                          FilledButton.tonalIcon(
                            onPressed: () {
                              setState(() {
                                _isMapView = true;
                              });
                            },
                            style: FilledButton.styleFrom(
                              minimumSize: Size.zero,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.map_rounded, size: 16),
                            label: Text(l10n.mapView, style: const TextStyle(fontSize: 12)),
                          ),
                      ],
                    ),
                  ),
                );
              }

              if (results.isEmpty) {
                return _buildEmptyState(context, f, l10n, allProperties, isDark);
              }

              final p = results[index - 1];
              double? distKm;
              if (f.isRadiusSearch && p.effectiveLatitude != null && p.effectiveLongitude != null) {
                final searchLat = f.searchLatitude ?? 23.8103;
                final searchLng = f.searchLongitude ?? 90.4125;
                distKm = _distanceCalc.as(
                  LengthUnit.Kilometer,
                  LatLng(searchLat, searchLng),
                  LatLng(p.effectiveLatitude!, p.effectiveLongitude!),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: PropertyCard(property: p, distanceKm: distKm),
              );
            },
          );
        },
      ),
    );
  }

  /// Interactive Map View with Search Radius Overlay & Property Pins
  Widget _buildInteractiveMapView(
    BuildContext context,
    List<PropertyModel> properties,
    SearchFilterModel filter,
    ThemeData theme,
    bool isDark,
    AppLocalizations l10n,
  ) {
    final centerLat = filter.searchLatitude ?? 23.8103;
    final centerLng = filter.searchLongitude ?? 90.4125;
    final centerLatLng = LatLng(centerLat, centerLng);
    final validProperties = properties.where((p) => p.effectiveLatitude != null && p.effectiveLongitude != null).toList();

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: centerLatLng,
            initialZoom: 13.5,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.bashabondhu_home_rental_management_system',
            ),

            // Search Center Circle & Radius Boundary
            CircleLayer(
              circles: [
                CircleMarker(
                  point: centerLatLng,
                  radius: (filter.searchRadiusKm ?? 5.0) * 1000,
                  useRadiusInMeter: true,
                  color: AppColors.themeColor.withValues(alpha: 0.12),
                  borderColor: AppColors.themeColor,
                  borderStrokeWidth: 2,
                ),
              ],
            ),

            // Markers Layer
            MarkerLayer(
              markers: [
                // 1. Center Search Marker
                Marker(
                  point: centerLatLng,
                  width: 44,
                  height: 44,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.my_location_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),

                // 2. Property Markers
                ...validProperties.map((p) {
                  final isSelected = _selectedMapProperty?.id == p.id;
                  final pLat = p.effectiveLatitude!;
                  final pLng = p.effectiveLongitude!;
                  return Marker(
                    point: LatLng(pLat, pLng),
                    width: 46,
                    height: 46,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedMapProperty = p;
                        });
                        _mapController.move(LatLng(pLat, pLng), 15.0);
                      },
                      child: AnimatedScale(
                        scale: isSelected ? 1.2 : 1.0,
                        duration: const Duration(milliseconds: 150),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.deepOrange : Colors.redAccent,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: isSelected ? 3 : 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isSelected ? 0.4 : 0.25),
                                blurRadius: isSelected ? 10 : 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.home_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),

        // Floating Switch to List View Button on Top Right
        Positioned(
          top: 16,
          right: 16,
          child: FloatingActionButton.extended(
            heroTag: 'switchToList',
            backgroundColor: isDark ? const Color(0xFF1E2827) : Colors.white,
            foregroundColor: AppColors.themeColor,
            elevation: 4,
            icon: const Icon(Icons.format_list_bulleted_rounded),
            label: Text(
              '${l10n.listView} (${validProperties.length})',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              setState(() {
                _isMapView = false;
              });
            },
          ),
        ),

        // Selected Property Bottom Card Preview
        if (_selectedMapProperty != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: _buildSelectedPropertyCard(context, _selectedMapProperty!, l10n, isDark),
          ),
      ],
    );
  }

  Widget _buildSelectedPropertyCard(
    BuildContext context,
    PropertyModel p,
    AppLocalizations l10n,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2827) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Image Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 70,
              height: 70,
              child: p.images.isNotEmpty
                  ? AppImageWidget(
                      imageSource: p.images.first,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.home_rounded, color: Colors.grey),
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '৳ ${p.amount}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.themeColor,
                  ),
                ),
                Text(
                  '${p.houseType.getLocalizedLabel(l10n)} • ${p.roomOrSeat.getLocalizedRoomOrSeat(l10n)}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                ),
                Text(
                  p.shortAddress,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // View Details Action
          FilledButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PropertyDetailsScreen(property: p),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.themeColor,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              l10n.viewDetails,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    SearchFilterModel f,
    AppLocalizations l10n,
    List<PropertyModel> allProperties,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final isBn = languageCode == 'bn';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        children: [
          // 1. Icon Container
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: isDark ? 0.15 : 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.amber.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 58,
              color: Colors.amber,
            ),
          ),
          const SizedBox(height: 18),

          // 2. Title
          Text(
            l10n.noHousesFoundTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 19,
            ),
          ),
          const SizedBox(height: 10),

          // 3. Informational Subtitle
          Text(
            f.isRadiusSearch
                ? (isBn
                    ? 'আপনার অবস্থান থেকে ${f.searchRadiusKm?.toInt() ?? 5} কিমি দূরত্বের মধ্যে কোনো বাসা পাওয়া যায়নি। পরিধি বাড়িয়ে অথবা ফিল্টার পরিবর্তন করে চেষ্টা করুন।'
                    : 'No rental homes found within ${f.searchRadiusKm?.toInt() ?? 5} km of your selected center. Try expanding the radius.')
                : l10n.noHousesFoundSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),

          // 4. Quick Radius Expansion Chips (in Radius Mode)
          if (f.isRadiusSearch) ...[
            Text(
              isBn ? 'দ্রুত পরিধি বাড়ান:' : 'Quickly expand radius:',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.add_location_alt_outlined, size: 16, color: AppColors.themeColor),
                  label: Text(isBn ? '১০ কিমি করুন' : '10 km Radius'),
                  onPressed: () {
                    setState(() {
                      _activeFilter = _activeFilter.copyWith(searchRadiusKm: 10.0);
                    });
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.add_location_alt_outlined, size: 16, color: AppColors.themeColor),
                  label: Text(isBn ? '২০ কিমি করুন' : '20 km Radius'),
                  onPressed: () {
                    setState(() {
                      _activeFilter = _activeFilter.copyWith(searchRadiusKm: 20.0);
                    });
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.travel_explore_rounded, size: 16, color: Colors.teal),
                  label: Text(isBn ? '৩০ কিমি করুন' : '30 km Radius'),
                  onPressed: () {
                    setState(() {
                      _activeFilter = _activeFilter.copyWith(searchRadiusKm: 30.0);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],

          // 5. Main Action Buttons
          Wrap(
            spacing: 12,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: Text(
                  l10n.changeFilters,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.themeColor,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              if (f.isRadiusSearch)
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isMapView = true;
                    });
                  },
                  icon: const Icon(Icons.map_rounded, size: 18, color: AppColors.themeColor),
                  label: Text(
                    l10n.mapView,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.themeColor,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.themeColor),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}