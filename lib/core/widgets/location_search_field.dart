import 'dart:math' as math;

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
  final bool useFormattedAddress;
  final bool expandSuggestions;
  final ValueChanged<bool>? onSearchActiveChanged;
  final void Function({
    required List<PlaceResult> suggestions,
    required bool isLoading,
    required bool show,
    required String query,
  })? onSuggestionsStateChanged;

  const LocationSearchField({
    Key? key,
    this.hintText,
    this.controller,
    required this.onLocationSelected,
    this.initialLocation,
    this.autofocus = false,
    this.useFormattedAddress = true,
    this.expandSuggestions = false,
    this.onSearchActiveChanged,
    this.onSuggestionsStateChanged,
  }) : super(key: key);

  @override
  State<LocationSearchField> createState() => _LocationSearchFieldState();

  /// Full-height suggestion list for parent-hosted expanded search (Easy Mode).
  static Widget buildExpandedSuggestionsList({
    required List<PlaceResult> suggestions,
    required bool isLoading,
    required String query,
    required bool useFormattedAddress,
    required void Function(PlaceResult place) onLocationSelected,
    required AppLocalizations l10n,
    required ColorScheme colorScheme,
  }) {
    if (suggestions.isEmpty) {
      if (isLoading) {
        return Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        );
      }
      return ListTile(
        title: Text(
          l10n.locationSearchNoResults,
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 4),
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final place = suggestions[index];
        final title =
            useFormattedAddress ? place.suggestionTitle : place.shortAddress;
        final subtitle =
            useFormattedAddress ? place.suggestionSubtitle : place.displayName;
        return ListTile(
          leading: Icon(Icons.location_on, color: colorScheme.primary),
          title: _highlightedTitle(title, query, colorScheme),
          subtitle: title.toLowerCase() != subtitle.toLowerCase()
              ? Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                )
              : null,
          onTap: () => onLocationSelected(place),
        );
      },
    );
  }

  static Widget _highlightedTitle(
    String title,
    String query,
    ColorScheme colorScheme,
  ) {
    if (query.length < 2) {
      return Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      );
    }

    final lowerTitle = title.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final matchIndex = lowerTitle.indexOf(lowerQuery);

    if (matchIndex < 0) {
      return Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      );
    }

    final before = title.substring(0, matchIndex);
    final match = title.substring(matchIndex, matchIndex + query.length);
    final after = title.substring(matchIndex + query.length);

    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
          fontSize: 16,
        ),
        children: [
          if (before.isNotEmpty) TextSpan(text: before),
          TextSpan(
            text: match,
            style: const TextStyle(
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (after.isNotEmpty) TextSpan(text: after),
        ],
      ),
    );
  }
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
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    _controller.removeListener(_onSearchChanged);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _notifySuggestionsState() {
    widget.onSuggestionsStateChanged?.call(
      suggestions: _suggestions,
      isLoading: _isLoading,
      show: _showSuggestions,
      query: _controller.text.trim(),
    );
  }

  void _onFocusChanged() {
    _updateSearchActive();
    if (_focusNode.hasFocus && _controller.text.isNotEmpty) {
      setState(() {
        _showSuggestions = true;
      });
      _notifySuggestionsState();
    } else if (!_focusNode.hasFocus) {
      setState(() {
        _showSuggestions = false;
      });
      _notifySuggestionsState();
    }
  }

  void _updateSearchActive() {
    final active =
        _focusNode.hasFocus && _controller.text.trim().length >= 2;
    widget.onSearchActiveChanged?.call(active);
  }

  void _onSearchChanged() {
    if (_controller.text.isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      _updateSearchActive();
      _notifySuggestionsState();
      return;
    }

    _updateSearchActive();
    _searchPlaces(_controller.text);
  }

  Future<void> _searchPlaces(String query) async {
    if (query.trim().length < 2) return;

    setState(() {
      _isLoading = true;
      _showSuggestions = true;
    });
    _notifySuggestionsState();

    try {
      final results = await GooglePlacesService.searchPlaces(query);
      if (mounted) {
        setState(() {
          _suggestions = results;
          _isLoading = false;
        });
        _notifySuggestionsState();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _isLoading = false;
        });
        _notifySuggestionsState();
      }
    }
  }

  void _selectLocation(PlaceResult place) {
    _controller.text = widget.useFormattedAddress
        ? place.formattedAddress
        : place.shortAddress;
    widget.onLocationSelected(place);
    setState(() {
      _showSuggestions = false;
    });
    _focusNode.unfocus();
    widget.onSearchActiveChanged?.call(false);
    _notifySuggestionsState();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final hint = widget.hintText ?? l10n.searchLocationHint;
    final query = _controller.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
              _notifySuggestionsState();
            }
            _updateSearchActive();
          },
        ),
        if (_showSuggestions && !widget.expandSuggestions)
          _buildSuggestionsDropdown(colorScheme, l10n, query),
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
          _updateSearchActive();
          _notifySuggestionsState();
        },
      );
    }
    return null;
  }

  Widget _buildSuggestionsDropdown(
    ColorScheme colorScheme,
    AppLocalizations l10n,
    String query,
  ) {
    return Material(
      elevation: 2,
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      shadowColor: colorScheme.shadow.withValues(alpha: 0.18),
      child: Builder(
        builder: (context) {
          final screenHeight = MediaQuery.sizeOf(context).height;
          final listMaxHeight = _suggestions.isEmpty
              ? 250.0
              : math.min(
                  _suggestions.length * 72.0 + 8,
                  screenHeight * 0.55,
                ).clamp(250.0, screenHeight * 0.55);

          return Container(
            constraints: BoxConstraints(maxHeight: listMaxHeight),
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: _buildSuggestionsList(colorScheme, l10n, query),
          );
        },
      ),
    );
  }

  Widget _buildSuggestionsList(
    ColorScheme colorScheme,
    AppLocalizations l10n,
    String query,
  ) {
    if (_suggestions.isEmpty) {
      if (_isLoading) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: CircularProgressIndicator(color: colorScheme.primary),
          ),
        );
      }
      return ListTile(
        title: Text(
          l10n.locationSearchNoResults,
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: !widget.expandSuggestions,
      padding: widget.expandSuggestions
          ? const EdgeInsets.only(top: 4)
          : EdgeInsets.zero,
      itemCount: _suggestions.length,
      itemBuilder: (context, index) {
        final place = _suggestions[index];
        final title = widget.useFormattedAddress
            ? place.suggestionTitle
            : place.shortAddress;
        final subtitle = widget.useFormattedAddress
            ? place.suggestionSubtitle
            : place.displayName;
        return ListTile(
          leading: Icon(
            Icons.location_on,
            color: colorScheme.primary,
          ),
          title: LocationSearchField._highlightedTitle(title, query, colorScheme),
          subtitle: title.toLowerCase() != subtitle.toLowerCase()
              ? Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                )
              : null,
          onTap: () => _selectLocation(place),
        );
      },
    );
  }
}
