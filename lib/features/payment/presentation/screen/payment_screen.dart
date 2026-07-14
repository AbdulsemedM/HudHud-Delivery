import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/api/api_service.dart';
import '../../../checkout/data/data_provider/checkout_data_provider.dart';
import '../../../checkout/data/repository/checkout_repository.dart';
import '../../bloc/payment_bloc.dart';
import '../../data/data_provider/payment_data_provider.dart';
import '../../data/repository/payment_repository.dart';
import '../widgets/payment_widgets.dart';

class PaymentScreen extends StatefulWidget {
  final String orderId;
  final double totalAmount;
  final Map<String, dynamic> orderDetails;
  final String? preSelectedPaymentMethod;

  const PaymentScreen({
    super.key,
    required this.orderId,
    required this.totalAmount,
    required this.orderDetails,
    this.preSelectedPaymentMethod,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with TickerProviderStateMixin {
  String? _selectedPaymentMethod;
  List<String> _activePaymentMethodIds = const [];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _selectedPaymentMethod = widget.preSelectedPaymentMethod;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _processPayment(BuildContext blocContext) {
    final l10n = blocContext.l10n;
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(blocContext).showSnackBar(
        SnackBar(
          content: Text(l10n.paymentSelectMethodFirst),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (!_activePaymentMethodIds.contains(_selectedPaymentMethod)) {
      ScaffoldMessenger.of(blocContext).showSnackBar(
        SnackBar(
          content: Text(l10n.paymentMethodUnavailable),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _selectedPaymentMethod = null;
      });
      return;
    }

    // Show processing dialog
    showDialog(
      context: blocContext,
      barrierDismissible: false,
      builder: (ctx) => PaymentProcessingDialog(
        paymentMethod: _selectedPaymentMethod!,
      ),
    );

    // Process payment
    blocContext.read<PaymentBloc>().add(
          ProcessPaymentEvent(
            paymentMethod: _selectedPaymentMethod!,
            amount: widget.totalAmount,
            orderId: widget.orderId,
            paymentDetails: {
              'order_details': widget.orderDetails,
            },
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    return BlocProvider(
      create: (_) => PaymentBloc(
        paymentRepository: PaymentRepository(
          paymentDataProvider: PaymentDataProvider(
            apiService: ApiService.instance,
          ),
        ),
        checkoutRepository: CheckoutRepository(
          checkoutDataProvider: CheckoutDataProvider(
            apiService: ApiService.instance,
          ),
        ),
      )..add(const GetPaymentMethodsEvent()),
      child: Builder(
        builder: (blocContext) {
          final l10n = blocContext.l10n;
          return Scaffold(
          backgroundColor: colorScheme.surface,
          body: BlocListener<PaymentBloc, PaymentState>(
            listener: (context, state) {
              if (state is PaymentSuccess) {
                Navigator.of(context).pop(); // Close processing dialog
                _showPaymentSuccessDialog(state.transactionId);
              } else if (state is PaymentFailure) {
                Navigator.of(context).pop(); // Close processing dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.l10n.paymentFailedWithError(state.error)),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: CustomScrollView(
              slivers: [
                // Custom App Bar with gradient
                SliverAppBar(
                  expandedHeight: 120,
                  floating: false,
                  pinned: true,
                  elevation: 0,
                  backgroundColor: AppColors.primaryColor,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      l10n.paymentScreenTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primaryColor,
                            AppColors.primaryColor.withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.payment,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                // Payment content
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          // Payment Summary
                          PaymentSummaryCard(
                            subtotal: widget.orderDetails['subtotal'] ?? 0.0,
                            total: widget.totalAmount,
                          ),
                          const SizedBox(height: 24),
                          // Payment Methods Section
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.payment,
                                      color: AppColors.primaryColor,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      l10n.paymentChooseMethodHeading,
                                      style: textTheme.titleMedium?.copyWith(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l10n.paymentEthiopianOptionsSubtitle,
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontSize: 14,
                                    color: colorScheme.onSurface.withValues(alpha: 0.72),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Payment Methods List
                          BlocBuilder<PaymentBloc, PaymentState>(
                            builder: (context, state) {
                              if (state is PaymentLoading) {
                                return const Padding(
                                  padding: EdgeInsets.all(AppColors.spaceMD),
                                  child: _PaymentMethodsShimmer(),
                                );
                              } else if (state is PaymentMethodsLoaded) {
                                final activeIds = state.paymentMethods
                                    .where((m) => m['enabled'] == true)
                                    .map((m) => m['id'] as String)
                                    .toList(growable: false);
                                if (activeIds.join('|') !=
                                    _activePaymentMethodIds.join('|')) {
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    if (!mounted) return;
                                    setState(() {
                                      _activePaymentMethodIds = activeIds;
                                      if (_selectedPaymentMethod != null &&
                                          !_activePaymentMethodIds.contains(
                                              _selectedPaymentMethod)) {
                                        _selectedPaymentMethod = null;
                                      }
                                    });
                                  });
                                }
                                return Column(
                                  children: state.paymentMethods.map((method) {
                                    return PaymentMethodCard(
                                      id: method['id'],
                                      name: method['name'],
                                      description: method['description'],
                                      icon: method['icon'],
                                      isSelected: _selectedPaymentMethod ==
                                          method['id'],
                                      enabled: method['enabled'],
                                      onTap: () {
                                        setState(() {
                                          _selectedPaymentMethod = method['id'];
                                        });
                                      },
                                    );
                                  }).toList(),
                                );
                              } else if (state is PaymentFailure) {
                                return Container(
                                  margin: const EdgeInsets.all(16),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.errorColor.withValues(alpha: 
                                        isDark ? 0.16 : 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.errorColor.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: Colors.red.shade600,
                                        size: 48,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        l10n.paymentLoadMethodsError,
                                        style: textTheme.titleSmall?.copyWith(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.errorColor,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        state.error,
                                        textAlign: TextAlign.center,
                                        style: textTheme.bodyMedium?.copyWith(
                                          fontSize: 14,
                                          color: AppColors.errorColor
                                              .withValues(alpha: 0.9),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton(
                                        onPressed: () {
                                          context.read<PaymentBloc>().add(
                                                const GetPaymentMethodsEvent(),
                                              );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.errorColor,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: Text(l10n.actionRetry),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Pay Now Button
          bottomNavigationBar: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: ElevatedButton(
                onPressed: _selectedPaymentMethod != null &&
                        _activePaymentMethodIds.contains(_selectedPaymentMethod)
                    ? () => _processPayment(blocContext)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      l10n.paymentPayAmountBr(
                        widget.totalAmount.toStringAsFixed(2),
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        },
      ),
    );
  }

  void _showPaymentSuccessDialog(String transactionId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final l10n = context.l10n;
        final textTheme = Theme.of(context).textTheme;
        final colorScheme = Theme.of(context).colorScheme;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.successColor.withValues(alpha: 
                      isDark ? 0.2 : 0.14,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: AppColors.successColor,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.paymentSuccessTitle,
                  style: textTheme.titleLarge?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.paymentTransactionIdLabel(transactionId),
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    color: colorScheme.onSurface.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                        },
                        child: Text(l10n.continueShopping),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                          // Navigate to orders screen
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(l10n.viewOrder),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PaymentMethodsShimmer extends StatelessWidget {
  const _PaymentMethodsShimmer();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);
    final highlightColor =
        isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF5F5F5);
    return Column(
      children: List.generate(4, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(AppColors.radiusLG),
              ),
            ),
          ),
        );
      }),
    );
  }
}
