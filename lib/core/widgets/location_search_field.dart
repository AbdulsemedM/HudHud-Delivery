import 'package:flutter/material.dart';
import 'package:hudhud_delivery/app/services/google_places_service.dart';
import 'package:hudhud_delivery/app/models/place_result.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

class LocationSearchField extends StatefulWidget {
  final String? hintText;
  final TextEditingController? controller;
  final Function(PlaceResult) onLocationSelected;
  final String? initialLocation;
  final bool autofocus;

  const LocationSearchField({
    Key? key,
    this.hintText,
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

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();

    if (widget.initialLocation != null) {
      _controller.text = widget.initialLocation!;
    }

    _controller.addListener(_onSearchChanged);
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _controller.text.isNotEmpty) {
        setState(() {
          _showSuggestions = true;
        });
      } else {
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
      final results = await GooglePlacesService.searchPlaces(query);
      if (mounted) {
        setState(() {
          _suggestions = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _isLoading = false;
        });
      }
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
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final hint = widget.hintText ?? l10n.searchLocationHint;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          autofocus: widget.autofocus,
          style: TextStyle(color: colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
            prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
            suffixIcon: _buildSuffixIcon(colorScheme),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outlineVariant),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onTap: () {
            if (_controller.text.isNotEmpty) {
              setState(() {
                _showSuggestions = true;
              });
            }
          },
        ),
        if (_showSuggestions)
          _buildSuggestionsDropdown(colorScheme, l10n),
      ],
    );
  }

  Widget? _buildSuffixIcon(ColorScheme colorScheme) {
    if (_isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colorScheme.primary,
          ),
        ),
      );
    } else if (_controller.text.isNotEmpty) {
      return IconButton(
        icon: Icon(Icons.clear, color: colorScheme.onSurfaceVariant),
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

  Widget _buildSuggestionsDropdown(
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    return Material(
      elevation: 2,
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      shadowColor: colorScheme.shadow.withValues(alpha: 0.18),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 250),
        margin: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: _suggestions.isEmpty
            ? _isLoading
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(
                        color: colorScheme.primary,
                      ),
                    ),
                  )
                : ListTile(
                    title: Text(
                      l10n.locationSearchNoResults,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  )
            : ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final place = _suggestions[index];
                  return ListTile(
                    leading: Icon(
                      Icons.location_on,
                      color: colorScheme.primary,
                    ),
                    title: Text(
                      place.shortAddress,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      place.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                    onTap: () => _selectLocation(place),
                  );
                },
              ),
      ),
    );
  }
}
