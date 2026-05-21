import 'dart:async';

import 'package:flutter/material.dart';

class ProductSearchField extends StatefulWidget {
  final String hint;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback? onFilterTap;
  final VoidCallback? onTap;
  final String? initialValue;
  final bool readOnly;

  const ProductSearchField({
    super.key,
    required this.hint,
    required this.onSearchChanged,
    this.onFilterTap,
    this.onTap,
    this.initialValue,
    this.readOnly = false,
  });

  @override
  State<ProductSearchField> createState() => _ProductSearchFieldState();
}

class _ProductSearchFieldState extends State<ProductSearchField> {
  late final TextEditingController _controller;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      widget.onSearchChanged(value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _controller,
                readOnly: widget.readOnly,
                onTap: widget.onTap,
                onChanged: widget.readOnly ? null : _onChanged,
                onSubmitted: (v) {
                  _debounce?.cancel();
                  widget.onSearchChanged(v.trim());
                },
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _controller.clear();
                            _debounce?.cancel();
                            widget.onSearchChanged('');
                            setState(() {});
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          if (widget.onFilterTap != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: widget.onFilterTap,
              icon: const Icon(Icons.tune),
              tooltip: 'Price filter',
            ),
          ],
        ],
      ),
    );
  }
}
