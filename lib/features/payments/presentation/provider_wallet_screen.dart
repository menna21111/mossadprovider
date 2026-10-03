import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/mosaed_colors.dart';
import '../../../core/constants/styles_manager.dart';
import '../../../core/network/failure.dart';
import '../data/provider_wallet_model.dart';
import '../data/provider_wallet_repository.dart';
import 'widgets/payment_amount_text.dart';

enum _TxFilter { all, topUp, payments, refunds }

class ProviderWalletScreen extends StatefulWidget {
  const ProviderWalletScreen({super.key});

  @override
  State<ProviderWalletScreen> createState() => _ProviderWalletScreenState();
}

class _ProviderWalletScreenState extends State<ProviderWalletScreen> {
  bool _loading = true;
  String? _error;
  ProviderWallet? _wallet;
  _TxFilter _filter = _TxFilter.all;

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

  List<ProviderRecentTransaction> _filtered(List<ProviderRecentTransaction> list) {
    switch (_filter) {
      case _TxFilter.all:
        return list;
      case _TxFilter.topUp:
        return list.where((t) {
          final x = t.transactionType.toLowerCase();
          return x.contains('top') ||
              x.contains('شحن') ||
              x.contains('credit') ||
              x.contains('charge_wallet');
        }).toList();
      case _TxFilter.payments:
        return list.where((t) {
          final x = t.transactionType.toLowerCase();
          return x.contains('payment') ||
              x.contains('fee') ||
              x.contains('debit') ||
              x.contains('مدفوع') ||
              x.contains('رسوم');
        }).toList();
      case _TxFilter.refunds:
        return list.where((t) {
          final x = t.transactionType.toLowerCase();
          return x.contains('refund') || x.contains('استرداد');
        }).toList();
    }
  }

  Map<String, List<ProviderRecentTransaction>> _groupByDate(
    List<ProviderRecentTransaction> list,
  ) {
    final map = <String, List<ProviderRecentTransaction>>{};
    for (final tx in list) {
      final key = _dateLabel(tx.createdAt);
      map.putIfAbsent(key, () => []).add(tx);
    }
    return map;
  }

