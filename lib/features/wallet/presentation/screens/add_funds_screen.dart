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
import 'package:hudhud_delivery/features/wallet/bloc/wallet_bloc.dart';
import 'package:hudhud_delivery/features/wallet/data/providers/wallet_data_provider.dart';
import 'package:hudhud_delivery/features/wallet/data/repositories/wallet_repository.dart';
import 'package:hudhud_delivery/features/wallet/utils/wallet_funding_methods.dart';

class AddFundsScreen extends StatefulWidget {
  final String defaultCurrency;

  const AddFundsScreen({
    super.key,
    this.defaultCurrency = 'ETB',
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
    _fetchPaymentMethods();
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final borderColor =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE);

    return BlocProvider.value(
      value: _walletBloc,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.addFundsTitle),
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          elevation: 0,
        ),
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
            return SafeArea(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _amountController,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: InputDecoration(
                                labelText: l10n.amount,
                                hintText: '0.00',
                                suffixText: widget.defaultCurrency,
                                border: const OutlineInputBorder(),
                              ),
                              validator: (v) {
                                final n = double.tryParse(v?.trim() ?? '');
                                if (n == null || n <= 0) {
                                  return l10n.validationEnterValidAmount;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            Text(
                              l10n.labelPaymentMethod,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (_isLoadingPaymentMethods)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            else
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _paymentMethods.map((method) {
                                  final id = method['id'] as String? ?? '';
                                  final name =
                                      method['name'] as String? ?? id;
                                  final selected = _selectedMethodId == id;
                                  return FilterChip(
                                    label: Text(name),
                                    selected: selected,
                                    onSelected: (v) {
                                      if (!v) return;
                                      setState(() {
                                        _selectedMethodId = id;
                                        _paymentDetails = {};
                                        _useHpp = false;
                                        _ebirrProvider = 'kaafi';
                                      });
                                    },
                                    showCheckmark: false,
                                    selectedColor: AppColors.primaryColor,
                                    labelStyle: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: selected
                                          ? colorScheme.onPrimary
                                          : colorScheme.onSurfaceVariant,
                                    ),
                                    side: BorderSide(
                                      color: selected
                                          ? AppColors.primaryColor
                                          : borderColor,
                                    ),
                                  );
                                }).toList(),
                              ),
                            if (_selectedMethodId != null)
                              PaymentDetailsForm(
                                key: ValueKey(_selectedMethodId),
                                paymentMethodCode: _selectedMethodId!,
                                ebirrProvider: _ebirrProvider,
                                useHpp: _useHpp,
                                onEbirrProviderChanged: (v) =>
                                    setState(() => _ebirrProvider = v),
                                onUseHppChanged: (v) =>
                                    setState(() => _useHpp = v),
                                onChanged: (details) {
                                  _paymentDetails = details;
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppColors.spaceMD),
                      child: SizedBox(
                        width: double.infinity,
                        height: AppColors.buttonHeightMD,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(l10n.walletAddMoney),
                        ),
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
}
