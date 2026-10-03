import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/functions.dart';
import '../../../../core/constants/mosaed_colors.dart';
import '../../../../core/constants/styles_manager.dart';
import '../../../../core/network/failure.dart';
import '../../../../core/widgets/mosaed_confirm_dialog.dart';
import '../../data/bank_accounts_repository.dart';

Future<bool?> showManageBankAccountSheet(
  BuildContext context, {
  required BankAccount account,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: MosaedColors.surfaceWhite,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (_) => _ManageBankAccountSheet(account: account),
  );
}

class _ManageBankAccountSheet extends StatelessWidget {
  const _ManageBankAccountSheet({required this.account});

  final BankAccount account;

  Future<void> _setDefault(BuildContext context) async {
    try {
      await context.read<BankAccountsRepository>().setDefault(account.id);
      if (!context.mounted) return;
      AppFunctions.showsToast(
        'mosaedDefaultAccountUpdated'.tr(),
        MosaedColors.success,
        context,
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!context.mounted) return;
      final message = e is Failure
          ? e.errMessage
          : 'mosaedBankAccountSaveError'.tr();
      AppFunctions.showsToast(message, MosaedColors.danger, context);
    }
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showMosaedConfirmDialog(
      context,
      title: 'mosaedDeleteBankAccountTitle'.tr(),
      message: 'mosaedDeleteBankAccountBody'.tr(),
      confirmText: 'mosaedDelete'.tr(),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await context.read<BankAccountsRepository>().deleteAccount(account.id);
      if (!context.mounted) return;
      AppFunctions.showsToast(
        'mosaedBankAccountDeleted'.tr(),
        MosaedColors.success,
        context,
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!context.mounted) return;
      final message = e is Failure
          ? e.errMessage
          : 'mosaedBankAccountSaveError'.tr();
      AppFunctions.showsToast(message, MosaedColors.danger, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 20.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: MosaedColors.fieldBorder,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'mosaedManageCard'.tr(),
              style: getBoldStyle(
                fontSize: 18.sp,
                color: MosaedColors.textPrimary,
              ),
            ),
            SizedBox(height: 14.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      color: MosaedColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      account.bankName.trim().isNotEmpty
                          ? account.bankName.trim()[0]
                          : 'ب',
                      style: getBoldStyle(
                        fontSize: 16.sp,
                        color: MosaedColors.brand,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.bankName,
                          style: getBoldStyle(
                            fontSize: 14.sp,
                            color: MosaedColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          account.maskedIban,
                          style: getRegularStyle(
                            fontSize: 12.sp,
                            color: MosaedColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.credit_card_outlined,
                    color: MosaedColors.textHint,
                    size: 22.sp,
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            if (!account.isDefault)
              _ActionTile(
                icon: Icons.star_outline_rounded,
                label: 'mosaedSetAsDefault'.tr(),
                onTap: () => _setDefault(context),
              ),
            _ActionTile(
              icon: Icons.delete_outline_rounded,
              label: 'mosaedDeleteCard'.tr(),
              destructive: true,
              onTap: () => _delete(context),
            ),
            SizedBox(height: 8.h),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'cancel'.tr(),
                  style: getBoldStyle(
                    fontSize: 14.sp,
                    color: MosaedColors.brand,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? MosaedColors.danger : MosaedColors.textPrimary;
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 4.w),
      leading: Icon(icon, color: color, size: 22.sp),
      title: Text(
        label,
        style: getMediumStyle(fontSize: 14.sp, color: color),
      ),
      onTap: onTap,
    );
  }
}
