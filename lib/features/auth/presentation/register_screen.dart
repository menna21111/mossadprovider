import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/functions.dart';
import '../../../core/constants/mosaed_colors.dart';
import '../../../core/constants/styles_manager.dart';
import '../../../core/widgets/mosaed_dropdown.dart';
import '../../custom_service/data/custom_service_repository.dart';
import '../../custom_service/data/models/custom_service_models.dart';
import 'cubit/auth_cubit.dart';
import 'otp_bottom_sheet.dart';
import 'widgets/auth_header.dart';
import 'widgets/auth_rich_link.dart';
import 'widgets/mosaed_buttons.dart';
import 'widgets/terms_agree_tile.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _commercialRegController = TextEditingController();
  final _imagePicker = ImagePicker();

  List<Specialization> _specializations = [];
  String? _selectedSpecializationId;
  File? _contractImage;
  bool _loadingSpecs = true;
  bool _agreedToTerms = false;
  bool _otpSheetOpen = false;

  bool get _canSubmit =>
      _agreedToTerms &&
      _nameController.text.trim().isNotEmpty &&
      mosaedPhoneDigitCount(_phoneController.text) >= 9 &&
      _emailController.text.trim().isNotEmpty &&
      (_selectedSpecializationId?.isNotEmpty ?? false) &&
      _nationalIdController.text.trim().isNotEmpty &&
      _commercialRegController.text.trim().isNotEmpty &&
      _contractImage != null;

  @override
  void initState() {
    super.initState();
    _loadSpecializations();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _nationalIdController.dispose();
    _commercialRegController.dispose();
    super.dispose();
  }

  Future<void> _loadSpecializations() async {
    try {
      final specs =
          await context.read<CustomServiceRepository>().getSpecializations();
      if (!mounted) return;
      setState(() {
        _specializations = specs;
        _loadingSpecs = false;
        if (specs.isNotEmpty) {
          _selectedSpecializationId = specs.first.id;
        }
      });
    } catch (_) {
      if (mounted) setState(() => _loadingSpecs = false);
    }
  }

  String _normalizePhone(String value) {
    var phone = mosaedToAsciiDigits(value).trim().replaceAll(' ', '');
    if (phone.startsWith('+966')) phone = phone.substring(4);
    if (phone.startsWith('966')) phone = phone.substring(3);
    if (phone.startsWith('0')) phone = phone.substring(1);
    return '0$phone';
  }

  Future<void> _pickContractImage() async {
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
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 2000,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() => _contractImage = File(picked.path));
      }
    } catch (_) {
      if (!mounted) return;
      AppFunctions.showsToast(
        'mosaedImagePickError'.tr(),
        MosaedColors.danger,
        context,
      );
    }
  }

  void _register() {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreedToTerms) {
      AppFunctions.showsToast(
        'mosaedAcceptTermsRequired'.tr(),
        MosaedColors.danger,
        context,
      );
      return;
    }

    if (_selectedSpecializationId == null ||
        _selectedSpecializationId!.isEmpty) {
      AppFunctions.showsToast(
        'mosaedSelectSpecialization'.tr(),
        MosaedColors.danger,
        context,
      );
      return;
    }

    if (_contractImage == null) {
      AppFunctions.showsToast(
        'mosaedContractImageRequired'.tr(),
        MosaedColors.danger,
        context,
      );
      return;
    }

    context.read<AuthCubit>().registerProvider(
          name: _nameController.text.trim(),
          phoneNumber: _normalizePhone(_phoneController.text),
          email: _emailController.text.trim(),
          specializationId: _selectedSpecializationId!,
          nationalId: _nationalIdController.text.trim(),
          commercialRegistration: _commercialRegController.text.trim(),
          contractImage: _contractImage!,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is OtpSent) {
          final otpCode = state.otpCode?.trim();
          if (otpCode != null && otpCode.isNotEmpty) {
            AppFunctions.showsToast(
              'mosaedOtpCodeToast'.tr(args: [otpCode]),
              MosaedColors.success,
              context,
            );
          } else {
            AppFunctions.showsToast(
              'mosaedRegisterVerifyPhone'.tr(),
              MosaedColors.success,
              context,
            );
          }
          if (!_otpSheetOpen) {
            _otpSheetOpen = true;
            OtpBottomSheet.show(
              context,
              phoneNumber: state.phoneNumber,
            ).whenComplete(() {
              if (mounted) _otpSheetOpen = false;
            });
          }
          context.read<AuthCubit>().reset();
        } else if (state is AuthFailure) {
          AppFunctions.showsToast(state.message, MosaedColors.danger, context);
          context.read<AuthCubit>().reset();
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          backgroundColor: MosaedColors.surfaceWhite,
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: 20.h),
                          AuthHeader(
                            title: 'mosaedRegisterTitle'.tr(),
                            subtitle: 'mosaedProviderRegisterSubtitle'.tr(),
                            logoWidth: 142,
                            logoHeight: 195,
                          ),
                          SizedBox(height: 28.h),
                          MosaedInputField(
                            label: 'mosaedYourName'.tr(),
                            controller: _nameController,
                            hint: 'mosaedFullNameHint'.tr(),
                            onChanged: (_) => setState(() {}),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'nameRequired'.tr()
                                    : null,
                          ),
                          SizedBox(height: 16.h),
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              'mosaedPhoneLabel'.tr(),
                              style: getMediumStyle(
                                fontSize: 14.sp,
                                color: MosaedColors.textPrimary,
                              ),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          MosaedPhoneField(
                            controller: _phoneController,
                            onChanged: (_) => setState(() {}),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'phoneRequired'.tr();
                              }
                              if (mosaedPhoneDigitCount(value) < 9) {
                                return 'mosaedPhoneInvalid'.tr();
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16.h),
                          MosaedInputField(
                            label: 'email'.tr(),
                            controller: _emailController,
                            hint: 'mosaedEmailHint'.tr(),
                            keyboardType: TextInputType.emailAddress,
                            onChanged: (_) => setState(() {}),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'mosaedEmailRequired'.tr();
                              }
                              if (!value.contains('@')) {
                                return 'mosaedEmailInvalid'.tr();
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16.h),
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              'mosaedSpecialization'.tr(),
                              style: getMediumStyle(
                                fontSize: 14.sp,
                                color: MosaedColors.textPrimary,
                              ),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          MosaedDropdown<String>(
                            title: '',
                            hint: 'mosaedSelectSpecialization'.tr(),
                            icon: Icons.keyboard_arrow_down_rounded,
                            selectedValue: _selectedSpecializationId,
                            isLoading: _loadingSpecs,
                            items: _specializations
                                .map(
                                  (spec) => MosaedDropdownItem(
                                    value: spec.id,
                                    label: spec.name,
                                  ),
                                )
                                .toList(),
                            onSelected: (value) => setState(
                              () => _selectedSpecializationId = value,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          MosaedInputField(
                            label: 'mosaedNationalId'.tr(),
                            controller: _nationalIdController,
                            hint: 'mosaedNationalIdHint'.tr(),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            validator: (value) =>
                                value == null || value.isEmpty
                                    ? 'mosaedNationalIdRequired'.tr()
                                    : null,
                          ),
                          SizedBox(height: 16.h),
                          MosaedInputField(
                            label: 'mosaedCommercialRegistration'.tr(),
                            controller: _commercialRegController,
                            hint: 'mosaedCommercialRegistrationHint'.tr(),
                            onChanged: (_) => setState(() {}),
                            validator: (value) =>
                                value == null || value.isEmpty
                                    ? 'fieldRequired'.tr()
                                    : null,
                          ),
                          SizedBox(height: 16.h),
                          _ContractImagePicker(
                            image: _contractImage,
                            onPick: _pickContractImage,
                            onRemove: () =>
                                setState(() => _contractImage = null),
                          ),
                          SizedBox(height: 20.h),
                          TermsAgreeTile(
                            agreed: _agreedToTerms,
                            onChanged: (value) =>
                                setState(() => _agreedToTerms = value),
                          ),
                          SizedBox(height: 20.h),
                          AuthRichLink(
                            prefix: 'alreadyHaveAccount'.tr(),
                            action: 'login'.tr(),
                            onTap: () => Navigator.pop(context),
                          ),
                          SizedBox(height: 24.h),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      color: MosaedColors.surfaceWhite,
                      border: Border(
                        top: BorderSide(
                          color: MosaedColors.fieldBorder,
                          width: 1,
                        ),
                      ),
                    ),
                    padding: EdgeInsets.fromLTRB(16.w, 8.h, 24.w, 16.h),
                    child: MosaedPrimaryButton(
                      text: 'mosaedCreateAccount'.tr(),
                      isLoading: isLoading,
                      enabled: _canSubmit,
                      fontSize: 15,
                      onPressed: _canSubmit ? _register : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ContractImagePicker extends StatelessWidget {
  const _ContractImagePicker({
    required this.image,
    required this.onPick,
    required this.onRemove,
  });

  final File? image;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            'mosaedContractImage'.tr(),
            style: getMediumStyle(
              fontSize: 14.sp,
              color: MosaedColors.textPrimary,
            ),
          ),
        ),
        SizedBox(height: 8.h),
        InkWell(
          onTap: onPick,
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            width: double.infinity,
            height: image != null ? 160.h : 100.h,
            decoration: BoxDecoration(
              color: MosaedColors.surfaceWhite,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: image != null
                    ? MosaedColors.brand
                    : MosaedColors.fieldBorder,
                width: image != null ? 1.5 : 1,
              ),
            ),
            child: image != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(11.r),
                        child: Image.file(image!, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 8.h,
                        left: 8.w,
                        child: IconButton.filled(
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black54,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: onRemove,
                          icon: const Icon(Icons.close_rounded, size: 18),
                        ),
                      ),
                      Positioned(
                        bottom: 8.h,
                        right: 8.w,
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.black54,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: onPick,
                          icon: const Icon(Icons.edit_rounded, size: 16),
                          label: Text('mosaedChangePhoto'.tr()),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.upload_file_rounded,
                        size: 32.sp,
                        color: MosaedColors.brand,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'mosaedUploadContract'.tr(),
                        style: getMediumStyle(
                          fontSize: 15.sp,
                          color: MosaedColors.brand,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'mosaedContractImageHint'.tr(),
                        style: getRegularStyle(
                          fontSize: 13.sp,
                          color: MosaedColors.textHint,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
