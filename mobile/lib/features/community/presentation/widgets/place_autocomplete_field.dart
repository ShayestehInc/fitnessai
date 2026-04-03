import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// Result from Google Places autocomplete selection.
class PlaceResult {
  final String address;
  final double lat;
  final double lng;

  const PlaceResult({
    required this.address,
    required this.lat,
    required this.lng,
  });
}

/// A text field with Google Places autocomplete suggestions.
///
/// Uses the Google Places API (New) via HTTP — no extra native packages.
/// Requires a valid Google API key with Places API enabled.
class PlaceAutocompleteField extends StatefulWidget {
  final String? initialAddress;
  final String apiKey;
  final ValueChanged<PlaceResult?> onPlaceSelected;

  const PlaceAutocompleteField({
    super.key,
    this.initialAddress,
    required this.apiKey,
    required this.onPlaceSelected,
  });

  @override
  State<PlaceAutocompleteField> createState() =>
      _PlaceAutocompleteFieldState();
}

class _PlaceAutocompleteFieldState extends State<PlaceAutocompleteField> {
  late final TextEditingController _controller;
  final _dio = Dio();
  Timer? _debounce;
  List<_Suggestion> _suggestions = [];
  bool _showSuggestions = false;
  bool _isLoading = false;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialAddress ?? '');
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        setState(() => _showSuggestions = false);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    _dio.close();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 3) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _fetchSuggestions(value.trim());
    });
  }

  Future<void> _fetchSuggestions(String input) async {
    setState(() => _isLoading = true);
    try {
      final response = await _dio.post(
        'https://places.googleapis.com/v1/places:autocomplete',
        data: {'input': input},
        options: Options(headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': widget.apiKey,
        }),
      );
      final suggestions = <_Suggestion>[];
      final items = response.data['suggestions'] as List<dynamic>? ?? [];
      for (final item in items) {
        final prediction =
            item['placePrediction'] as Map<String, dynamic>?;
        if (prediction == null) continue;
        final placeId = prediction['placeId'] as String? ?? '';
        final text = prediction['text'] as Map<String, dynamic>? ?? {};
        final description = text['text'] as String? ?? '';
        if (placeId.isNotEmpty && description.isNotEmpty) {
          suggestions.add(_Suggestion(placeId: placeId, description: description));
        }
      }
      if (!mounted) return;
      setState(() {
        _suggestions = suggestions;
        _showSuggestions = suggestions.isNotEmpty;
        _isLoading = false;
      });
    } on Exception {
      if (!mounted) return;
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _selectSuggestion(_Suggestion suggestion) async {
    _controller.text = suggestion.description;
    setState(() {
      _showSuggestions = false;
      _isLoading = true;
    });

    try {
      final response = await _dio.get(
        'https://places.googleapis.com/v1/places/${suggestion.placeId}',
        queryParameters: {'languageCode': 'en'},
        options: Options(headers: {
          'X-Goog-Api-Key': widget.apiKey,
          'X-Goog-FieldMask': 'location,formattedAddress',
        }),
      );
      final data = response.data as Map<String, dynamic>;
      final location = data['location'] as Map<String, dynamic>?;
      final formattedAddress =
          data['formattedAddress'] as String? ?? suggestion.description;
      if (location != null) {
        final lat = (location['latitude'] as num).toDouble();
        final lng = (location['longitude'] as num).toDouble();
        _controller.text = formattedAddress;
        widget.onPlaceSelected(PlaceResult(
          address: formattedAddress,
          lat: lat,
          lng: lng,
        ));
      }
    } on Exception {
      // Still use the description even if geocode fails
      widget.onPlaceSelected(null);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _clear() {
    _controller.clear();
    widget.onPlaceSelected(null);
    setState(() {
      _suggestions = [];
      _showSuggestions = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: _onChanged,
          decoration: InputDecoration(
            labelText: 'Location',
            hintText: 'Search for an address...',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.location_on_outlined),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: _clear,
                  )
                : _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
          ),
        ),
        if (_showSuggestions)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.3),
              ),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final s = _suggestions[index];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.place, size: 18),
                  title: Text(
                    s.description,
                    style: const TextStyle(fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => _selectSuggestion(s),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _Suggestion {
  final String placeId;
  final String description;

  const _Suggestion({required this.placeId, required this.description});
}
