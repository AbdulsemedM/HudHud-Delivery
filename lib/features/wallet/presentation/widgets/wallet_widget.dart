import 'package:flutter/material.dart';

class WalletHeader extends StatelessWidget {
  const WalletHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const CircleAvatar(
          radius: 20,
          backgroundImage: NetworkImage('https://via.placeholder.com/40'),
        ),
        IconButton(
          icon: const Icon(
            Icons.notifications_outlined,
            color: Colors.black,
          ),
          onPressed: () {},
        ),
      ],
    );
  }
}

class BalanceCard extends StatelessWidget {
  final String balance;

  const BalanceCard({
    super.key,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.brown[300]!,
            Colors.orange[200]!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MY BALANCE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            balance,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class WalletActions extends StatelessWidget {
  final VoidCallback onAddMoney;
  final VoidCallback onSendMoney;

  const WalletActions({
    super.key,
    required this.onAddMoney,
    required this.onSendMoney,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextButton.icon(
            onPressed: onAddMoney,
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Add Money'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.purple,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextButton.icon(
            onPressed: onSendMoney,
            icon: const Icon(Icons.send_outlined),
            label: const Text('Send Money'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

class TransactionsList extends StatelessWidget {
  final List<TransactionItem> transactions;
  final VoidCallback onSeeAll;

  const TransactionsList({
    super.key,
    required this.transactions,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: onSeeAll,
              child: const Text(
                'See All',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: transactions.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            return TransactionListItem(transaction: transactions[index]);
          },
        ),
      ],
    );
  }
}

class TransactionListItem extends StatelessWidget {
  final TransactionItem transaction;

  const TransactionListItem({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            transaction.date,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PKR${transaction.amount}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey[200]!,
                  ),
                ),
                child: Text(
                  transaction.type,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TransactionItem {
  final String date;
  final String amount;
  final String type;

  const TransactionItem({
    required this.date,
    required this.amount,
    required this.type,
  });
}
