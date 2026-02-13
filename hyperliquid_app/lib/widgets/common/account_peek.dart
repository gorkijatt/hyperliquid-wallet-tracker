import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/account_provider.dart';
import '../../providers/wallet_provider.dart';

class AccountPeek extends StatelessWidget {
  final VoidCallback onTap;

  const AccountPeek({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final wp = context.watch<WalletProvider>();
    if (!wp.hasWallet) return const SizedBox.shrink();

    return Consumer<AccountProvider>(
      builder: (context, ap, _) {
        final data = ap.data;
        if (data == null) return const SizedBox.shrink();

        return GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  fmtUsd(data.totalBalance),
                  style: AppTheme.mono.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                Container(width: 1, height: 14, color: AppColors.border),
                const SizedBox(width: 12),
                Text(
                  'uPnL ',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textDim,
                  ),
                ),
                Text(
                  '${data.totalPnl >= 0 ? '+' : ''}${fmtUsd(data.totalPnl)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: pnlColor(data.totalPnl),
                  ),
                ),
                const Spacer(),
                if (data.positions.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentDim,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${data.positions.length} pos',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: AppColors.textDim,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