  String _dateLabel(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw.isEmpty ? '—' : raw;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'mosaedToday'.tr();
    if (diff == 1) return 'mosaedYesterday'.tr();
    return DateFormat('d MMMM yyyy', context.locale.toString()).format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MosaedColors.surfaceWhite,
      appBar: AppBar(
        backgroundColor: MosaedColors.surfaceWhite,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'mosaedMyProfits'.tr(),
          style: getBoldStyle(fontSize: 16.sp, color: MosaedColors.textPrimary),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: const Divider(height: 1, color: MosaedColors.fieldBorder),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: MosaedColors.brand),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: getRegularStyle(
                  fontSize: 14.sp,
                  color: MosaedColors.textSecondary,
                ),
              ),
              SizedBox(height: 16.h),
              TextButton(onPressed: _load, child: Text('mosaedRetry'.tr())),
            ],
          ),
        ),
      );
    }

    final wallet = _wallet;
    if (wallet == null) return const SizedBox.shrink();
    final filtered = _filtered(wallet.recentTransactions);
    final groups = _groupByDate(filtered);

    return RefreshIndicator(
      onRefresh: _load,
      color: MosaedColors.brand,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
        children: [
          FinanceSummaryCard(
            mainLabel: 'mosaedMyProfits'.tr(),
            mainAmount: wallet.availableBalance,
            rightLabel: 'mosaedPendingProcessing'.tr(),
            rightAmount: wallet.pendingBalance,
            leftLabel: 'mosaedTotalReturns'.tr(),
            leftAmount: wallet.totalEarned,
          ),
          SizedBox(height: 22.h),
          Text(
            'mosaedTransactions'.tr(),
            style: getBoldStyle(fontSize: 15.sp, color: MosaedColors.textPrimary),
          ),
          SizedBox(height: 12.h),
          _FilterChips(
            selected: _filter,
            onChanged: (v) => setState(() => _filter = v),
          ),
          SizedBox(height: 10.h),
          Text(
            'mosaedLast7Days'.tr(),
            style: getRegularStyle(
              fontSize: 12.sp,
              color: MosaedColors.textSecondary,
            ),
          ),
          SizedBox(height: 12.h),
          if (filtered.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: Text(
                'mosaedNoRecentTransactions'.tr(),
                textAlign: TextAlign.center,
                style: getRegularStyle(
                  fontSize: 13.sp,
                  color: MosaedColors.textSecondary,
                ),
              ),
            )
          else
            ...groups.entries.expand((entry) {
              return [
                _DateDivider(label: entry.key),
                ...entry.value.map((tx) => _TxTile(transaction: tx)),
              ];
            }),
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.selected, required this.onChanged});

  final _TxFilter selected;
  final ValueChanged<_TxFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = <(_TxFilter, String)>[
      (_TxFilter.all, 'mosaedFilterAll'.tr()),
      (_TxFilter.topUp, 'mosaedFilterTopUp'.tr()),
      (_TxFilter.payments, 'mosaedFilterPayments'.tr()),
      (_TxFilter.refunds, 'mosaedFilterRefunds'.tr()),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final item in items) ...[
            _Chip(
              label: item.$2,
              selected: selected == item.$1,
              onTap: () => onChanged(item.$1),
            ),
            SizedBox(width: 8.w),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: selected ? MosaedColors.otpFill : MosaedColors.surfaceWhite,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: selected ? MosaedColors.brand : MosaedColors.fieldBorder,
          ),
        ),
        child: Text(
          label,
          style: getMediumStyle(
            fontSize: 12.sp,
            color: selected ? MosaedColors.brand : MosaedColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _DateDivider extends StatelessWidget {
  const _DateDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        children: [
          const Expanded(child: Divider(color: MosaedColors.fieldBorder)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: Text(
              label,
              style: getRegularStyle(
                fontSize: 11.sp,
                color: MosaedColors.textHint,
              ),
            ),
          ),
          const Expanded(child: Divider(color: MosaedColors.fieldBorder)),
        ],
      ),
    );
  }
}

class _TxTile extends StatelessWidget {
  const _TxTile({required this.transaction});

  final ProviderRecentTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final credit = transaction.isCredit;
    final amountColor = MosaedColors.success;
    final absAmount = transaction.amount.replaceFirst(RegExp(r'^[+-]'), '');
    final prefix = credit ? '+ ' : '- ';

    final (bg, icon, iconColor) = _styleFor(transaction);

    final titleKey = transaction.displayTitle;
    final title = titleKey.startsWith('mosaed') ? titleKey.tr() : titleKey;

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20.sp),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: getMediumStyle(
                    fontSize: 13.sp,
                    color: MosaedColors.textPrimary,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  '#${'mosaedTxNumber'.tr()} : ${transaction.id}',
                  style: getRegularStyle(
                    fontSize: 11.sp,
                    color: MosaedColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          PaymentAmountText(
            amount: absAmount,
            prefix: prefix,
            color: amountColor,
            fontSize: 13,
            iconSize: 11,
          ),
        ],
      ),
    );
  }

  (Color, IconData, Color) _styleFor(ProviderRecentTransaction tx) {
    final t = tx.transactionType.toLowerCase();
    if (t.contains('refund') || t.contains('استرداد')) {
      return (
        const Color(0xFFF1F1F1),
        Icons.reply_rounded,
        MosaedColors.textSecondary,
      );
    }
    if (t.contains('fee') || t.contains('platform') || t.contains('رسوم')) {
      return (
        MosaedColors.otpFill,
        Icons.currency_exchange_rounded,
        MosaedColors.brand,
      );
    }
    return (
      const Color(0xFFE8F1FF),
      Icons.account_balance_wallet_outlined,
      const Color(0xFF3B82F6),
    );
  }
}
