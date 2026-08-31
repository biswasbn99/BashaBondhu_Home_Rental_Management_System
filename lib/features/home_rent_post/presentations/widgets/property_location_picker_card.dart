import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/extensions/utility_extension.dart';

class PropertyLocationPickerCard extends StatefulWidget {
  const PropertyLocationPickerCard({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.onLocationChanged,
  });

  final double? latitude;
  final double? longitude;
  final void Function(double? lat, double? lng) onLocationChanged;

  @override
  State<PropertyLocationPickerCard> createState() => _PropertyLocationPickerCardState();
}

class _PropertyLocationPickerCardState extends State<PropertyLocationPickerCard> {
  bool _isFetchingGps = false;

  Future<void> _fetchCurrentGpsLocation() async {
    final l10n = context.localizations;
    setState(() => _isFetchingGps = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.locationServiceDisabled)),
          );
        }
        setState(() => _isFetchingGps = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.locationPermissionDenied)),
            );
          }
          setState(() => _isFetchingGps = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.locationPermissionDenied)),
          );
        }
        setState(() => _isFetchingGps = false);
        return;
      }

      Position? position = await Geolocator.getLastKnownPosition();
      position ??= await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 5),
        ),
      );

      widget.onLocationChanged(position.latitude, position.longitude);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.themeColor,
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(l10n.locationPinned),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error getting GPS location: $e');
    } finally {
      if (mounted) setState(() => _isFetchingGps = false);
    }
  }

  void _openFullMapPickerWithCenter(LatLng center) {
    Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => _FullMapPickerDialog(
          initialLocation: center,
        ),
      ),
    ).then((selected) {
      if (selected != null) {
        widget.onLocationChanged(selected.latitude, selected.longitude);
        if (mounted) {
          final l10n = context.localizations;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.themeColor,
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(l10n.locationPinned),
                ],
              ),
            ),
          );
        }
      }
    });
  }

  /// Opens Pick on Map screen (with Search bar & center draggable target pin)
  void _openFullMapPicker() {
    final initialLat = widget.latitude ?? 23.8103; // Default Dhaka Center
    final initialLng = widget.longitude ?? 90.4125;
    _openFullMapPickerWithCenter(LatLng(initialLat, initialLng));
  }

  /// Opens View Full Map screen (Fixed marker pinned to exact location, no search bar, scrollable & zoomable)
  void _openFullMapViewer() {
    if (widget.latitude == null || widget.longitude == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => _FullMapViewerDialog(
          location: LatLng(widget.latitude!, widget.longitude!),
          onChangeLocationRequested: _openFullMapPicker,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasLocation = widget.latitude != null && widget.longitude != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2827) : const Color(0xFFF7FAFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasLocation
              ? AppColors.themeColor.withValues(alpha: 0.5)
              : (isDark ? Colors.grey[800]! : Colors.grey[300]!),
          width: hasLocation ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.themeColor.withValues(alpha: isDark ? 0.25 : 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.map_rounded,
                  color: AppColors.themeColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.propertyMapLocation,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                      ),
                    ),
                    Text(
                      l10n.mapLocationSubtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // If Location is Selected -> Show Interactive Scrollable Mini-Map Preview with Full Screen Expand Button
          if (hasLocation) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 160,
                width: double.infinity,
                child: Stack(
                  children: [
                    FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(widget.latitude!, widget.longitude!),
                        initialZoom: 15.5,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.bashabondhu_home_rental_management_system',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(widget.latitude!, widget.longitude!),
                              width: 44,
                              height: 44,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
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
                                  Icons.home_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Coordinates Badge on Top Left
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${widget.latitude!.toStringAsFixed(4)}°, ${widget.longitude!.toStringAsFixed(4)}°',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // Expand / View Full Map Button on Top Right
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _openFullMapViewer,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.themeColor.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.fullscreen_rounded,
                                  color: Colors.white,
                                  size: 15,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  l10n.viewLargeMap,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Action Buttons (Change Location / Remove)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openFullMapPicker,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.themeColor,
                      side: const BorderSide(color: AppColors.themeColor),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.edit_location_alt_rounded, size: 16),
                    label: Text(l10n.changeLocation, style: const TextStyle(fontSize: 12.5)),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () => widget.onLocationChanged(null, null),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: Text(l10n.clearLocation, style: const TextStyle(fontSize: 12.5)),
                ),
              ],
            ),
          ] else ...[
            // If No Location Picked -> 2 Action Buttons
            Row(
              children: [
                // 1. GPS Auto-Locate Button (Directly sets current location in card)
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isFetchingGps ? null : _fetchCurrentGpsLocation,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.themeColor.withValues(alpha: isDark ? 0.25 : 0.12),
                      foregroundColor: AppColors.themeColor,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: AppColors.themeColor.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    icon: _isFetchingGps
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.themeColor,
                            ),
                          )
                        : const Icon(Icons.my_location_rounded, size: 16),
                    label: Text(
                      _isFetchingGps ? l10n.fetchingLocation : l10n.useCurrentLocation,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // 2. Open Full Map Picker Button (Pick on Map)
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _openFullMapPicker,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.themeColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.pin_drop_rounded, size: 16),
                    label: Text(
                      l10n.pickOnMap,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Full-Screen View-Only Map Dialog (Fixed House Marker pinned to exact location, No Search Bar, Full Pan/Zoom)
class _FullMapViewerDialog extends StatefulWidget {
  const _FullMapViewerDialog({
    required this.location,
    this.onChangeLocationRequested,
  });

  final LatLng location;
  final VoidCallback? onChangeLocationRequested;

  @override
  State<_FullMapViewerDialog> createState() => _FullMapViewerDialogState();
}

class _FullMapViewerDialogState extends State<_FullMapViewerDialog> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  void _recenterOnHome() {
    _mapController.move(widget.location, 16.0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.viewLargeMap,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_rounded, color: AppColors.themeColor),
            tooltip: l10n.propertyMapLocation,
            onPressed: _recenterOnHome,
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Interactive Map with Fixed House Marker pinned to exact geo-coordinates
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.location,
              initialZoom: 16.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.bashabondhu_home_rental_management_system',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: widget.location,
                    width: 52,
                    height: 52,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.home_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 2. Floating Zoom Controls (+ and -) on Right
          Positioned(
            right: 16,
            bottom: 90,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'viewerZoomIn',
                  backgroundColor: isDark ? const Color(0xFF1E2827) : Colors.white,
                  foregroundColor: isDark ? Colors.white : Colors.black87,
                  child: const Icon(Icons.add_rounded),
                  onPressed: () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom + 1,
                    );
                  },
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'viewerZoomOut',
                  backgroundColor: isDark ? const Color(0xFF1E2827) : Colors.white,
                  foregroundColor: isDark ? Colors.white : Colors.black87,
                  child: const Icon(Icons.remove_rounded),
                  onPressed: () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom - 1,
                    );
                  },
                ),
              ],
            ),
          ),

          // 3. Bottom Card with Coordinates and Change Location button
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A2221) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.themeColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: AppColors.themeColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.locationPinned,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                        ),
                        Text(
                          '${widget.location.latitude.toStringAsFixed(5)}°, ${widget.location.longitude.toStringAsFixed(5)}°',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.onChangeLocationRequested != null) ...[
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onChangeLocationRequested!();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.themeColor,
                        side: const BorderSide(color: AppColors.themeColor),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.edit_location_alt_rounded, size: 15),
                      label: Text(l10n.changeLocation, style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-Screen Interactive OpenStreetMap Location Picker with Search & Target Pin
class _FullMapPickerDialog extends StatefulWidget {
  const _FullMapPickerDialog({required this.initialLocation});

  final LatLng initialLocation;

  @override
  State<_FullMapPickerDialog> createState() => _FullMapPickerDialogState();
}

class _FullMapPickerDialogState extends State<_FullMapPickerDialog> {
  late final MapController _mapController;
  late LatLng _selectedLocation;
  bool _isDragging = false;

  // Search State
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedLocation = widget.initialLocation;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _searchPlaces(String query) async {
    final clean = query.trim();
    if (clean.length < 2) {
      setState(() {
        _searchResults = [];
        _showSuggestions = false;
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final encoded = Uri.encodeComponent(clean);
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$encoded&format=json&limit=5&countrycodes=bd',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'BashaBondhuApp/1.0 (contact@bashabondhu.com)'},
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _searchResults = data.map<Map<String, dynamic>>((e) {
              return {
                'name': e['name']?.toString().isNotEmpty == true ? e['name'] : e['display_name'].toString().split(',').first,
                'display_name': e['display_name'] ?? '',
                'lat': double.tryParse(e['lat'].toString()) ?? 0.0,
                'lon': double.tryParse(e['lon'].toString()) ?? 0.0,
              };
            }).toList();
            _showSuggestions = true;
            _isSearching = false;
          });
        }
      } else {
        if (mounted) setState(() => _isSearching = false);
      }
    } catch (e) {
      debugPrint('Search error: $e');
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _searchPlaces(query);
    });
  }

  void _selectSearchResult(Map<String, dynamic> item) {
    final lat = item['lat'] as double;
    final lon = item['lon'] as double;
    final latLng = LatLng(lat, lon);

    setState(() {
      _selectedLocation = latLng;
      _showSuggestions = false;
      _searchController.text = item['name'] ?? '';
    });

    FocusScope.of(context).unfocus();
    _mapController.move(latLng, 16.5);
  }

  Future<void> _moveToCurrentGps() async {
    try {
      Position? pos = await Geolocator.getLastKnownPosition();
      pos ??= await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 5),
        ),
      );
      final latLng = LatLng(pos.latitude, pos.longitude);
      setState(() => _selectedLocation = latLng);
      _mapController.move(latLng, 16.5);
    } catch (e) {
      debugPrint('Error moving to GPS: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          l10n.pickOnMap,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location_rounded, color: AppColors.themeColor),
            tooltip: l10n.useCurrentLocation,
            onPressed: _moveToCurrentGps,
          ),
        ],
      ),
      body: Stack(
        children: [
          // --- 1. Interactive OpenStreetMap (Supports full drag, pan, zoom in all directions) ---
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialLocation,
              initialZoom: 15.5,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onPositionChanged: (camera, hasGesture) {
                if (hasGesture) {
                  setState(() {
                    _selectedLocation = camera.center;
                    _isDragging = true;
                  });
                }
              },
              onMapEvent: (event) {
                if (event is MapEventMoveEnd) {
                  setState(() {
                    _isDragging = false;
                    _selectedLocation = _mapController.camera.center;
                  });
                }
              },
              onTap: (tapPosition, point) {
                setState(() {
                  _selectedLocation = point;
                });
                _mapController.move(point, _mapController.camera.zoom);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.bashabondhu_home_rental_management_system',
              ),
            ],
          ),

          // --- 2. Fixed Center Target House Pin (Touches pass through to map) ---
          IgnorePointer(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 36),
                child: AnimatedScale(
                  scale: _isDragging ? 1.15 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: _isDragging ? 0.45 : 0.25),
                              blurRadius: _isDragging ? 14 : 8,
                              offset: Offset(0, _isDragging ? 8 : 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.home_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.black45,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // --- 3. Top Floating Search Bar & Auto-Complete Suggestions ---
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2827) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: l10n.searchAddressOrArea,
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.themeColor),
                      suffixIcon: _isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.themeColor,
                                ),
                              ),
                            )
                          : _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchResults = [];
                                      _showSuggestions = false;
                                    });
                                  },
                                )
                              : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),

                // Search Results Dropdown
                if (_showSuggestions && _searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    constraints: const BoxConstraints(maxHeight: 220),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: isDark ? const Color(0xFF1E2827) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      clipBehavior: Clip.antiAlias,
                      child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = _searchResults[index];
                        return ListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          leading: const Icon(
                            Icons.location_on_rounded,
                            color: AppColors.themeColor,
                            size: 20,
                          ),
                          title: Text(
                            item['name'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          subtitle: Text(
                            item['display_name'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                          ),
                          onTap: () => _selectSearchResult(item),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- 4. Floating Zoom Controls (+ and -) on Right ---
          Positioned(
            right: 16,
            bottom: 110,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoomIn',
                  backgroundColor: isDark ? const Color(0xFF1E2827) : Colors.white,
                  foregroundColor: isDark ? Colors.white : Colors.black87,
                  child: const Icon(Icons.add_rounded),
                  onPressed: () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom + 1,
                    );
                  },
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoomOut',
                  backgroundColor: isDark ? const Color(0xFF1E2827) : Colors.white,
                  foregroundColor: isDark ? Colors.white : Colors.black87,
                  child: const Icon(Icons.remove_rounded),
                  onPressed: () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom - 1,
                    );
                  },
                ),
              ],
            ),
          ),

          // --- 5. Bottom Confirmation Bar with Live Coordinates ---
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A2221) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.themeColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.touch_app_rounded,
                          color: AppColors.themeColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.dragMapToAdjust,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              '${_selectedLocation.latitude.toStringAsFixed(5)}°, ${_selectedLocation.longitude.toStringAsFixed(5)}°',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, _selectedLocation),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.themeColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        l10n.confirmLocation,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
