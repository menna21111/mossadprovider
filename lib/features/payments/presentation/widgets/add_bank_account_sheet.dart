import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/functions.dart';
import '../../../../core/constants/mosaed_colors.dart';
import '../../../../core/constants/styles_manager.dart';
import '../../../../core/network/failure.dart';
import '../../../../core/widgets/mosaed_dropdown.dart';
import '../../../auth/presentation/widgets/mosaed_buttons.dart';
import '../../data/bank_accounts_repository.dart';

Future<bool?> showAddBankAccountSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: MosaedColors.surfaceWhite,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (_) => const _AddBankAccountSheet(),
  );
}

class _AddBankAccountSheet extends StatefulWidget {
  const _AddBankAccountSheet();

  @override
  State<_AddBankAccountSheet> createState() => _AddBankAccountSheetState();
}

class _AddBankAccountSheetState extends State<_AddBankAccountSheet> {
  final _ibanController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _holderController = TextEditingController();
  String? _bankName;
  bool _isDefault = true;
  bool _saving = false;

  @override
  void dispose() {
    _ibanController.dispose();
    _accountNumberController.dispose();
    _holderController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final bank = (_bankName ?? '').trim();
    final iban = _ibanController.text.trim().replaceAll(RegExp(r'\s+'), '');
    final accountNumber = _accountNumberController.text.trim();
    final holder = _holderController.text.trim();

    if (bank.isEmpty) {
      AppFunctions.showsToast(
        'mosaedBankNameRequired'.tr(),
        MosaedColors.danger,
        context,
      );
      return;
    }
    if (accountNumber.isEmpty) {
      AppFunctions.showsToast(
        'mosaedAccountNumberRequired'.tr(),
        MosaedColors.danger,
        context,
      );
      return;
    }
    if (iban.length < 8) {
      AppFunctions.showsToast(
        'mosaedIbanRequired'.tr(),
        MosaedColors.danger,
        context,
      );
      return;
    }
    if (holder.isEmpty) {
      AppFunctions.showsToast(
        'mosaedHolderNameRequired'.tr(),
        MosaedColors.danger,
        context,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = context.read<BankAccountsRepository>();
      await repo.addAccount(
        CreateBankAccountPayload(
          bankName: bank,
          accountHolderName: holder,
          accountNumber: accountNumber,
          iban: iban,
          isDefault: _isDefault,
        ),
      );
      if (!mounted) return;
      AppFunctions.showsToast(
        'mosaedBankAccountAdded'.tr(),
        MosaedColors.success,
        context,
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      final message = e is Failure
          ? e.errMessage
          : 'mosaedBankAccountSaveError'.tr();
      AppFunctions.showsToast(message, MosaedColors.danger, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final banks = BankAccountsRepository.saudiBanks
        .map((b) => MosaedDropdownItem(value: b, label: b))
        .toList();

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 20.h),
          child: Column(
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
                'mosaedAddBankAccount'.tr(),
                style: getBoldStyle(
                  fontSize: 18.sp,
                  color: MosaedColors.textPrimary,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'mosaedAddBankAccountHint'.tr(),
                style: getRegularStyle(
                  fontSize: 13.sp,
                  color: MosaedColors.textSecondary,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 18.h),
              MosaedDropdown<String>(
                title: 'mosaedBankName'.tr(),
                hint: 'mosaedChooseBankName'.tr(),
                icon: Icons.account_balance_outlined,
                items: banks,
                selectedValue: _bankName,
                onSelected: (value) => setState(() => _bankName = value),
              ),
              SizedBox(height: 12.h),
              _LabeledField(
                label: 'mosaedAccountHolderName'.tr(),
                hint: 'mosaedAccountHolderNameHint'.tr(),
                icon: Icons.person_outline_rounded,
                controller: _holderController,
              ),
              SizedBox(height: 12.h),
              _LabeledField(
                label: 'mosaedAccountNumber'.tr(),
                hint: 'mosaedAccountNumberHint'.tr(),
                icon: Icons.numbers_rounded,
                controller: _accountNumberController,
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 12.h),
              _LabeledField(
                label: 'mosaedIban'.tr(),
                hint: 'mosaedIbanHint'.tr(),
                icon: Icons.credit_card_outlined,
                controller: _ibanController,
                keyboardType: TextInputType.visiblePassword,
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'mosaedSetAsDefaultAccount'.tr(),
                          style: getBoldStyle(
                            fontSize: 14.sp,
                            color: MosaedColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'mosaedSetAsDefaultAccountHint'.tr(),
                          style: getRegularStyle(
                            fontSize: 12.sp,
                            color: MosaedColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _isDefault,
                    activeTrackColor: MosaedColors.brand,
                    onChanged: (v) => setState(() => _isDefault = v),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              MosaedPrimaryButton(
                text: 'mosaedAddAccountAction'.tr(),
                isLoading: _saving,
                onPressed: _saving ? null : _submit,
              ),
              SizedBox(height: 8.h),
              Center(
                child: TextButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
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
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.keyboardType,
  });

  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: getMediumStyle(
            fontSize: 13.sp,
            color: MosaedColors.textPrimary,
          ),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: getRegularStyle(
            fontSize: 14.sp,
            color: MosaedColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: getRegularStyle(
              fontSize: 13.sp,
              color: MosaedColors.textHint,
            ),
            prefixIcon: Icon(icon, color: MosaedColors.textHint, size: 20.sp),
            filled: true,
            fillColor: MosaedColors.surfaceWhite,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: const BorderSide(color: MosaedColors.fieldBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: const BorderSide(color: MosaedColors.fieldBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: const BorderSide(color: MosaedColors.brand),
            ),
          ),
        ),
      ],
    );
  }
}
