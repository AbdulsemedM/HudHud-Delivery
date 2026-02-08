import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/handyman/data/data_provider/handyman_data_provider.dart';
import 'package:hudhud_delivery/features/handyman/data/models/service_quote_model.dart';
import 'package:hudhud_delivery/features/handyman/data/repository/handyman_repository.dart';
import 'handyman_details_screen.dart';

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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Accept Quote'),
        content: Text(
          'Accept ${quote.formattedAmount ?? quote.amount} from ${quote.handymanName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.successColor),
            child: const Text('Accept'),
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
          content: Text(result['message'] as String? ?? 'Quote accepted'),
          backgroundColor: AppColors.successColor,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] as String? ?? 'Failed to accept'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  Future<void> _rejectQuote(ServiceQuoteModel quote) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Quote'),
        content: Text(
          'Reject quote from ${quote.handymanName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorColor),
            child: const Text('Reject'),
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
          content: Text(result['message'] as String? ?? 'Quote rejected'),
          backgroundColor: AppColors.successColor,
        ),
      );
      _fetchQuotes();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] as String? ?? 'Failed to reject'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Quotes',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: AppColors.lightTextPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.lightTextPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppColors.lightBorder.withOpacity(0.5),
            height: 1,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchQuotes,
        child: _isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _fetchQuotes,
                            child: Text(
                              'Retry',
                              style: TextStyle(color: AppColors.primaryColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : _quotes.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No quotes yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Handymen will send quotes soon',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _quotes.length,
                        itemBuilder: (context, index) {
                          final quote = _quotes[index];
                          return _QuoteCard(
                            quote: quote,
                            onAccept: () => _acceptQuote(quote),
                            onReject: () => _rejectQuote(quote),
                            onViewProfile: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      HandymanDetailsScreen(
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
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onViewProfile;

  const _QuoteCard({
    required this.quote,
    required this.onAccept,
    required this.onReject,
    required this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  quote.handymanName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
              Text(
                quote.formattedAmount ?? quote.amount,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
          if (quote.description != null && quote.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              quote.description!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              TextButton(
                onPressed: onViewProfile,
                child: Text(
                  'View Profile',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
              const Spacer(),
              if (quote.status == 'pending' && quote.isValid) ...[
                OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.errorColor,
                    side: const BorderSide(color: AppColors.errorColor),
                  ),
                  child: const Text('Reject'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.successColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Accept'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
