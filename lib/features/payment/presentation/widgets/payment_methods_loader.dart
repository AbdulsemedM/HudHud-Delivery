import 'package:flutter/material.dart';
import '../../../../core/api/api_service.dart';
import '../../data/data_provider/payment_data_provider.dart';
import '../../data/repository/payment_repository.dart';

typedef PaymentMethodsBuilder = Widget Function(
  BuildContext context,
  List<Map<String, dynamic>> methods,
  bool isLoading,
  String? error,
  VoidCallback reload,
);

class PaymentMethodsLoader extends StatefulWidget {
  final PaymentMethodsBuilder builder;
  final PaymentRepository? repository;

  const PaymentMethodsLoader({
    super.key,
    required this.builder,
    this.repository,
  });

  @override
  State<PaymentMethodsLoader> createState() => _PaymentMethodsLoaderState();
}

class _PaymentMethodsLoaderState extends State<PaymentMethodsLoader> {
  List<Map<String, dynamic>> _methods = [];
  bool _isLoading = true;
  String? _error;

  late final PaymentRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ??
        PaymentRepository(
          paymentDataProvider:
              PaymentDataProvider(apiService: ApiService.instance),
        );
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final methods = await _repository.getPaymentMethods();
      if (!mounted) return;
      setState(() {
        _methods = methods;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _methods = [];
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      _methods,
      _isLoading,
      _error,
      _load,
    );
  }
}
