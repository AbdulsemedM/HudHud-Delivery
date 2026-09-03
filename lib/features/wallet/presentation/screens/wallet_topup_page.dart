import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/utils/payment_details_builder.dart';
import 'package:hudhud_delivery/core/utils/payment_idempotency.dart';
import 'package:hudhud_delivery/core/utils/payment_poller.dart';
import 'package:hudhud_delivery/features/payment/data/data_provider/payment_data_provider.dart';
import 'package:hudhud_delivery/features/payment/data/repository/payment_repository.dart';
import 'package:hudhud_delivery/features/payment/model/payment_initiate_result.dart';
import 'package:hudhud_delivery/features/payment/model/payment_status_result.dart';
import 'package:hudhud_delivery/features/payment/presentation/screen/payment_initiate_result_screen.dart';
import 'package:hudhud_delivery/features/payment/presentation/widgets/payment_details_form.dart';
import 'package:hudhud_delivery/features/payment/presentation/widgets/qpay_qr_sheet.dart';
import 'package:hudhud_delivery/features/payment/utils/qpay_method.dart';
import 'package:hudhud_delivery/features/settings/presentation/widgets/profile_dark_page.dart';
import 'package:hudhud_delivery/features/wallet/data/providers/wallet_data_provider.dart';
import 'package:hudhud_delivery/features/wallet/data/repositories/wallet_repository.dart';
import 'package:hudhud_delivery/features/wallet/data/wallet_topup_pending_store.dart';
import 'package:hudhud_delivery/features/wallet/presentation/widgets/wallet_funding_form.dart';
import 'package:hudhud_delivery/features/wallet/services/wallet_topup_recovery_service.dart';
import 'package:hudhud_delivery/features/wallet/utils/wallet_funding_methods.dart';

class WalletTopUpPage extends StatefulWidget {
  final String defaultCurrency;
  final double? initialAmount;

  const WalletTopUpPage({
    super.key,
    this.defaultCurrency = 'ETB',
    this.initialAmount,
  });

  @override
  State<WalletTopUpPage> createState() => _WalletTopUpPageState();
}

