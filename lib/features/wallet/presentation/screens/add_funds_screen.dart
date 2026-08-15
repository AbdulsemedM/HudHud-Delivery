import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
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

class AddFundsScreen extends StatefulWidget {
  final String defaultCurrency;
  final double? initialAmount;

  const AddFundsScreen({
    super.key,
    this.defaultCurrency = 'ETB',
    this.initialAmount,
  });

  @override
  State<AddFundsScreen> createState() => _AddFundsScreenState();
}

class _AddFundsScreenState extends State<AddFundsScreen> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> _paymentMethods =
      List.from(kDefaultWalletFundingMethods);
  bool _isLoadingPaymentMethods = true;
  String? _selectedMethodId;
  Map<String, dynamic> _paymentDetails = {};
  String _ebirrProvider = 'kaafi';
  bool _useHpp = false;

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
    if (widget.initialAmount != null && widget.initialAmount! > 0) {
      _applyAmount(widget.initialAmount!);
    }
    _fetchPaymentMethods();
  }

  void _applyAmount(double amount) {
    _amountController.text = amount == amount.roundToDouble()
        ? amount.toStringAsFixed(0)
        : amount.toStringAsFixed(2);
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final method = _selectedMethodId;
    if (method == null || method.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a payment method'),
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

    _walletBloc.add(AddFundsEvent(
      amount: amount,
      paymentMethodCode: method,
      currency: widget.defaultCurrency,
      paymentDetails: details,
    ));
  }

  Future<void> _handlePaymentResult(Map<String, dynamic>? payment) async {
    if (payment == null) return;
    final result = PaymentInitiateResult.fromJson(payment);
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
          orderId: 'wallet-topup',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocProvider.value(
      value: _walletBloc,
      child: ProfileDarkPage(
        title: l10n.addFundsTitle,
        body: BlocConsumer<WalletBloc, WalletState>(
          listener: (context, state) async {
            if (state is AddFundsSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.message.isNotEmpty
                        ? state.message
                        : 'Funds added successfully',
                  ),
                  backgroundColor: AppColors.successColor,
                ),
              );
              await _handlePaymentResult(state.payment);
              if (context.mounted) Navigator.pop(context, true);
            } else if (state is AddFundsError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            final isLoading = state is AddFundsLoading;
            return Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: WalletFundingFormBody(
                      amountController: _amountController,
                      currency: widget.defaultCurrency,
                      amountHint: '0.00',
                      amountValidator: (v) {
                        final n = double.tryParse(v?.trim() ?? '');
                        if (n == null || n <= 0) {
                          return l10n.validationEnterValidAmount;
                        }
                        return null;
                      },
                      onQuickAmountSelected: (amount) {
                        setState(() => _applyAmount(amount));
                      },
                      methodSectionTitle: l10n.labelPaymentMethod,
                      methods: _paymentMethods,
                      selectedMethodId: _selectedMethodId,
                      isLoadingMethods: _isLoadingPaymentMethods,
                      onMethodSelected: (id) {
                        setState(() {
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
                    label: l10n.walletAddMoney,
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
