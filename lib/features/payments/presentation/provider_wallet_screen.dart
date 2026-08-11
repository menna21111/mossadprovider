import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/mosaed_colors.dart';
import '../../../core/constants/styles_manager.dart';
import '../../../core/network/failure.dart';
import '../data/provider_wallet_model.dart';
import '../data/provider_wallet_repository.dart';

class ProviderWalletScreen extends StatefulWidget {
  const ProviderWalletScreen({super.key});

  @override
  State<ProviderWalletScreen> createState() => _ProviderWalletScreenState();
}

class _ProviderWalletScreenState extends State<ProviderWalletScreen> {
  bool _loading = true;
  String? _error;
  ProviderWallet? _wallet;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = context.read<ProviderWalletRepository>();
      final wallet = await repo.getWallet();
      if (!mounted) return;
      setState(() {
        _wallet = wallet;
        _loading = false;
      });
    } on ServerFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.errMessage;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'mosaedRetry'.tr();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MosaedColors.background,
      appBar: AppBar(
        backgroundColor: MosaedColors.surfaceWhite,
        elevation: 0,
        title: Text(
          'mosaedWallet'.tr(),
          style: getBoldStyle(fontSize: 18.sp, color: MosaedColors.textPrimary),
        ),
        iconTheme: const IconThemeData(color: MosaedColors.primary),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: MosaedColors.primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.account_balance_wallet_outlined,
                  size: 48.sp, color: MosaedColors.textHint),
              SizedBox(height: 12.h),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: getRegularStyle(
                  fontSize: 14.sp,
                  color: MosaedColors.textSecondary,
                ),
              ),
              SizedBox(height: 16.h),
              TextButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: Text('mosaedRetry'.tr()),
              ),
            ],
          ),
        ),
      );
    }

    final wallet = _wallet;
    if (wallet == null) return const SizedBox.shrink();
    final currency = 'mosaedCurrency'.tr();

    return RefreshIndicator(
      onRefresh: _load,
      color: MosaedColors.primary,
      child: ListView(
        padding: EdgeInsets.all(20.w),
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: MosaedColors.surfaceWhite,
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(color: MosaedColors.border),
              boxShadow: MosaedColors.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'mosaedAvailableBalance'.tr(),
                  style: getRegularStyle(
                    fontSize: 13.sp,
                    color: MosaedColors.textSecondary,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  '${wallet.availableBalance} $currency',
                  style: getBoldStyle(
                    fontSize: 26.sp,
                    color: MosaedColors.primary,
                  ),
                ),
                SizedBox(height: 14.h),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryBox(
                        label: 'mosaedTotalEarned'.tr(),
                        value: '${wallet.totalEarned} $currency',
                        icon: Icons.trending_up_rounded,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _SummaryBox(
                        label: 'mosaedTotalPaidOut'.tr(),
                        value: '${wallet.totalPaidOut} $currency',
                        icon: Icons.trending_down_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'mosaedRecentTransactions'.tr(),
            style: getBoldStyle(fontSize: 15.sp, color: MosaedColors.textPrimary),
          ),
          SizedBox(height: 10.h),
          if (wallet.recentTransactions.isEmpty)
            Text(
              'mosaedNoRecentTransactions'.tr(),
              style: getRegularStyle(
                fontSize: 13.sp,
                color: MosaedColors.textSecondary,
              ),
            )
          else
            ...wallet.recentTransactions.map(
              (transaction) => _TransactionTile(transaction: transaction),
            ),
        ],
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  const _SummaryBox({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: MosaedColors.primaryContainer.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: MosaedColors.primary, size: 18.sp),
          SizedBox(height: 8.h),
          Text(
            label,
            style: getRegularStyle(
              fontSize: 11.sp,
              color: MosaedColors.textSecondary,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: getBoldStyle(
              fontSize: 13.sp,
              color: MosaedColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});

  final ProviderRecentTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.transactionType.toLowerCase().contains('credit') ||
        transaction.transactionType.toLowerCase().contains('commission') ||
        transaction.transactionType.toLowerCase().contains('earned');
    final color = isCredit ? MosaedColors.success : MosaedColors.danger;

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: MosaedColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: MosaedColors.border),
      ),
      child: Row(
        children: [
          Icon(
            isCredit ? Icons.add_circle_rounded : Icons.remove_circle_rounded,
            color: color,
            size: 22.sp,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.transactionType,
                  style: getMediumStyle(
                    fontSize: 13.sp,
                    color: MosaedColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  transaction.createdAt,
                  style: getRegularStyle(
                    fontSize: 11.sp,
                    color: MosaedColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          Text(
            transaction.amount,
            style: getBoldStyle(fontSize: 13.sp, color: color),
          ),
        ],
      ),
    );
  }
}

