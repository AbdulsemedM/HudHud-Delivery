import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/app/services/auth_service.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/payment/data/data_provider/payment_data_provider.dart';
import 'package:hudhud_delivery/features/payment/data/repository/payment_repository.dart';
import 'package:hudhud_delivery/features/wallet/bloc/wallet_bloc.dart';
import 'package:hudhud_delivery/features/wallet/data/models/wallet_model.dart';
import 'package:hudhud_delivery/features/wallet/data/providers/wallet_data_provider.dart';
import 'package:hudhud_delivery/features/wallet/data/repositories/wallet_repository.dart';

class AddFundsScreen extends StatefulWidget {
  final List<WalletModel> wallets;
  final String defaultCurrency;

  const AddFundsScreen({
    super.key,
    required this.wallets,
    this.defaultCurrency = 'ETB',
  });

  @override
  State<AddFundsScreen> createState() => _AddFundsScreenState();
}

class _AddFundsScreenState extends State<AddFundsScreen> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> _paymentMethods = [];
  bool _isLoadingPaymentMethods = true;
  WalletModel? _selectedWallet;
  String? _selectedMethodId;
  bool _showCardDetails = false;
  final _transactionIdController = TextEditingController();
  final _cardLastFourController = TextEditingController();
  final _cardBrandController = TextEditingController();

  late final WalletRepository _walletRepository;
  late final PaymentRepository _paymentRepository;

  @override
  void initState() {
    super.initState();
    _walletRepository = WalletRepository(
      walletDataProvider: WalletDataProvider(apiService: ApiService.instance),
    );
    _paymentRepository = PaymentRepository(
      paymentDataProvider: PaymentDataProvider(apiService: ApiService.instance),
    );
    _fetchPaymentMethods();
    if (widget.wallets.isNotEmpty && _selectedWallet == null) {
      _selectedWallet = widget.wallets.first;
    }
  }

  Future<void> _fetchPaymentMethods() async {
    try {
      final methods = await _paymentRepository.getPaymentMethods();
      if (mounted) {
        setState(() {
          _paymentMethods = methods;
          _isLoadingPaymentMethods = false;
          if (methods.isNotEmpty && _selectedMethodId == null) {
            _selectedMethodId = methods.first['id'] as String?;
            _showCardDetails = _selectedMethodId == 'card';
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _paymentMethods = [];
          _isLoadingPaymentMethods = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _transactionIdController.dispose();
    _cardLastFourController.dispose();
    _cardBrandController.dispose();
    super.dispose();
  }

  String get _currency => 'ETB';

  InputDecoration _fieldDecoration(BuildContext context, String label,
      {String? hint}) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE);
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: scheme.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusLG),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusLG),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusLG),
        borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final borderColor =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE);

    return BlocProvider(
      create: (_) => WalletBloc(
        walletRepository: _walletRepository,
      ),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(l10n.addFundsTitle),
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        body: BlocConsumer<WalletBloc, WalletState>(
          listener: (context, state) {
            if (state is AddFundsSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.successColor,
                ),
              );
              Navigator.of(context).pop(true);
            } else if (state is AddFundsError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: colorScheme.error,
                ),
              );
            }
          },
          builder: (context, state) {
            final isLoading = state is AddFundsLoading;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppColors.spaceMD),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppColors.spaceMD),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.primaryColor,
                            AppColors.primaryDarkColor,
                          ],
                        ),
                        borderRadius:
                            BorderRadius.circular(AppColors.radiusLG),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.account_balance_wallet,
                              color: Colors.white, size: 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              l10n.addFundsTitle,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppColors.spaceLG),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: _fieldDecoration(
                        context,
                        l10n.amount,
                        hint: l10n.enterAmount,
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return l10n.enterAmount;
                        final amount = double.tryParse(v);
                        if (amount == null || amount <= 0) {
                          return l10n.validationEnterValidAmount;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppColors.spaceMD),
                    if (widget.wallets.isNotEmpty) ...[
                      DropdownButtonFormField<WalletModel>(
                        initialValue: _selectedWallet,
                        decoration: _fieldDecoration(context, l10n.wallet),
                        items: widget.wallets
                            .map((w) => DropdownMenuItem(
                                  value: w,
                                  child: Text('${w.name} (${w.currency})'),
                                ))
                            .toList(),
                        onChanged: (w) => setState(() => _selectedWallet = w),
                      ),
                      const SizedBox(height: AppColors.spaceMD),
                    ],
                    if (_isLoadingPaymentMethods)
                      _FormShimmer(borderColor: borderColor)
                    else if (_paymentMethods.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(AppColors.spaceMD),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius:
                              BorderRadius.circular(AppColors.radiusLG),
                          border: Border.all(color: borderColor),
                        ),
                        child: Text(
                          l10n.walletNoPaymentMethods,
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      )
                    else ...[
                      DropdownButtonFormField<String>(
                        initialValue: _selectedMethodId,
                        decoration:
                            _fieldDecoration(context, l10n.paymentMethod),
                        items: _paymentMethods
                            .map((m) => DropdownMenuItem(
                                  value: m['id'] as String?,
                                  child: Text(m['name'] as String? ?? ''),
                                ))
                            .toList(),
                        onChanged: (id) => setState(() {
                          _selectedMethodId = id;
                          _showCardDetails = id == 'card';
                        }),
                      ),
                      if (_showCardDetails) ...[
                        const SizedBox(height: AppColors.spaceMD),
                        TextFormField(
                          controller: _transactionIdController,
                          decoration: _fieldDecoration(
                            context,
                            l10n.transactionId,
                            hint: l10n.transactionIdHint,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _cardLastFourController,
                          decoration: _fieldDecoration(
                            context,
                            l10n.cardLast4,
                            hint: l10n.cardLast4Hint,
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _cardBrandController,
                          decoration: _fieldDecoration(
                            context,
                            l10n.cardBrand,
                            hint: l10n.cardBrandHint,
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: AppColors.spaceXL),
                    SizedBox(
                      height: AppColors.buttonHeightMD,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppColors.radiusLG),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(l10n.addFundsTitle),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _submitAddFunds({
    required double amount,
    required String method,
    required String currency,
    int? walletId,
    Map<String, dynamic>? paymentDetails,
  }) async {
    int? payerId;
    try {
      final user = await AuthService().getUserProfile();
      payerId = user?.id;
    } catch (_) {}

    if (!mounted) return;
    context.read<WalletBloc>().add(
          AddFundsEvent(
            amount: amount,
            method: method,
            currency: currency,
            payerId: payerId,
            walletId: walletId,
            paymentDetails:
                paymentDetails != null && paymentDetails.isNotEmpty
                    ? paymentDetails
                    : null,
          ),
        );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMethodId == null || _selectedMethodId!.isEmpty) {
      final colorScheme = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.selectPaymentMethod),
          backgroundColor: colorScheme.error,
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) return;

    Map<String, dynamic>? paymentDetails;
    if (_showCardDetails &&
        (_transactionIdController.text.isNotEmpty ||
            _cardLastFourController.text.isNotEmpty)) {
      paymentDetails = {};
      if (_transactionIdController.text.isNotEmpty) {
        paymentDetails['transaction_id'] = _transactionIdController.text;
      }
      if (_cardLastFourController.text.isNotEmpty) {
        paymentDetails['card_last_four'] = _cardLastFourController.text;
      }
      if (_cardBrandController.text.isNotEmpty) {
        paymentDetails['card_brand'] = _cardBrandController.text;
      }
    }

    _submitAddFunds(
      amount: amount,
      method: _selectedMethodId!,
      currency: _currency,
      walletId: _selectedWallet?.id,
      paymentDetails: paymentDetails,
    );
  }
}

class _FormShimmer extends StatelessWidget {
  final Color borderColor;

  const _FormShimmer({required this.borderColor});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);
    final highlightColor =
        isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF5F5F5);
    return Column(
      children: List.generate(2, (index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppColors.spaceMD),
          child: Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(AppColors.radiusLG),
                border: Border.all(color: borderColor),
              ),
            ),
          ),
        );
      }),
    );
  }
}
