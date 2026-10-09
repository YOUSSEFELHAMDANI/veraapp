import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../theme/app_theme.dart';

const String kGooglePlacesApiKey = 'AIzaSyAW1mx__G_waL0pFLRi-V6wOXVLYmzPl2o';

class PlaceAutocompleteResult {
  final String description;
  final String placeId;
  double? lat;
  double? lng;
  String? city;
  String? country;

  PlaceAutocompleteResult({
    required this.description,
    required this.placeId,
    this.lat,
    this.lng,
    this.city,
    this.country,
  });
}

class PlaceAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final String? country;
  final ValueChanged<PlaceAutocompleteResult?>? onSelected;

  const PlaceAutocompleteField({
    super.key,
    required this.controller,
    this.hintText = 'Search address...',
    this.country = 'ae',
    this.onSelected,
  });

  @override
  State<PlaceAutocompleteField> createState() => _PlaceAutocompleteFieldState();
}

class _PlaceAutocompleteFieldState extends State<PlaceAutocompleteField> {
  List<PlaceAutocompleteResult> _suggestions = [];
  bool _isLoading = false;
  bool _hasFocus = false;
  String _lastQuery = '';
  String? _apiError;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) setState(() => _hasFocus = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _searchPlaces(String query) async {
    if (query.length < 3) {
      if (mounted) setState(() { _suggestions = []; _apiError = null; });
      return;
    }
    if (query == _lastQuery) return;
    _lastQuery = query;

    if (mounted) setState(() { _isLoading = true; _apiError = null; });

    try {
      // Places API (New) — POST endpoint
      final body = <String, dynamic>{
        'input': query,
        'languageCode': 'ar',
      };
      if (widget.country != null) {
        body['includedRegionCodes'] = [widget.country];
      }
      // Bias to UAE center: Dubai
      body['locationBias'] = {
        'circle': {
          'center': {'latitude': 25.2048, 'longitude': 55.2708},
          'radius': 50000.0,
        }
      };

      final resp = await http.post(
        Uri.parse('https://places.googleapis.com/v1/places:autocomplete'),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': kGooglePlacesApiKey,
          'X-Goog-FieldMask': 'suggestions.placePrediction.placeId,suggestions.placePrediction.text.text',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final suggestions = data['suggestions'] as List? ?? [];
        _suggestions = [];
        for (final s in suggestions) {
          final pred = s['placePrediction'];
          if (pred != null) {
            final text = pred['text']?['text'] ?? '';
            final placeId = pred['placeId'] ?? '';
            if (text.isNotEmpty && placeId.isNotEmpty) {
              _suggestions.add(PlaceAutocompleteResult(
                description: text,
                placeId: placeId,
              ));
            }
          }
        }
      } else {
        final err = jsonDecode(resp.body);
        _apiError = err['error']?['message'] ?? 'HTTP ${resp.statusCode}';
      }
    } catch (e) {
      _apiError = e.toString();
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _selectPlace(PlaceAutocompleteResult place) async {
    widget.controller.text = place.description;
    _lastQuery = place.description;
    if (mounted) setState(() { _suggestions = []; _isLoading = true; });

    try {
      // Place Details (New) — GET endpoint
      final resp = await http.get(
        Uri.parse('https://places.googleapis.com/v1/places/${place.placeId}'),
        headers: {
          'X-Goog-Api-Key': kGooglePlacesApiKey,
          'X-Goog-FieldMask': 'location,addressComponents',
        },
      ).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final loc = data['location'];
        place.lat = loc?['latitude']?.toDouble();
        place.lng = loc?['longitude']?.toDouble();
        final comps = data['addressComponents'] as List? ?? [];
        for (final c in comps) {
          final types = (c['types'] as List?)?.cast<String>() ?? [];
          if (types.contains('locality') || types.contains('administrative_area_level_2')) {
            place.city = c['longText'] ?? c['shortText'];
          }
        }
      }
    } catch (e) {
      debugPrint('Place details error: $e');
    }

    _focusNode.unfocus();
    if (mounted) setState(() => _isLoading = false);
    widget.onSelected?.call(place);
  }

  @override
  Widget build(BuildContext context) {
    final showSuggestions = _hasFocus && (_suggestions.isNotEmpty || _apiError != null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          onChanged: _searchPlaces,
          style: GoogleFonts.cairo(fontSize: 14, color: AppTheme.charcoal),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: GoogleFonts.cairo(color: AppTheme.grayText, fontSize: 13),
            prefixIcon: Icon(Icons.search_rounded, color: AppTheme.primaryPinkDark, size: 22),
            suffixIcon: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : widget.controller.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, size: 18, color: AppTheme.grayText),
                        onPressed: () {
                          widget.controller.clear();
                          setState(() { _suggestions = []; _lastQuery = ''; _apiError = null; });
                          widget.onSelected?.call(null);
                        },
                      )
                    : null,
            filled: true,
            fillColor: AppTheme.surfaceLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primaryPinkDark, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
        if (showSuggestions)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 250),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: _apiError != null
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, size: 16, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _apiError!,
                            style: GoogleFonts.cairo(fontSize: 12, color: Colors.red.shade700),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    shrinkWrap: true,
                    itemCount: _suggestions.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
                    itemBuilder: (context, index) {
                      final s = _suggestions[index];
                      return InkWell(
                        onTap: () => _selectPlace(s),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: 20, color: AppTheme.primaryPinkDark),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  s.description,
                                  style: GoogleFonts.cairo(fontSize: 13, color: AppTheme.charcoal),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
      ],
    );
  }
}
