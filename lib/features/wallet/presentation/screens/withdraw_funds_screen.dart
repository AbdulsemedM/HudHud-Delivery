import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/utils/payment_idempotency.dart';
import 'package:hudhud_delivery/features/payment/data/data_provider/payment_data_provider.dart';
import 'package:hudhud_delivery/features/payment/data/repository/payment_repository.dart';
import 'package:hudhud_delivery/features/payment/model/payment_initiate_result.dart';
import 'package:hudhud_delivery/features/payment/presentation/screen/payment_initiate_result_screen.dart';
import 'package:hudhud_delivery/features/payment/presentation/widgets/payment_details_form.dart';
import 'package:hudhud_delivery/features/settings/presentation/widgets/profile_dark_page.dart';
import 'package:hudhud_delivery/features/wallet/bloc/wallet_bloc.dart';
import 'package:hudhud_delivery/features/wallet/data/providers/wallet_data_provider.dart';
import 'package:hudhud_delivery/features/wallet/data/repositories/wallet_repository.dart';
import 'package:hudhud_delivery/features/wallet/presentation/widgets/wallet_funding_form.dart';
import 'package:hudhud_delivery/features/wallet/utils/wallet_funding_methods.dart';

class WithdrawFundsScreen extends StatefulWidget {
  final String defaultCurrency;
  final int? walletId;

  const WithdrawFundsScreen({
    super.key,
    this.defaultCurrency = 'ETB',
    this.walletId,
  });

  @override
  State<WithdrawFundsScreen> createState() => _WithdrawFundsScreenState();
}

