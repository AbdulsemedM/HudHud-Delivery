import 'package:flutter/material.dart';
import '../widgets/wallet_widget.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<TransactionItem> transactions = [
      const TransactionItem(
        date: 'ADDED ON 29 JUN 2021',
        amount: '95',
        type: 'WALLET',
      ),
      const TransactionItem(
        date: 'SENT ON 29 JUN 2021',
        amount: '200',
        type: 'CASH',
      ),
      const TransactionItem(
        date: 'ADDED ON 29 JUN 2021',
        amount: '713',
        type: 'WALLET',
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const WalletHeader(),
              const SizedBox(height: 24),
              const BalanceCard(
                balance: 'PKR 223,456.00',
              ),
              const SizedBox(height: 24),
              WalletActions(
                onAddMoney: () {
                  // Handle add money
                },
                onSendMoney: () {
                  // Handle send money
                },
              ),
              const SizedBox(height: 24),
              TransactionsList(
                transactions: transactions,
                onSeeAll: () {
                  // Handle see all transactions
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
