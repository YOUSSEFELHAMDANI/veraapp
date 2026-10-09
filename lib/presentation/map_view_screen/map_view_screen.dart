import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../services/vera_api_service.dart';

class MapViewScreen extends StatefulWidget {
  final String mode;

  const MapViewScreen({super.key, this.mode = 'services'});

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  Position? _currentPosition;
  bool _isLoading = true;
  String? _error;
  Set<Marker> _markers = {};
  List<VeraService> _services = [];
  VeraService? _selectedService;

  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(25.2048, 55.2708),
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _getCurrentLocation();
    await _loadServices();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _error = 'location_disabled';
          _isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _error = 'location_denied';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _error = 'location_denied_forever';
          _isLoading = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      setState(() {
        _currentPosition = position;
        _markers.add(
          Marker(
            markerId: const MarkerId('current_location'),
            position: LatLng(position.latitude, position.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRose,
            ),
            infoWindow: InfoWindow(
              title: 'موقعك الحالي',
            ),
          ),
        );
      });

      final controller = await _mapController.future;
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 14,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _error = 'location_error';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadServices() async {
    try {
      final services = await VeraApiService.instance.fetchServices();
      setState(() {
        _services = services;
        _isLoading = false;
      });
      _addServiceMarkers();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addServiceMarkers() {
    if (_currentPosition == null) return;

    final cityGroups = <String, List<VeraService>>{};
    for (final s in _services) {
      final city = s.providerCity.isNotEmpty ? s.providerCity : 'Dubai';
      cityGroups.putIfAbsent(city, () => []).add(s);
    }

    final cityCoords = <String, LatLng>{
      'Dubai': const LatLng(25.2048, 55.2708),
      'Abu Dhabi': const LatLng(24.4539, 54.3773),
      'Sharjah': const LatLng(25.3463, 55.4209),
      'Ajman': const LatLng(25.4052, 55.5136),
      'Ras Al Khaimah': const LatLng(25.7894, 55.9432),
      'Fujairah': const LatLng(25.1288, 56.3264),
      'Umm Al Quwain': const LatLng(25.5204, 55.5618),
    };

    final newMarkers = <Marker>{
      if (_currentPosition != null)
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRose,
          ),
          infoWindow: const InfoWindow(title: 'موقعك الحالي'),
        ),
    };

    for (final entry in cityGroups.entries) {
      final coords = cityCoords[entry.key];
      if (coords == null) continue;

      final service = entry.value.first;
      newMarkers.add(
        Marker(
          markerId: MarkerId('city_${entry.key}'),
          position: coords,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          ),
          onTap: () => setState(() => _selectedService = service),
          infoWindow: InfoWindow(
            title: entry.key,
            snippet: '${entry.value.length} خدمة متاحة',
          ),
        ),
      );
    }

    setState(() => _markers = newMarkers);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _currentPosition != null
                ? CameraPosition(
                    target: LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    ),
                    zoom: 14,
                  )
                : _defaultPosition,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            markers: _markers,
            onMapCreated: (controller) {
              if (!_mapController.isCompleted) {
                _mapController.complete(controller);
              }
            },
            onCameraMove: (_) {},
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
            rotateGesturesEnabled: true,
            scrollGesturesEnabled: true,
            tiltGesturesEnabled: true,
          ),

          if (_isLoading)
            Container(
              color: AppTheme.backgroundLight,
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryPink,
                ),
              ),
            ),

          if (_error != null)
            Center(
              child: Container(
                margin: const EdgeInsets.all(40),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _error == 'location_disabled'
                          ? Icons.location_off_outlined
                          : Icons.location_searching,
                      size: 48,
                      color: AppTheme.primaryPink,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _error == 'location_disabled'
                          ? 'يرجى تفعيل خدمات الموقع'
                          : _error == 'location_denied'
                              ? 'يرجى منح صلاحية الموقع'
                              : 'حدث خطأ في تحديد الموقع',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.charcoal,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        setState(() {
                          _error = null;
                          _isLoading = true;
                        });
                        await _init();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryPink,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'إعادة المحاولة',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLight,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(20),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                            color: AppTheme.charcoal,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLight,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(20),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 12),
                              Icon(
                                Icons.search_rounded,
                                size: 16,
                                color: AppTheme.grayText,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  widget.mode == 'real_estate'
                                      ? l10n.t('realEstateMap')
                                      : l10n.t('servicesMap'),
                                  style: GoogleFonts.cairo(
                                    fontSize: 13,
                                    color: AppTheme.grayText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildFilterChip(l10n.allLabel, true),
                      const SizedBox(width: 8),
                      _buildFilterChip(l10n.t('clinics'), false),
                      const SizedBox(width: 8),
                      _buildFilterChip(l10n.t('salons'), false),
                      const SizedBox(width: 8),
                      _buildFilterChip(l10n.t('gym'), false),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (_selectedService != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 32,
              child: _buildServicePreview(l10n),
            ),

          Positioned(
            right: 16,
            bottom: _selectedService != null ? 200 : 100,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 16,
                    color: AppTheme.primaryPink,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_services.length} ${l10n.allLabel}',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.charcoal,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_currentPosition != null)
            Positioned(
              right: 16,
              bottom: _selectedService != null ? 160 : 60,
              child: GestureDetector(
                onTap: () async {
                  final controller = await _mapController.future;
                  controller.animateCamera(
                    CameraUpdate.newCameraPosition(
                      CameraPosition(
                        target: LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        ),
                        zoom: 14,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(20),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.my_location_rounded,
                    size: 20,
                    color: AppTheme.primaryPink,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.primaryPink : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: GoogleFonts.cairo(
          fontSize: 12,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          color: isActive ? Colors.white : AppTheme.charcoal,
        ),
      ),
    );
  }

  Widget _buildServicePreview(AppLocalizations l10n) {
    final service = _selectedService!;
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(30),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: service.imageUrl.isNotEmpty
                  ? Image.network(
                      VeraApiService.resolveAssetUrl(service.imageUrl),
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 120,
                        color: AppTheme.primaryPinkLight,
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: AppTheme.primaryPinkDark,
                        ),
                      ),
                    )
                  : Container(
                      height: 120,
                      color: AppTheme.primaryPinkLight,
                      child: Icon(
                        Icons.local_offer_outlined,
                        size: 32,
                        color: AppTheme.primaryPinkDark,
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          service.name,
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.charcoal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryPink,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          l10n.localizePrice(
                            'From AED ${service.price.toStringAsFixed(0)}',
                          ),
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppTheme.grayText,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          service.providerCity.isNotEmpty
                              ? service.providerCity
                              : service.category,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: AppTheme.grayText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (service.rating > 0) ...[
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: Color(0xFFFFC107),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          service.rating.toStringAsFixed(1),
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.charcoal,
                          ),
                        ),
                      ],
                    ],
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