class _WalletTopUpPageState extends State<WalletTopUpPage> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _pendingStore = WalletTopUpPendingStore();

  List<Map<String, dynamic>> _paymentMethods =
      List.from(kDefaultWalletFundingMethods);
  bool _isLoadingPaymentMethods = true;
  bool _isSubmitting = false;
  bool _verificationInProgress = false;
  String? _selectedMethodId;
  Map<String, dynamic> _paymentDetails = {};
  String _ebirrProvider = 'kaafi';
  bool _useHpp = false;
  int? _restoredPendingPaymentId;
  PaymentPoller? _pagePoller;

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
    if (widget.initialAmount != null && widget.initialAmount! > 0) {
      _applyAmount(widget.initialAmount!);
    }
    _amountController.addListener(() => setState(() {}));
    _loadMethods();
    _restorePendingState();
  }

  @override
  void dispose() {
    _pagePoller?.stop();
    _amountController.dispose();
    super.dispose();
  }

  void _applyAmount(double amount) {
    _amountController.text = amount == amount.roundToDouble()
        ? amount.toStringAsFixed(0)
        : amount.toStringAsFixed(2);
  }

  Future<void> _restorePendingState() async {
    final pendingId = await _pendingStore.readLastPendingPaymentId();
    if (!mounted || pendingId == null) return;
    setState(() {
      _restoredPendingPaymentId = pendingId;
      _verificationInProgress = true;
    });
    _startPagePoller(pendingId);
  }

  Future<void> _loadMethods() async {
    try {
      var methods = filterWalletFundingMethods(
        await _paymentRepository.getPaymentMethods(type: 'wallet'),
      );
      if (!hasUsableQpayInList(methods)) {
        methods = methods.where((m) => !isQpay(m['id']?.toString())).toList();
        final resolved = await _paymentRepository.resolveUsableQpay();
        if (resolved != null) {
          methods = [resolved, ...methods];
        }
      }
      methods = sortQpayFirst(methods);
      if (!mounted) return;
      setState(() {
        _paymentMethods = methods;
        _isLoadingPaymentMethods = false;
        _selectedMethodId ??=
            methods.isNotEmpty ? methods.first['id'] as String? : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _paymentMethods = List.from(kDefaultWalletFundingMethods);
        _isLoadingPaymentMethods = false;
      });
    }
  }

  String _currentFingerprint(String method, double amount) {
    final phone = _paymentDetails['phone']?.toString() ?? '';
    return buildWalletTopUpFingerprint(
      paymentMethodCode: method,
      amount: amount,
      currency: widget.defaultCurrency,
      phone: phone,
    );
  }

  Future<void> _submitTopUp() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;
    final method = _selectedMethodId;
    if (method == null || method.isEmpty) {
      _showSnack(context.l10n.paymentSelectMethodFirst, isError: true);
      return;
    }

    if (paymentMethodNeedsDetailsForm(method)) {
      final phoneError = validatePaymentPhone(
        _paymentDetails['phone']?.toString(),
        method,
      );
      if (phoneError != null) {
        _showSnack(phoneError, isError: true);
        return;
      }
    }

    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      _showSnack(context.l10n.validationEnterValidAmount, isError: true);
      return;
    }

    final details = buildWalletTopUpPaymentDetails(
      paymentMethodCode: method,
      collectedDetails: _paymentDetails,
    );
    final fingerprint = _currentFingerprint(method, amount);
    var idempotencyKey = await resolveWalletTopUpKey(fingerprint);

    setState(() => _isSubmitting = true);
    try {
      final response = await _submitWithRetry(
        amount: amount,
        method: method,
        details: details,
        fingerprint: fingerprint,
        idempotencyKey: idempotencyKey,
      );
      if (!mounted) return;
      await _handleTopUpResponse(
        response.toInitiateEnvelope(),
        method: method,
        amount: amount,
      );
      await WalletTopUpRecoveryService.instance.refresh();
    } on ApiException catch (e) {
      if (!mounted) return;
      await _handleQpayApiError(e);
    } catch (e) {
      if (!mounted) return;
      if (!isTransientPaymentNetworkError(e)) {
        await clearWalletTopUpIdempotency();
      }
      _showSnack(userFacingApiError(e), isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<WalletMutationResponse> _submitWithRetry({
    required double amount,
    required String method,
    required Map<String, dynamic> details,
    required String fingerprint,
    required String idempotencyKey,
  }) async {
    try {
      return await _walletRepository.topUp(
        amount: amount,
        paymentMethodCode: method,
        currency: widget.defaultCurrency,
        paymentDetails: details,
        idempotencyKey: idempotencyKey,
      );
    } on ApiException catch (e) {
      if (isIdempotencyConflictError(e)) {
        await clearWalletTopUpIdempotency();
        final newKey = await resolveWalletTopUpKey(fingerprint);
        return _walletRepository.topUp(
          amount: amount,
          paymentMethodCode: method,
          currency: widget.defaultCurrency,
          paymentDetails: details,
          idempotencyKey: newKey,
        );
      }
      rethrow;
    }
  }

  Future<void> _handleTopUpResponse(
    Map<String, dynamic> envelope, {
    required String method,
    required double amount,
  }) async {
    final result = PaymentInitiateResult.fromJson(envelope);
    if (!result.isSuccess) {
      _showSnack(result.message ?? 'Top up failed', isError: true);
      return;
    }

    if (isQpay(method)) {
      if (qpayInitiateLooksValid(result)) {
        final paymentId = result.paymentId!;
        await _pendingStore.addPendingPaymentId(paymentId);
        if (!mounted) return;
        final sheetResult = await showQPayQrSheet(
          context,
          paymentId: paymentId,
          qrCode: result.qrCodeBase64!,
          amount: result.amount ?? amount.toStringAsFixed(2),
          currency: result.currency ?? widget.defaultCurrency,
        );
        if (!mounted) return;
        await _handleQPaySheetResult(sheetResult, paymentId);
        return;
      }

      if (shouldPollPaymentStatus(
        isSuccess: result.isSuccess,
        nextAction: result.nextAction,
        status: result.status,
        method: result.method,
      )) {
        if (result.paymentId != null) {
          await _pendingStore.addPendingPaymentId(result.paymentId!);
          setState(() => _verificationInProgress = true);
          _startPagePoller(result.paymentId!);
        }
        _showSnack(
          result.message ?? 'Payment pending. We are checking status…',
        );
        return;
      }

      _showSnack(
        result.message ?? 'QPay QR is unavailable. Try again shortly.',
        isError: true,
      );
      return;
    }

    if (!result.isSuccess &&
        result.uiMode == PaymentInitiateUiMode.failure &&
        result.paymentId == null) {
      return;
    }

    _showSnack(_nonQpaySuccessMessage(result));
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentInitiateResultScreen(
          result: result,
          orderId: 'wallet-topup',
        ),
      ),
    );
    if (!mounted) return;
    await clearWalletTopUpIdempotency();
    Navigator.pop(context, true);
  }

  String _nonQpaySuccessMessage(PaymentInitiateResult result) {
    if (result.message != null && result.message!.isNotEmpty) {
      return result.message!;
    }
    return 'Payment initiated. Complete approval on your phone if prompted.';
  }

  Future<void> _handleQPaySheetResult(
    QPaySheetResult? result,
    int paymentId,
  ) async {
    switch (result) {
      case QPaySheetResult.completed:
        await _onWalletSettled(paymentId);
      case QPaySheetResult.expired:
        await _onWalletFailed(
          paymentId,
          'Payment expired. Please try again.',
        );
      case QPaySheetResult.failed:
        await _onWalletFailed(
          paymentId,
          'Payment failed. Please try again.',
        );
      case QPaySheetResult.unavailable:
        await clearWalletTopUpIdempotency();
        await _pendingStore.removePendingPaymentId(paymentId);
        setState(() => _verificationInProgress = false);
        _showSnack('Payment verification unavailable.', isError: true);
      case QPaySheetResult.dismissed:
      case null:
        setState(() => _verificationInProgress = true);
        _startPagePoller(paymentId);
    }
  }

  Future<void> _onWalletSettled(int paymentId) async {
    await _pendingStore.removePendingPaymentId(paymentId);
    await clearWalletTopUpIdempotency();
    _pagePoller?.stop();
    setState(() => _verificationInProgress = false);
    _showSnack('Wallet credited successfully.');
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _onWalletFailed(int paymentId, String message) async {
    await _pendingStore.removePendingPaymentId(paymentId);
    await clearWalletTopUpIdempotency();
    _pagePoller?.stop();
    setState(() => _verificationInProgress = false);
    _showSnack(message, isError: true);
  }

  void _startPagePoller(int paymentId) {
    _pagePoller?.stop();
    _pagePoller = PaymentPoller.startWalletTopUp(
      paymentId: paymentId,
      onStatus: (_) {},
      onTerminal: (status) async {
        if (!mounted) return;
        if (status.isWalletTopUpSettled) {
          await _onWalletSettled(paymentId);
        } else if (status.isWalletTopUpTerminalFailure) {
          await _onWalletFailed(paymentId, 'Payment failed or expired.');
        }
      },
      onFatalError: (_) async {
        if (!mounted) return;
        await clearWalletTopUpIdempotency();
        await _pendingStore.removePendingPaymentId(paymentId);
        setState(() => _verificationInProgress = false);
        _showSnack('Payment verification unavailable.', isError: true);
      },
    );
  }

  Future<void> _handleQpayApiError(ApiException error) async {
    final parsed = parseApiErrorResult(
      error.data is Map
          ? Map<String, dynamic>.from(error.data as Map)
          : {'message': error.message, 'code': error.code},
    );
    final code = parsed.code ?? error.code ?? '';

    switch (code) {
      case 'QPAY_NOT_CONFIGURED':
        _showSnack(parsed.displayMessage, isError: true);
        return;
      case 'QPAY_QR_GENERATION_FAILED':
      case 'QPAY_QR_GENERATION_UNAVAILABLE':
        await clearWalletTopUpIdempotency();
        _showSnack(parsed.displayMessage, isError: true);
        return;
      default:
        if (!isTransientPaymentNetworkError(error)) {
          await clearWalletTopUpIdempotency();
        }
        _showSnack(parsed.displayMessage, isError: true);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppColors.successColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ProfileDarkPage(
      title: l10n.addFundsTitle,
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            if (_verificationInProgress) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: MaterialBanner(
                  content: Text(
                    _restoredPendingPaymentId != null
                        ? 'Resuming wallet top-up verification…'
                        : 'Payment verification in progress…',
                  ),
                  leading: const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  actions: const [SizedBox.shrink()],
                ),
              ),
            ],
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
                onQuickAmountSelected: _applyAmount,
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
                onEbirrProviderChanged: (v) => setState(() => _ebirrProvider = v),
                onUseHppChanged: (v) => setState(() => _useHpp = v),
                onPaymentDetailsChanged: (details) {
                  _paymentDetails = details;
                },
              ),
            ),
            WalletFundingSubmitBar(
              label: l10n.walletAddMoney,
              isLoading: _isSubmitting,
              onPressed: _submitTopUp,
            ),
          ],
        ),
      ),
    );
  }
}
