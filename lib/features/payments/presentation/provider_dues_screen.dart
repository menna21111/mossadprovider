import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/mosaed_colors.dart';
import '../../../core/constants/styles_manager.dart';
import '../../../core/network/failure.dart';
import '../data/provider_dues_repository.dart';
import '../data/provider_dues_response_model.dart';
import '../data/provider_wallet_model.dart';
import 'cubit/provider_due_lock_cubit.dart';

class ProviderDuesScreen extends StatefulWidget {
  const ProviderDuesScreen({super.key});

  @override
  State<ProviderDuesScreen> createState() => _ProviderDuesScreenState();
}

class _ProviderDuesScreenState extends State<ProviderDuesScreen> {
  bool _loading = true;
  String? _error;
  ProviderDuesResponse? _dues;

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
      final dueLockCubit = context.read<ProviderDueLockCubit>();
      final repo = context.read<ProviderDuesRepository>();
      final dues = await repo.getDues();

      // Keep lock state in sync with the dues payload.
      dueLockCubit.applyStatus(dues.due);

      if (!mounted) return;
      setState(() {
        _dues = dues;
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

  Future<void> _openPaymentLink(String link) async {
    if (link.trim().isEmpty) return;
    final uri = Uri.tryParse(link);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MosaedColors.background,
      appBar: AppBar(
        backgroundColor: MosaedColors.surfaceWhite,
        elevation: 0,
        title: Text(
          'mosaedDuePaymentRequiredTitle'.tr(),
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

    if (_error != null || _dues == null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long_outlined,
                  size: 48.sp, color: MosaedColors.textHint),
              SizedBox(height: 12.h),
              Text(
                _error ?? 'mosaedRetry'.tr(),
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

    final dues = _dues!;
    final due = dues.due;
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
                  'mosaedDueOutstandingAmount'.tr(
                    args: [due.outstandingAmount],
                  ),
                  style: getMediumStyle(
                    fontSize: 14.sp,
                    color: MosaedColors.textSecondary,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  '${due.outstandingAmount} $currency',
                  style: getBoldStyle(
                    fontSize: 26.sp,
                    color: MosaedColors.primary,
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  due.isBlocked
                      ? 'mosaedDueLockHint'.tr()
                      : 'mosaedAccountUnblocked'.tr(),
                  style: getRegularStyle(
                    fontSize: 13.sp,
                    color: due.isBlocked
                        ? MosaedColors.danger
                        : MosaedColors.success,
                  ),
                ),
                if (due.currentPaymentLink.trim().isNotEmpty) ...[
                  SizedBox(height: 14.h),
                  ElevatedButton.icon(
                    onPressed: () => _openPaymentLink(due.currentPaymentLink),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MosaedColors.primaryContainer,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    icon: const Icon(Icons.payment_rounded),
                    label: Text('mosaedPayNow'.tr()),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 18.h),
          Text(
            'mosaedRecentTransactions'.tr(),
            style: getBoldStyle(fontSize: 15.sp, color: MosaedColors.textPrimary),
          ),
          SizedBox(height: 10.h),
          if (dues.recentTransactions.isEmpty)
            Text(
              'mosaedNoRecentTransactions'.tr(),
              style: getRegularStyle(
                fontSize: 13.sp,
                color: MosaedColors.textSecondary,
              ),
            )
          else
            ...dues.recentTransactions.map(
              (tx) => _DueTransactionTile(transaction: tx),
            ),
        ],
      ),
    );
  }
}

class _DueTransactionTile extends StatelessWidget {
  const _DueTransactionTile({required this.transaction});

  final ProviderRecentTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final type = transaction.transactionType.toLowerCase();
    final isCharge = type.contains('charge') || type.contains('debit');
    final color = isCharge ? MosaedColors.danger : MosaedColors.success;
    final currency = 'mosaedCurrency'.tr();

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
            isCharge ? Icons.remove_circle_rounded : Icons.add_circle_rounded,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${transaction.amount} $currency',
                style: getBoldStyle(fontSize: 13.sp, color: color),
              ),
              SizedBox(height: 2.h),
              Text(
                '${'mosaedBalanceAfter'.tr()}: ${transaction.balanceAfter}',
                style: getRegularStyle(
                  fontSize: 10.sp,
                  color: MosaedColors.textHint,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
