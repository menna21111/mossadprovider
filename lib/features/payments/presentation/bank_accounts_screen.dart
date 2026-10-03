import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/functions.dart';
import '../../../core/constants/mosaed_colors.dart';
import '../../../core/constants/styles_manager.dart';
import '../../../core/network/failure.dart';
import '../data/bank_accounts_repository.dart';
import 'widgets/add_bank_account_sheet.dart';
import 'widgets/manage_bank_account_sheet.dart';

class BankAccountsScreen extends StatefulWidget {
  const BankAccountsScreen({super.key});

  @override
  State<BankAccountsScreen> createState() => _BankAccountsScreenState();
}

class _BankAccountsScreenState extends State<BankAccountsScreen> {
  List<BankAccount> _accounts = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final accounts =
          await context.read<BankAccountsRepository>().getAccounts();
      if (!mounted) return;
      setState(() {
        _accounts = accounts;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is Failure
            ? e.errMessage
            : 'mosaedBankAccountSaveError'.tr();
      });
    }
  }

  Future<void> _onAddTap() async {
    final added = await showAddBankAccountSheet(context);
    if (added == true && mounted) _reload();
  }

  Future<void> _selectAccount(BankAccount account) async {
    if (account.isDefault) return;
    try {
      await context.read<BankAccountsRepository>().setDefault(account.id);
      if (mounted) _reload();
    } catch (e) {
      if (!mounted) return;
      final message = e is Failure
          ? e.errMessage
          : 'mosaedBankAccountSaveError'.tr();
      AppFunctions.showsToast(message, MosaedColors.danger, context);
    }
  }

  Future<void> _openManage(BankAccount account) async {
    final changed = await showManageBankAccountSheet(context, account: account);
    if (changed == true && mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MosaedColors.surfaceWhite,
      appBar: AppBar(
        backgroundColor: MosaedColors.surfaceWhite,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios,
            color: MosaedColors.textPrimary,
            size: 18.sp,
          ),
        ),
        title: Text(
          'mosaedBankAccount'.tr(),
          style: getBoldStyle(fontSize: 16.sp, color: MosaedColors.textPrimary),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: const Divider(height: 1, color: MosaedColors.fieldBorder),
        ),
      ),
      body: RefreshIndicator(
        color: MosaedColors.brand,
        onRefresh: _reload,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 28.h),
          children: [
            Text(
              'mosaedChooseBankAccount'.tr(),
              style: getBoldStyle(
                fontSize: 18.sp,
                color: MosaedColors.textPrimary,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'mosaedChooseBankAccountHint'.tr(),
              style: getRegularStyle(
                fontSize: 13.sp,
                color: MosaedColors.textSecondary,
              ),
            ),
            SizedBox(height: 18.h),
            if (_loading)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 48.h),
                child: const Center(
                  child: CircularProgressIndicator(color: MosaedColors.brand),
                ),
              )
            else if (_error != null)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 28.h),
                child: Column(
                  children: [
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: getRegularStyle(
                        fontSize: 14.sp,
                        color: MosaedColors.danger,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    TextButton(
                      onPressed: _reload,
                      child: Text(
                        'retry'.tr(),
                        style: getBoldStyle(
                          fontSize: 14.sp,
                          color: MosaedColors.brand,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (_accounts.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 28.h),
                child: Text(
                  'mosaedNoBankAccountsYet'.tr(),
                  textAlign: TextAlign.center,
                  style: getRegularStyle(
                    fontSize: 14.sp,
                    color: MosaedColors.textHint,
                  ),
                ),
              )
            else
              ..._accounts.map(
                (account) => Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: _BankAccountCard(
                    account: account,
                    selected: account.isDefault,
                    onSelect: () => _selectAccount(account),
                    onManage: () => _openManage(account),
                  ),
                ),
              ),
            if (!_loading && _error == null) ...[
              SizedBox(height: 4.h),
              _AddBankDashedButton(onTap: _onAddTap),
            ],
          ],
        ),
      ),
    );
  }
}

class _BankAccountCard extends StatelessWidget {
  const _BankAccountCard({
    required this.account,
    required this.selected,
    required this.onSelect,
    required this.onManage,
  });

  final BankAccount account;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: MosaedColors.surfaceWhite,
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        onTap: onSelect,
        onLongPress: onManage,
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 14.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: selected ? MosaedColors.brand : MosaedColors.fieldBorder,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _BankLogo(bankName: account.bankName),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                account.bankName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: getBoldStyle(
                                  fontSize: 14.sp,
                                  color: MosaedColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                account.accountHolderName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: getRegularStyle(
                                  fontSize: 13.sp,
                                  color: MosaedColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                account.maskedIban,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: getRegularStyle(
                                  fontSize: 12.sp,
                                  color: MosaedColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10.w),
                  _SelectionDot(selected: selected),
                ],
              ),
              if (account.isDefault) ...[
                SizedBox(height: 12.h),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 5.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0E6),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      'mosaedDefaultBankAccount'.tr(),
                      style: getMediumStyle(
                        fontSize: 11.sp,
                        color: MosaedColors.brand,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionDot extends StatelessWidget {
  const _SelectionDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    if (selected) {
      return Container(
        width: 22.w,
        height: 22.w,
        decoration: const BoxDecoration(
          color: MosaedColors.brand,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.check_rounded,
          color: Colors.white,
          size: 14.sp,
        ),
      );
    }

    return Container(
      width: 22.w,
      height: 22.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: MosaedColors.brand, width: 1.6),
      ),
    );
  }
}

class _BankLogo extends StatelessWidget {
  const _BankLogo({required this.bankName});

  final String bankName;

  Color get _accent {
    final name = bankName.trim();
    if (name.contains('الراجحي')) return const Color(0xFF006C35);
    if (name.contains('الأهلي') || name.contains('اهلي')) {
      return const Color(0xFF1B8354);
    }
    if (name.contains('الرياض')) return const Color(0xFF003366);
    if (name.contains('الإنماء') || name.contains('الانماء')) {
      return const Color(0xFF5C2D91);
    }
    if (name.contains('الفرنسي')) return const Color(0xFF004B93);
    if (name.contains('ساب')) return const Color(0xFF00838F);
    if (name.contains('البلاد')) return const Color(0xFF9C1F2E);
    if (name.contains('الجزيرة')) return const Color(0xFF0D7377);
    return MosaedColors.brand;
  }

  @override
  Widget build(BuildContext context) {
    final letter = bankName.trim().isNotEmpty ? bankName.trim()[0] : 'ب';
    return Container(
      width: 42.w,
      height: 42.w,
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: _accent.withValues(alpha: 0.18)),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: getBoldStyle(fontSize: 16.sp, color: _accent),
      ),
    );
  }
}

class _AddBankDashedButton extends StatelessWidget {
  const _AddBankDashedButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: MosaedColors.brand.withValues(alpha: 0.55),
            radius: 16.r,
          ),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 16.h),
            alignment: Alignment.center,
            child: Text(
              '+ ${'mosaedAddBankAccount'.tr()}',
              style: getBoldStyle(fontSize: 14.sp, color: MosaedColors.brand),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(radius),
        ),
      );

    const dashWidth = 6.0;
    const dashSpace = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
