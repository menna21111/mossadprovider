import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/functions.dart';
import '../../../core/constants/mosaed_colors.dart';
import '../../../core/constants/styles_manager.dart';
import '../../../core/network/failure.dart';
import '../../../core/widgets/mosaed_confirm_dialog.dart';
import '../../auth/data/models/customer_profile.dart';
import '../../auth/presentation/cubit/auth_cubit.dart';
import '../../auth/presentation/widgets/mosaed_buttons.dart';
import '../../splash/presentation/splash_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.profile});

  final CustomerProfile profile;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _picker = ImagePicker();

  File? _photo;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameController.text = p.name;
    _phoneController.text = _localPhone(p.phoneNumber);
    _nameController.addListener(_onChanged);
    _phoneController.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _nameController.removeListener(_onChanged);
    _phoneController.removeListener(_onChanged);
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String _localPhone(String phone) {
    var digits = mosaedToAsciiDigits(phone).replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('966')) digits = digits.substring(3);
    if (digits.startsWith('0')) digits = digits.substring(1);
    return digits;
  }

  String _normalizePhone(String value) {
    var phone = mosaedToAsciiDigits(value).trim().replaceAll(' ', '');
    if (phone.startsWith('+966')) phone = phone.substring(4);
    if (phone.startsWith('966')) phone = phone.substring(3);
    if (phone.startsWith('0')) phone = phone.substring(1);
    return '0$phone';
  }

  bool get _canSubmit {
    final nameOk = _nameController.text.trim().isNotEmpty;
    final phoneDigits =
        mosaedToAsciiDigits(_phoneController.text).replaceAll(RegExp(r'\D'), '');
    final phoneOk = phoneDigits.length >= 9;
    return !_saving && nameOk && phoneOk;
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: MosaedColors.surfaceWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text('mosaedPickFromGallery'.tr()),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text('mosaedTakePhoto'.tr()),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 2000,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() => _photo = File(picked.path));
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_canSubmit) return;
    setState(() => _saving = true);
    try {
      await context.read<AuthCubit>().updateProfile(
            name: _nameController.text.trim(),
            phoneNumber: _normalizePhone(_phoneController.text),
            photo: _photo,
          );
      if (!mounted) return;
      AppFunctions.showsToast(
        'mosaedProfileUpdated'.tr(),
        MosaedColors.success,
        context,
      );
      Navigator.pop(context, true);
    } on ServerFailure catch (e) {
      if (mounted) {
        AppFunctions.showsToast(e.errMessage, MosaedColors.danger, context);
      }
    } catch (_) {
      if (mounted) {
        AppFunctions.showsToast(
          'mosaedCustomServiceError'.tr(),
          MosaedColors.danger,
          context,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showMosaedConfirmDialog(
      context,
      title: 'mosaedDeleteAccountTitle'.tr(),
      message: 'mosaedDeleteAccountBody'.tr(),
      confirmText: 'mosaedDelete'.tr(),
    );
    if (!confirmed || !mounted) return;
    await context.read<AuthCubit>().deleteAccount();
  }

  ImageProvider? get _avatar {
    if (_photo != null) return FileImage(_photo!);
    final url = widget.profile.avatar?.trim();
    if (url != null && url.isNotEmpty) return NetworkImage(url);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final infoRows = <_InfoRowData>[
      if ((p.email ?? '').trim().isNotEmpty)
        _InfoRowData(label: 'email'.tr(), value: p.email!.trim()),
      if ((p.specializationName ?? '').trim().isNotEmpty)
        _InfoRowData(
          label: 'mosaedSpecialization'.tr(),
          value: p.specializationName!.trim(),
        ),
      if ((p.nationalId ?? '').trim().isNotEmpty)
        _InfoRowData(
          label: 'mosaedNationalId'.tr(),
          value: p.nationalId!.trim(),
        ),
      if ((p.commercialRegistration ?? '').trim().isNotEmpty)
        _InfoRowData(
          label: 'mosaedCommercialRegistration'.tr(),
          value: p.commercialRegistration!.trim(),
        ),
    ];

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthLoggedOut) {
          AppFunctions.navigateToAndFinish(context, const SplashScrean());
        } else if (state is AuthFailure) {
          AppFunctions.showsToast(state.message, MosaedColors.danger, context);
        }
      },
      child: Scaffold(
        backgroundColor: MosaedColors.surfaceWhite,
        appBar: AppBar(
          backgroundColor: MosaedColors.surfaceWhite,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'mosaedEditProfile'.tr(),
            style: getBoldStyle(
              fontSize: 16.sp,
              color: MosaedColors.textPrimary,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(1.h),
            child: const Divider(height: 1, color: MosaedColors.fieldBorder),
          ),
        ),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 16.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: GestureDetector(
                          onTap: _pickPhoto,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              CircleAvatar(
                                radius: 44.r,
                                backgroundColor: MosaedColors.otpFill,
                                backgroundImage: _avatar,
                                child: _avatar == null
                                    ? Icon(
                                        Icons.person_rounded,
                                        color: MosaedColors.brand,
                                        size: 40.sp,
                                      )
                                    : null,
                              ),
                              PositionedDirectional(
                                start: 0,
                                bottom: 0,
                                child: Container(
                                  width: 26.w,
                                  height: 26.w,
                                  decoration: BoxDecoration(
                                    color: MosaedColors.brand,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.camera_alt_rounded,
                                    color: Colors.white,
                                    size: 14.sp,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'mosaedChooseClearPhoto'.tr(),
                        textAlign: TextAlign.center,
                        style: getRegularStyle(
                          fontSize: 12.sp,
                          color: MosaedColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 24.h),
                      MosaedInputField(
                        label: 'mosaedYourName'.tr(),
                        controller: _nameController,
                        hint: 'mosaedFullNameHint'.tr(),
                        onChanged: (_) => setState(() {}),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'nameRequired'.tr()
                            : null,
                      ),
                      SizedBox(height: 16.h),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          'mosaedPhoneLabel'.tr(),
                          style: getMediumStyle(
                            fontSize: 12.sp,
                            color: MosaedColors.textPrimary,
                          ),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      MosaedPhoneField(
                        controller: _phoneController,
                        onChanged: (_) => setState(() {}),
                        validator: (v) {
                          final digits = mosaedToAsciiDigits(v ?? '')
                              .replaceAll(RegExp(r'\D'), '');
                          if (digits.length < 9) {
                            return 'mosaedPhoneInvalid'.tr();
                          }
                          return null;
                        },
                      ),
                      if (infoRows.isNotEmpty) ...[
                        SizedBox(height: 28.h),
                        Text(
                          'mosaedAccountInfo'.tr(),
                          style: getBoldStyle(
                            fontSize: 14.sp,
                            color: MosaedColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: MosaedColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(color: MosaedColors.fieldBorder),
                          ),
                          child: Column(
                            children: [
                              for (var i = 0; i < infoRows.length; i++) ...[
                                _ReadOnlyInfoRow(data: infoRows[i]),
                                if (i < infoRows.length - 1)
                                  const Divider(
                                    height: 1,
                                    color: MosaedColors.fieldBorder,
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 16.h),
                decoration: const BoxDecoration(
                  color: MosaedColors.surfaceWhite,
                  border: Border(
                    top: BorderSide(color: MosaedColors.fieldBorder),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      MosaedPrimaryButton(
                        text: 'mosaedSaveEdits'.tr(),
                        isLoading: _saving,
                        enabled: _canSubmit,
                        onPressed: _canSubmit ? _save : null,
                      ),
                      SizedBox(height: 10.h),
                      MosaedOutlineButton(
                        text: 'mosaedDeleteAccount'.tr(),
                        color: MosaedColors.danger,
                        onPressed: _deleteAccount,
                      ),
                    ],
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

class _InfoRowData {
  const _InfoRowData({required this.label, required this.value});

  final String label;
  final String value;
}

class _ReadOnlyInfoRow extends StatelessWidget {
  const _ReadOnlyInfoRow({required this.data});

  final _InfoRowData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              data.label,
              style: getRegularStyle(
                fontSize: 12.sp,
                color: MosaedColors.textSecondary,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            flex: 3,
            child: Text(
              data.value,
              textAlign: TextAlign.end,
              style: getMediumStyle(
                fontSize: 13.sp,
                color: MosaedColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
