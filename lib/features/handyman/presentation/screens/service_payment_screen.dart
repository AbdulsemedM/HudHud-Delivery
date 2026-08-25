import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/handyman/utils/service_payment_helper.dart';
import 'package:hudhud_delivery/features/payment/data/data_provider/payment_data_provider.dart';
import 'package:hudhud_delivery/features/payment/data/repository/payment_repository.dart';
import 'package:hudhud_delivery/features/payment/model/payment_initiate_result.dart';
import 'package:hudhud_delivery/features/payment/presentation/screen/payment_initiate_result_screen.dart';
import 'package:hudhud_delivery/features/payment/presentation/widgets/payment_details_form.dart';

/// Pays an accepted service quote via convenience payment endpoints.
class ServicePaymentScreen extends StatefulWidget {
  final int serviceRequestId;
  final double amount;
  final String currency;

  const ServicePaymentScreen({
    super.key,
    required this.serviceRequestId,
    required this.amount,
    this.currency = 'ETB',
  });

  @override
  State<ServicePaymentScreen> createState() => _ServicePaymentScreenState();
}

class _ServicePaymentScreenState extends State<ServicePaymentScreen> {
  late final PaymentRepository _paymentRepository;

  List<Map<String, dynamic>> _paymentMethods =
      List.from(kDefaultServicePaymentMethods);
  String? _selectedMethod;
  Map<String, dynamic> _paymentDetails = {};
  String _ebirrProvider = 'kaafi';
  bool _useHpp = false;
  bool _loadingMethods = true;
  bool _isPaying = false;

  @override
  void initState() {
    super.initState();
    _paymentRepository = PaymentRepository(
      paymentDataProvider: PaymentDataProvider(
        apiService: ApiService.instance,
      ),
    );
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    try {
      final methods = await _paymentRepository.getPaymentMethods();
      if (!mounted) return;
      setState(() {
        _paymentMethods = filterServicePaymentMethods(methods);
        _loadingMethods = false;
        if (_selectedMethod != null &&
            !_paymentMethods.any((m) => m['id'] == _selectedMethod)) {
          _selectedMethod = null;
          _paymentDetails = {};
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _paymentMethods = List.from(kDefaultServicePaymentMethods);
        _loadingMethods = false;
      });
    }
  }

  Future<void> _onPay() async {
    final method = _selectedMethod;
    if (method == null || method.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.paymentSelectMethodFirst),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (paymentMethodNeedsDetailsForm(method)) {
      final phoneError = validatePaymentPhone(
        _paymentDetails['phone']?.toString(),
        method,
      );
      if (phoneError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(phoneError),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isPaying = true);

    try {
      final result = await initiateServiceConveniencePayment(
        repo: _paymentRepository,
        serviceRequestId: widget.serviceRequestId,
        paymentMethodCode: method,
        paymentDetails: Map<String, dynamic>.from(_paymentDetails),
      );

      if (!mounted) return;
      setState(() => _isPaying = false);

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PaymentInitiateResultScreen(
            result: result,
            orderId: widget.serviceRequestId.toString(),
          ),
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPaying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userFacingApiError(e)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final borderColor =
        isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Pay for service',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppColors.radiusLG),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Amount due',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${widget.amount.toStringAsFixed(2)} ${widget.currency}',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Request #${widget.serviceRequestId}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Payment method',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_loadingMethods)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _paymentMethods.map((method) {
                          final id = method['id'] as String? ?? '';
                          final name = method['name'] as String? ?? id;
                          final isSelected = _selectedMethod == id;
                          return FilterChip(
                            label: Text(name),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedMethod = id;
                                  _paymentDetails = {};
                                  _useHpp = false;
                                  _ebirrProvider = 'kaafi';
                                });
                              }
                            },
                            showCheckmark: false,
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurfaceVariant,
                            ),
                            backgroundColor: colorScheme.surface,
                            selectedColor: AppColors.primaryColor,
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primaryColor
                                  : borderColor,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppColors.radiusFull),
                            ),
                          );
                        }).toList(),
                      ),
                    if (_selectedMethod != null)
                      PaymentDetailsForm(
                        key: ValueKey(_selectedMethod),
                        paymentMethodCode: _selectedMethod!,
                        ebirrProvider: _ebirrProvider,
                        useHpp: _useHpp,
                        onEbirrProviderChanged: (v) =>
                            setState(() => _ebirrProvider = v),
                        onUseHppChanged: (v) => setState(() => _useHpp = v),
                        onChanged: (details) {
                          _paymentDetails = details;
                        },
                      ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(AppColors.spaceMD),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: AppColors.buttonHeightMD,
                child: ElevatedButton(
                  onPressed: _isPaying ? null : _onPay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: AppColors.lightOnPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppColors.radiusLG),
                    ),
                  ),
                  child: _isPaying
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.lightOnPrimary,
                          ),
                        )
                      : const Text(
                          'Pay now',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
