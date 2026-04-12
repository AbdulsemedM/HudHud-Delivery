import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

class WithdrawFundsScreen extends StatefulWidget {
  final List<WalletModel> wallets;
  final String defaultCurrency;

  const WithdrawFundsScreen({
    super.key,
    required this.wallets,
    this.defaultCurrency = 'ETB',
  });

  @override
  State<WithdrawFundsScreen> createState() => _WithdrawFundsScreenState();
}

class _WithdrawFundsScreenState extends State<WithdrawFundsScreen> {
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    if (widget.wallets.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.withdrawFundsTitle),
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l10n.walletNoWalletsForWithdraw,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
          ),
        ),
      );
    }

    return BlocProvider(
      create: (_) => WalletBloc(
        walletRepository: _walletRepository,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.withdrawFundsTitle),
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: BlocConsumer<WalletBloc, WalletState>(
          listener: (context, state) {
            if (state is WithdrawFundsSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green.shade700,
                ),
              );
              Navigator.of(context).pop(true);
            } else if (state is WithdrawFundsError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          },
          builder: (context, state) {
            final isLoading = state is WithdrawFundsLoading;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    DropdownButtonFormField<WalletModel>(
                      value: _selectedWallet,
                      decoration: InputDecoration(
                        labelText: l10n.fromWallet,
                        border: const OutlineInputBorder(),
                      ),
                      items: widget.wallets
                          .map((w) => DropdownMenuItem(
                                value: w,
                                child: Text(
                                    '${w.name} (${w.currency} ${w.balance})'),
                              ))
                          .toList(),
                      onChanged: (w) => setState(() => _selectedWallet = w),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: l10n.amount,
                        hintText: l10n.enterWithdrawAmount,
                        border: const OutlineInputBorder(),
                        prefixText: ' ',
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return l10n.enterAmount;
                        final amount = double.tryParse(v);
                        if (amount == null || amount <= 0) {
                          return l10n.validationEnterValidAmount;
                        }
                        if (_selectedWallet != null &&
                            amount > _selectedWallet!.balanceAmount) {
                          return l10n.validationAmountExceedsWalletBalance;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_isLoadingPaymentMethods)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_paymentMethods.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          l10n.walletNoPaymentMethods,
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      )
                    else ...[
                      DropdownButtonFormField<String>(
                        value: _selectedMethodId,
                        decoration: InputDecoration(
                          labelText: l10n.withdrawalMethod,
                          border: const OutlineInputBorder(),
                        ),
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
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _transactionIdController,
                          decoration: InputDecoration(
                            labelText: l10n.transactionId,
                            hintText: l10n.transactionIdHint,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _cardLastFourController,
                          decoration: InputDecoration(
                            labelText: l10n.cardLast4,
                            hintText: l10n.cardLast4Hint,
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _cardBrandController,
                          decoration: InputDecoration(
                            labelText: l10n.cardBrand,
                            hintText: l10n.cardBrandHint,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: isLoading
                          ? SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: colorScheme.onPrimary,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(l10n.withdrawAction),
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

  Future<void> _submitWithdraw({
    required double amount,
    required String method,
    required String currency,
    required int walletId,
    Map<String, dynamic>? paymentDetails,
  }) async {
    int? payerId;
    try {
      final user = await AuthService().getUserProfile();
      payerId = user?.id;
    } catch (_) {}

    if (!mounted) return;
    context.read<WalletBloc>().add(
          WithdrawFundsEvent(
            amount: amount,
            method: method,
            currency: currency,
            walletId: walletId,
            payerId: payerId,
            paymentDetails:
                paymentDetails != null && paymentDetails.isNotEmpty
                    ? paymentDetails
                    : null,
          ),
        );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final colorScheme = Theme.of(context).colorScheme;
    if (_selectedWallet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.selectWalletPrompt),
          backgroundColor: colorScheme.error,
        ),
      );
      return;
    }
    if (_selectedMethodId == null || _selectedMethodId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.selectWithdrawalMethodPrompt),
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

    _submitWithdraw(
      amount: amount,
      method: _selectedMethodId!,
      currency: _currency,
      walletId: _selectedWallet!.id,
      paymentDetails: paymentDetails,
    );
  }
}