class _WithdrawFundsScreenState extends State<WithdrawFundsScreen> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> _paymentMethods =
      List.from(kDefaultWalletFundingMethods);
  bool _isLoadingPaymentMethods = true;
  String? _selectedMethodId;
  Map<String, dynamic> _paymentDetails = {};
  String _ebirrProvider = 'kaafi';
  bool _useHpp = false;
  String? _idempotencyKey;
  int? _walletId;
  bool _resolvingWalletId = false;

  late final WalletRepository _walletRepository;
  late final PaymentRepository _paymentRepository;
  late final WalletBloc _walletBloc;

  @override
  void initState() {
    super.initState();
    _walletRepository = WalletRepository(
      walletDataProvider: WalletDataProvider(apiService: ApiService.instance),
    );
    _paymentRepository = PaymentRepository(
      paymentDataProvider: PaymentDataProvider(apiService: ApiService.instance),
    );
    _walletBloc = WalletBloc(walletRepository: _walletRepository);
    _walletId = widget.walletId;
    _amountController.addListener(_invalidateIdempotencyKey);
    _fetchPaymentMethods();
    if (_walletId == null) {
      _resolveWalletId();
    }
  }

  void _applyAmount(double amount) {
    _amountController.text = amount == amount.roundToDouble()
        ? amount.toStringAsFixed(0)
        : amount.toStringAsFixed(2);
  }

  Future<void> _resolveWalletId() async {
    setState(() => _resolvingWalletId = true);
    try {
      final balance = await _walletRepository.getBalance();
      if (!mounted) return;
      setState(() {
        _walletId = balance.id;
        _resolvingWalletId = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _resolvingWalletId = false);
    }
  }

  Future<void> _fetchPaymentMethods() async {
    try {
      final methods = await _paymentRepository.getPaymentMethods();
      if (!mounted) return;
      setState(() {
        _paymentMethods = filterWalletFundingMethods(methods);
        _isLoadingPaymentMethods = false;
        if (_selectedMethodId == null && _paymentMethods.isNotEmpty) {
          _selectedMethodId = _paymentMethods.first['id'] as String?;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _paymentMethods = List.from(kDefaultWalletFundingMethods);
        _isLoadingPaymentMethods = false;
      });
    }
  }

  @override
  void dispose() {
    _walletBloc.close();
    _amountController.dispose();
    super.dispose();
  }

  void _invalidateIdempotencyKey() {
    _idempotencyKey = null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final method = _selectedMethodId;
    if (method == null || method.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.selectWithdrawalMethodPrompt),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_walletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wallet is unavailable. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      await _resolveWalletId();
      return;
    }

    if (paymentMethodNeedsDetailsForm(method)) {
      final phoneError = validatePaymentPhone(
        _paymentDetails['phone']?.toString(),
        method,
      );
      if (phoneError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(phoneError), backgroundColor: Colors.red),
        );
        return;
      }
    }

    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final details = buildInitiatePaymentDetails(
      paymentMethodCode: method,
      collectedDetails: _paymentDetails,
      orderId: 0,
    );

    _idempotencyKey ??= createWalletIdempotencyKey(operation: 'withdraw');

    _walletBloc.add(WithdrawFundsEvent(
      amount: amount,
      paymentMethodCode: method,
      currency: widget.defaultCurrency,
      walletId: _walletId!,
      paymentDetails: details,
      idempotencyKey: _idempotencyKey,
    ));
  }

  Future<void> _handlePaymentResult(Map<String, dynamic> envelope) async {
    final result = PaymentInitiateResult.fromJson(envelope);
    if (!result.isSuccess &&
        result.uiMode == PaymentInitiateUiMode.failure &&
        result.paymentId == null) {
      return;
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentInitiateResultScreen(
          result: result,
          orderId: 'wallet-withdraw',
        ),
      ),
    );
  }

  String _successSnackMessage(WithdrawFundsSuccess state) {
    if (state.message.isNotEmpty) return state.message;
    switch (state.phase) {
      case WalletWithdrawPhase.approved:
        return 'Withdrawal completed';
      case WalletWithdrawPhase.rejected:
        return 'Withdrawal was rejected';
      case WalletWithdrawPhase.pending:
        return 'Withdrawal is pending approval';
      case WalletWithdrawPhase.submitted:
      case WalletWithdrawPhase.idle:
      case WalletWithdrawPhase.failed:
        return 'Withdrawal request submitted';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocProvider.value(
      value: _walletBloc,
      child: ProfileDarkPage(
        title: l10n.withdrawFundsTitle,
        body: BlocConsumer<WalletBloc, WalletState>(
          listener: (context, state) async {
            if (state is WithdrawFundsSuccess) {
              _invalidateIdempotencyKey();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_successSnackMessage(state)),
                  backgroundColor: AppColors.successColor,
                ),
              );
              await _handlePaymentResult(state.initiateEnvelope);
              if (context.mounted) Navigator.of(context).pop(true);
            } else if (state is WithdrawFundsError) {
              if (!isTransientPaymentNetworkError(state.message)) {
                _invalidateIdempotencyKey();
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            final isLoading =
                state is WithdrawFundsLoading || _resolvingWalletId;
            return Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: WalletFundingFormBody(
                      amountController: _amountController,
                      currency: widget.defaultCurrency,
                      amountHint: l10n.enterWithdrawAmount,
                      amountValidator: (v) {
                        if (v == null || v.isEmpty) {
                          return l10n.enterAmount;
                        }
                        final amount = double.tryParse(v);
                        if (amount == null || amount <= 0) {
                          return l10n.validationEnterValidAmount;
                        }
                        return null;
                      },
                      onQuickAmountSelected: (amount) {
                        setState(() {
                          _invalidateIdempotencyKey();
                          _applyAmount(amount);
                        });
                      },
                      methodSectionTitle: l10n.withdrawalMethod,
                      methods: _paymentMethods,
                      selectedMethodId: _selectedMethodId,
                      isLoadingMethods: _isLoadingPaymentMethods,
                      emptyMethodsMessage: l10n.walletNoPaymentMethods,
                      onMethodSelected: (id) {
                        setState(() {
                          _invalidateIdempotencyKey();
                          _selectedMethodId = id;
                          _paymentDetails = {};
                          _useHpp = false;
                          _ebirrProvider = 'kaafi';
                        });
                      },
                      ebirrProvider: _ebirrProvider,
                      useHpp: _useHpp,
                      onEbirrProviderChanged: (v) =>
                          setState(() => _ebirrProvider = v),
                      onUseHppChanged: (v) => setState(() => _useHpp = v),
                      onPaymentDetailsChanged: (details) {
                        _paymentDetails = details;
                      },
                    ),
                  ),
                  WalletFundingSubmitBar(
                    label: l10n.withdrawAction,
                    isLoading: isLoading,
                    onPressed: _submit,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
