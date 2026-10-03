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
import '../../../core/widgets/mosaed_pill_tabs.dart';
import 'cubit/provider_due_lock_cubit.dart';
import 'widgets/payment_amount_text.dart';

class ProviderDuesScreen extends StatefulWidget {
  const ProviderDuesScreen({super.key});

  @override
  State<ProviderDuesScreen> createState() => _ProviderDuesScreenState();
}

class _ProviderDuesScreenState extends State<ProviderDuesScreen> {
  bool _loading = true;
  String? _error;
  ProviderDuesResponse? _dues;
  int _tab = 0;

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

  List<ProviderDueItem> _dueItems(ProviderDuesResponse dues) {
    if (dues.items.isNotEmpty) return dues.items;
    final outstanding = double.tryParse(dues.due.outstandingAmount) ?? 0;
    if (outstanding <= 0) return const [];
    return [
      ProviderDueItem(
        id: 'outstanding',
        title: 'mosaedPlatformDues'.tr(),
        serviceTotal: dues.lastServiceAmount,
        platformDue: dues.due.outstandingAmount,
        paymentLink: dues.due.currentPaymentLink,
      ),
    ];
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
          'mosaedPlatformDues'.tr(),
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

    if (_error != null || _dues == null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _error ?? 'mosaedRetry'.tr(),
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

    final dues = _dues!;
    final items = _dueItems(dues);

    return RefreshIndicator(
      onRefresh: _load,
      color: MosaedColors.brand,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
        children: [
          FinanceSummaryCard(
            mainLabel: 'mosaedTotalDues'.tr(),
            mainAmount: dues.due.outstandingAmount,
            rightLabel: 'mosaedLastService'.tr(),
            rightAmount: dues.lastServiceAmount,
            leftLabel: 'mosaedLastPlatformShare'.tr(),
            leftAmount: dues.lastPlatformShare,
          ),
          SizedBox(height: 18.h),
          _DuesTabs(
            selected: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
          SizedBox(height: 14.h),
          if (_tab == 0) ...[
            if (items.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 28.h),
                child: Text(
                  'mosaedNoProviderDues'.tr(),
                  textAlign: TextAlign.center,
                  style: getRegularStyle(
                    fontSize: 13.sp,
                    color: MosaedColors.textSecondary,
                  ),
                ),
              )
            else
              ...items.map(
                (item) => _DueItemTile(
                  item: item,
                  fallbackLink: dues.due.currentPaymentLink,
                  onPay: (link) => _openPaymentLink(link),
                ),
              ),
          ] else ...[
            if (dues.recentTransactions.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 28.h),
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
              ...dues.recentTransactions.map(
                (tx) => _HistoryTile(transaction: tx),
              ),
          ],
        ],
      ),
    );
  }
}

class _DuesTabs extends StatelessWidget {
  const _DuesTabs({required this.selected, required this.onChanged});

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return MosaedPillTabs(
      labels: ['mosaedDuesTab'.tr(), 'mosaedDuesHistoryTab'.tr()],
      selectedIndex: selected,
      onChanged: onChanged,
    );
  }
}

class _DueItemTile extends StatelessWidget {
  const _DueItemTile({
    required this.item,
    required this.fallbackLink,
    required this.onPay,
  });

  final ProviderDueItem item;
  final String fallbackLink;
  final ValueChanged<String> onPay;

  IconData get _icon {
    final c = item.category.toLowerCase();
    final t = item.title.toLowerCase();
    if (c.contains('plumb') || t.contains('سباك')) return Icons.plumbing;
    if (c.contains('electr') || t.contains('كهرب')) {
      return Icons.bolt_rounded;
    }
    if (c.contains('ac') || t.contains('تكييف')) {
      return Icons.ac_unit_rounded;
    }
    if (c.contains('clean') || t.contains('تنظيف')) {
      return Icons.cleaning_services_outlined;
    }
    return Icons.handyman_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final link =
        item.paymentLink.trim().isNotEmpty ? item.paymentLink : fallbackLink;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          child: Row(
            children: [
              GestureDetector(
                onTap: link.trim().isEmpty ? null : () => onPay(link),
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: link.trim().isEmpty
                        ? MosaedColors.brand.withValues(alpha: 0.35)
                        : MosaedColors.brand,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    'mosaedPayDue'.tr(),
                    style: getBoldStyle(fontSize: 12.sp, color: Colors.white),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: getBoldStyle(
                        fontSize: 13.sp,
                        color: MosaedColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Text(
                          '${'mosaedServiceTotal'.tr()}: ',
                          style: getRegularStyle(
                            fontSize: 11.sp,
                            color: MosaedColors.textSecondary,
                          ),
                        ),
                        PaymentAmountText(
                          amount: item.serviceTotal,
                          color: MosaedColors.textSecondary,
                          fontSize: 11,
                          iconSize: 10,
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Text(
                          '${'mosaedPlatformDueLine'.tr()}: ',
                          style: getRegularStyle(
                            fontSize: 11.sp,
                            color: MosaedColors.textSecondary,
                          ),
                        ),
                        PaymentAmountText(
                          amount: item.platformDue,
                          color: MosaedColors.textSecondary,
                          fontSize: 11,
                          iconSize: 10,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                width: 40.w,
                height: 40.w,
                decoration: const BoxDecoration(
                  color: MosaedColors.otpFill,
                  shape: BoxShape.circle,
                ),
                child: Icon(_icon, color: MosaedColors.brand, size: 20.sp),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: MosaedColors.fieldBorder),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.transaction});

  final ProviderRecentTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final titleKey = transaction.displayTitle;
    final title = titleKey.startsWith('mosaed') ? titleKey.tr() : titleKey;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        children: [
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
          PaymentAmountText(
            amount: transaction.amount.replaceFirst(RegExp(r'^[+-]'), ''),
            prefix: transaction.isCredit ? '+ ' : '- ',
            color: MosaedColors.success,
            fontSize: 13,
            iconSize: 11,
          ),
        ],
      ),
    );
  }
}
