import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/handyman/data/data_provider/handyman_data_provider.dart';
import 'package:hudhud_delivery/features/handyman/data/models/service_quote_model.dart';
import 'package:hudhud_delivery/features/handyman/data/repository/handyman_repository.dart';
import 'package:hudhud_delivery/features/home/presentation/widgets/home_widget.dart';
import 'package:lottie/lottie.dart';
import 'handyman_details_screen.dart';
import 'service_payment_screen.dart';

class ServiceQuotesScreen extends StatefulWidget {
  final int requestId;

  const ServiceQuotesScreen({super.key, required this.requestId});

  @override
  State<ServiceQuotesScreen> createState() => _ServiceQuotesScreenState();
}

class _ServiceQuotesScreenState extends State<ServiceQuotesScreen> {
  late final HandymanRepository _repository;
  List<ServiceQuoteModel> _quotes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = HandymanRepository(
      dataProvider: HandymanDataProvider(apiService: ApiService.instance),
    );
    _fetchQuotes();
  }

  Future<void> _fetchQuotes() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result =
        await _repository.getServiceQuotes(widget.requestId, page: 1);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result['success'] == true) {
        _quotes = result['quotes'] as List<ServiceQuoteModel>;
        _error = null;
      } else {
        _quotes = [];
        _error = result['message'] as String?;
      }
    });
  }

  Future<void> _acceptQuote(ServiceQuoteModel quote) async {
    final l10n = context.l10n;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusLG),
        ),
        title: Text(l10n.handymanAcceptQuoteTitle),
        content: Text(
          l10n.handymanAcceptQuoteMessage(
            quote.formattedAmount ?? quote.amount,
            quote.handymanName,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.successColor),
            child: Text(l10n.actionAccept),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final result = await _repository.acceptQuote(
      widget.requestId,
      quote.id,
    );

    if (!mounted) return;
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] as String? ?? l10n.handymanQuoteAccepted),
          backgroundColor: AppColors.successColor,
        ),
      );

      final amount = double.tryParse(
            quote.amount.replaceAll(RegExp(r'[^0-9.]'), ''),
          ) ??
          0;
      if (amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.invalidQuoteAmount),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context, true);
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ServicePaymentScreen(
            serviceRequestId: widget.requestId,
            amount: amount,
            currency: 'ETB',
          ),
        ),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] as String? ?? l10n.handymanAcceptQuoteFailed),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  Future<void> _rejectQuote(ServiceQuoteModel quote) async {
    final l10n = context.l10n;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusLG),
        ),
        title: Text(l10n.handymanRejectQuoteTitle),
        content: Text(
          l10n.handymanRejectQuoteMessage(quote.handymanName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorColor),
            child: Text(l10n.actionReject),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final result = await _repository.rejectQuote(
      widget.requestId,
      quote.id,
    );

    if (!mounted) return;
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] as String? ?? l10n.handymanQuoteRejected),
          backgroundColor: AppColors.successColor,
        ),
      );
      _fetchQuotes();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] as String? ?? l10n.handymanRejectQuoteFailed),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  Color _cardBorder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.darkBorder : const Color(0xFFEEEEEE);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;
    final borderColor = _cardBorder(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.handymanQuotesTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: colorScheme.onSurface,
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            height: 1,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primaryColor,
        onRefresh: _fetchQuotes,
        child: _isLoading
            ? const SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(AppColors.spaceMD),
                child: ShimmerListView(itemCount: 3),
              )
            : _error != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppColors.spaceLG),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.wifi_off_rounded,
                                  size: 48,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(height: AppColors.spaceMD),
                                Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium,
                                ),
                                const SizedBox(height: AppColors.spaceMD),
                                TextButton.icon(
                                  onPressed: _fetchQuotes,
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: Text(l10n.actionRetry),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : _quotes.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(AppColors.spaceLG),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Lottie.asset(
                                      'assets/animations/browse.json',
                                      width: 180,
                                      errorBuilder: (_, __, ___) => Icon(
                                        Icons.receipt_long_outlined,
                                        size: 64,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: AppColors.spaceMD),
                                    Text(
                                      l10n.handymanNoQuotesYet,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: AppColors.spaceSM),
                                    Text(
                                      l10n.handymanNoQuotesSubtitle,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppColors.spaceMD),
                        itemCount: _quotes.length,
                        itemBuilder: (context, index) {
                          final quote = _quotes[index];
                          return _QuoteCard(
                            quote: quote,
                            borderColor: borderColor,
                            onAccept: () => _acceptQuote(quote),
                            onReject: () => _rejectQuote(quote),
                            onViewProfile: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => HandymanDetailsScreen(
                                    handymanId: quote.handymanId,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  final ServiceQuoteModel quote;
  final Color borderColor;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onViewProfile;

  const _QuoteCard({
    required this.quote,
    required this.borderColor,
    required this.onAccept,
    required this.onReject,
    required this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;

    return Container(
      margin: const EdgeInsets.only(bottom: AppColors.spaceMD),
      padding: const EdgeInsets.all(AppColors.spaceMD),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppColors.radiusLG),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppColors.radiusMD),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.primaryColor,
                ),
              ),
              const SizedBox(width: AppColors.spaceMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quote.handymanName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      quote.formattedAmount ?? quote.amount,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (quote.description != null && quote.description!.isNotEmpty) ...[
            const SizedBox(height: AppColors.spaceMD),
            Text(
              quote.description!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: AppColors.spaceMD),
          Row(
            children: [
              TextButton(
                onPressed: onViewProfile,
                child: Text(l10n.handymanViewProfile),
              ),
              const Spacer(),
              if (quote.status == 'pending' && quote.isValid) ...[
                OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.errorColor,
                    side: BorderSide(
                      color: AppColors.errorColor.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppColors.radiusLG),
                    ),
                  ),
                  child: Text(l10n.actionReject),
                ),
                const SizedBox(width: AppColors.spaceSM),
                FilledButton(
                  onPressed: onAccept,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppColors.radiusLG),
                    ),
                  ),
                  child: Text(l10n.actionAccept),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
