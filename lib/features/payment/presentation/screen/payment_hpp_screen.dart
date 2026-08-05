import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/theme/app_colors.dart';

/// Opens a hosted payment page (e.g. Waafi `redirect_to_hpp`).
class PaymentHppScreen extends StatefulWidget {
  final String redirectUrl;
  final String? title;

  const PaymentHppScreen({
    super.key,
    required this.redirectUrl,
    this.title,
  });

  @override
  State<PaymentHppScreen> createState() => _PaymentHppScreenState();
}

class _PaymentHppScreenState extends State<PaymentHppScreen> {
  late final WebViewController _controller;
  var _loading = true;
  var _loadError = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (_) {
            if (mounted) {
              setState(() {
                _loading = false;
                _loadError = true;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.redirectUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'Complete payment'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          if (_loadError)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    const Text(
                      'Could not load the payment page.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _loadError = false;
                          _loading = true;
                        });
                        _controller.loadRequest(Uri.parse(widget.redirectUrl));
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else
            WebViewWidget(controller: _controller),
          if (_loading && !_loadError)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
