import 'package:flutter/material.dart';
import 'package:hudhud_delivery/app/services/nominatim_service.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';

class LocationSearchField extends StatefulWidget {
  final String hintText;
  final TextEditingController? controller;
  final Function(PlaceResult) onLocationSelected;
  final String? initialLocation;
  final bool autofocus;

  const LocationSearchField({
    Key? key,
    this.hintText = 'Search for location...',
    this.controller,
    required this.onLocationSelected,
    this.initialLocation,
    this.autofocus = false,
  }) : super(key: key);

  @override
  State<LocationSearchField> createState() => _LocationSearchFieldState();
}

class _LocationSearchFieldState extends State<LocationSearchField> {
  final FocusNode _focusNode = FocusNode();
  late TextEditingController _controller;
  List<PlaceResult> _suggestions = [];
  bool _isLoading = false;
  bool _showSuggestions = false;
  bool _usingFallbackData = false;
  
  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    
    if (widget.initialLocation != null) {
      _controller.text = widget.initialLocation!;
    }
    
    _controller.addListener(_onSearchChanged);
    _focusNode.addListener(() {
      // Show suggestions when field is focused and has text
      if (_focusNode.hasFocus && _controller.text.isNotEmpty) {
        setState(() {
          _showSuggestions = true;
        });
      } else {
        // Hide suggestions when focus is lost
        setState(() {
          _showSuggestions = false;
        });
      }
    });
  }
  
  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    _controller.removeListener(_onSearchChanged);
    _focusNode.dispose();
    super.dispose();
  }
  
  void _onSearchChanged() {
    if (_controller.text.isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }
    
    _searchPlaces(_controller.text);
  }
  
  Future<void> _searchPlaces(String query) async {
    if (query.trim().length < 2) return;
    
    setState(() {
      _isLoading = true;
      _showSuggestions = true;
    });
    
    try {
      final results = await NominatimService.searchPlaces(query);
      if (mounted) {
        setState(() {
          _suggestions = results;
          _isLoading = false;
          _usingFallbackData = results.isNotEmpty && results.first.displayName.contains('Ethiopia');
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _usingFallbackData = true;
        });
      }
      print('Error searching places: $e');
    }
  }
  
  void _selectLocation(PlaceResult place) {
    _controller.text = place.shortAddress;
    widget.onLocationSelected(place);
    setState(() {
      _showSuggestions = false;
    });
    _focusNode.unfocus();
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          autofocus: widget.autofocus,
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            suffixIcon: _buildSuffixIcon(),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primaryColor),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onTap: () {
            if (_controller.text.isNotEmpty) {
              setState(() {
                _showSuggestions = true;
              });
            }
          },
        ),
        if (_usingFallbackData && _showSuggestions)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 8.0),
            child: Text(
              'Using offline location data',
              style: TextStyle(color: Colors.orange[700], fontSize: 12),
            ),
          ),
        if (_showSuggestions) _buildSuggestionsDropdown(),
      ],
    );
  }
  
  Widget? _buildSuffixIcon() {
    if (_isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: Padding(
          padding: EdgeInsets.all(12.0),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    } else if (_controller.text.isNotEmpty) {
      return IconButton(
        icon: const Icon(Icons.clear, color: Colors.grey),
        onPressed: () {
          _controller.clear();
          setState(() {
            _suggestions = [];
            _showSuggestions = false;
          });
        },
      );
    }
    return null;
  }
  
  Widget _buildSuggestionsDropdown() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 250),
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _suggestions.isEmpty
          ? _isLoading
              ? const Center(child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ))
              : ListTile(
                  title: Text(
                    'No locations found',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
          : ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final place = _suggestions[index];
                return ListTile(
                  leading: const Icon(Icons.location_on, color: Colors.red),
                  title: Text(
                    place.shortAddress,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    place.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => _selectLocation(place),
                );
              },
            ),
    );
  }
}