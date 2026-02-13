import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/account_provider.dart';
import '../../providers/funding_provider.dart';
import '../../providers/orders_provider.dart';
import '../../providers/trades_provider.dart';
import '../../providers/wallet_provider.dart';

class WalletModal extends StatefulWidget {
  const WalletModal({super.key});

  @override
  State<WalletModal> createState() => _WalletModalState();
}

class _WalletModalState extends State<WalletModal> {
  final _searchController = TextEditingController();
  final _addressController = TextEditingController();
  final _labelController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _addressController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  void _addWallet() {
    final address = _addressController.text.trim();
    final label = _labelController.text.trim();
    if (address.isEmpty) return;

    final wp = context.read<WalletProvider>();
    try {
      wp.addWallet(address, label);
      _addressController.clear();
      _labelController.clear();
      _reloadProviders();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Wallet added')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _selectWallet(String address) {
    final wp = context.read<WalletProvider>();
    wp.setActiveWallet(address);
    _reloadProviders();
    Navigator.of(context).pop();
  }

  void _reloadProviders() {
    final wp = context.read<WalletProvider>();
    final addr = wp.activeAddress;
    context.read<AccountProvider>().onWalletChanged(addr);
    context.read<OrdersProvider>().onWalletChanged(addr);
    context.read<TradesProvider>().onWalletChanged(addr);
    context.read<FundingProvider>().onWalletChanged(addr);
  }

  void _removeWallet(String address) {
    final wp = context.read<WalletProvider>();
    wp.removeWallet(address);
    _reloadProviders();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Wallet removed')));
  }

  void _renameWallet(String address, String currentLabel) {
    final controller = TextEditingController(text: currentLabel);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Rename Wallet'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Label'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<WalletProvider>().renameWallet(
                address,
                controller.text.trim(),
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Wallet renamed')));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletProvider>(
      builder: (context, wp, _) {
        final wallets = wp.search(_searchQuery);

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (_, scrollController) {
            return Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textDim,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Manage Wallets',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, size: 20),
                      ),
                    ],
                  ),
                ),
                // Search
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: const InputDecoration(
                      hintText: 'Search wallets...',
                      prefixIcon: Icon(Icons.search, size: 18),
                      isDense: true,
                    ),
                  ),
                ),
                // Wallet list
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: wallets.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (_, i) {
                      final w = wallets[i];
                      final isActive = w.address == wp.activeAddress;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.accentDim
                              : AppColors.card,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isActive
                                ? AppColors.accent.withValues(alpha: 0.3)
                                : AppColors.border,
                          ),
                        ),
                        child: InkWell(
                          onTap: () => _selectWallet(w.address),
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        w.displayName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${w.address.substring(0, 10)}...${w.address.substring(w.address.length - 6)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy, size: 16),
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(text: w.address),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Address copied'),
                                      ),
                                    );
                                  },
                                  tooltip: 'Copy',
                                  visualDensity: VisualDensity.compact,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 16),
                                  onPressed: () =>
                                      _renameWallet(w.address, w.label),
                                  tooltip: 'Rename',
                                  visualDensity: VisualDensity.compact,
                                ),
                                if (wp.wallets.length > 1)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: AppColors.red,
                                    ),
                                    onPressed: () => _removeWallet(w.address),
                                    tooltip: 'Remove',
                                    visualDensity: VisualDensity.compact,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Add wallet form
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Wallet Address',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          hintText: '0x...',
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Label (optional)',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _labelController,
                        decoration: const InputDecoration(
                          hintText: 'My Wallet',
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _addWallet,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Wallet'),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            );
          },
        );
      },
    );
  }
}
