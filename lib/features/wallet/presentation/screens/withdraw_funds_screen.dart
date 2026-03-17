import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    if (widget.wallets.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Withdraw Funds'),
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No wallets available to withdraw from',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
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
          title: const Text('Withdraw Funds'),
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: BlocConsumer<WalletBloc, WalletState>(
          listener: (context, state) {
            if (state is WithdrawFundsSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.of(context).pop(true);
            } else if (state is WithdrawFundsError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
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
                      decoration: const InputDecoration(
                        labelText: 'From Wallet',
                        border: OutlineInputBorder(),
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
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        hintText: 'Enter amount to withdraw',
                        border: OutlineInputBorder(),
                        prefixText: ' ',
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter amount';
                        final amount = double.tryParse(v);
                        if (amount == null || amount <= 0) {
                          return 'Enter a valid amount';
                        }
                        if (_selectedWallet != null &&
                            amount > _selectedWallet!.balanceAmount) {
                          return 'Amount exceeds wallet balance';
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
                          'No payment methods available',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    else ...[
                      DropdownButtonFormField<String>(
                        value: _selectedMethodId,
                        decoration: const InputDecoration(
                          labelText: 'Withdrawal Method',
                          border: OutlineInputBorder(),
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
                          decoration: const InputDecoration(
                            labelText: 'Transaction ID',
                            hintText: 'From payment gateway',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _cardLastFourController,
                          decoration: const InputDecoration(
                            labelText: 'Card last 4 digits',
                            hintText: '4242',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _cardBrandController,
                          decoration: const InputDecoration(
                            labelText: 'Card brand',
                            hintText: 'visa, mastercard',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
                          : const Text('Withdraw'),
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
    if (_selectedWallet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a wallet'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_selectedMethodId == null || _selectedMethodId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a withdrawal method'),
          backgroundColor: Colors.red,
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
