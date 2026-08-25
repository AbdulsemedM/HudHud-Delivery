import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';

class FAQsScreen extends StatefulWidget {
  const FAQsScreen({super.key});

  @override
  State<FAQsScreen> createState() => _FAQsScreenState();
}

class _FAQsScreenState extends State<FAQsScreen> {
  String _selectedCategory = 'General';
  String _searchQuery = '';
  int? _expandedIndex;

  final List<String> _categories = ['General', 'Security', 'Privacy', 'Payment'];

  List<Map<String, dynamic>> get _filteredQuestions {
    if (_searchQuery.isEmpty) {
      return _generalQuestions;
    }
    return _generalQuestions
        .where((q) => (q['question'] as String)
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  final List<Map<String, dynamic>> _generalQuestions = [
    {
      'question': 'How does one onboard my business?',
      'answer':
          'This Businesses is designed to help users manage their tasks efficiently and improve their productivity through simple',
    },
    {
      'question': 'How can I contact customer support?',
      'answer':
          'You can contact our customer support team through the Help desk section in the app settings, or by emailing us at support@hudhuddelivery.com',
    },
    {
      'question': 'Can I cancel my subscription at any time?',
      'answer':
          'Yes, you can cancel your subscription at any time from your account settings. Your subscription will remain active until the end of the current billing period.',
    },
    {
      'question': 'Is my data secure on this platform?',
      'answer':
          'Yes, we take data security seriously. All your personal information is encrypted and stored securely. We follow industry-standard security practices.',
    },
    {
      'question': 'How do I report a technical issue?',
      'answer':
          'You can report technical issues through the Help desk section in settings, or by contacting our support team directly.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(context.l10n.settingsFaqs),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Header Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How can we help you?',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? colorScheme.surfaceContainerHighest : Colors.grey[100],
                    borderRadius: BorderRadius.circular(AppColors.radiusLG),
                  ),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search question',
                      hintStyle: TextStyle(
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: theme.iconTheme.color?.withValues(alpha: 0.75),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Category Tabs
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = _selectedCategory == category;
                      return Padding(
                        padding: EdgeInsets.only(
                          right: index < _categories.length - 1 ? 12 : 0,
                        ),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategory = category;
                              _expandedIndex = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryColor
                                  : colorScheme.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primaryColor
                                    : (isDark ? colorScheme.outline : Colors.grey[300]!),
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : AppColors.primaryColor,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Questions List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredQuestions.length,
              itemBuilder: (context, index) {
                final question = _filteredQuestions[index];
                final isExpanded = _expandedIndex == index;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isExpanded
                        ? AppColors.primaryColor.withValues(alpha: 0.1)
                        : colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppColors.radiusLG),
                    border: Border.all(
                      color: isDark ? colorScheme.outline : Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            _expandedIndex = isExpanded ? null : index;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  question['question'] as String,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isExpanded
                                        ? AppColors.primaryColor
                                        : theme.textTheme.titleMedium?.color,
                                  ),
                                ),
                              ),
                              Icon(
                                isExpanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: isExpanded
                                    ? AppColors.primaryColor
                                    : theme.iconTheme.color?.withValues(alpha: 0.75),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isExpanded)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Text(
                            question['answer'] as String,
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.85),
                              height: 1.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

