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
import 'otp_screen.dart';
import 'widgets/mosaed_buttons.dart';
import 'widgets/mosaed_logo.dart';

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
        if (specs.isNotEmpty) _selectedSpecializationId = specs.first.id;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingSpecs = false);
    }
  }

  String _normalizePhone(String value) {
    var phone = value.trim().replaceAll(' ', '');
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
      if (picked != null) setState(() => _contractImage = File(picked.path));
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

    if (_selectedSpecializationId == null || _selectedSpecializationId!.isEmpty) {
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
          AppFunctions.showsToast(
            'mosaedRegisterVerifyPhone'.tr(),
            MosaedColors.success,
            context,
          );
          AppFunctions.navigateToAndFinish(
            context,
            OtpScreen(phoneNumber: state.phoneNumber),
          );
          context.read<AuthCubit>().reset();
        } else if (state is AuthFailure) {
          AppFunctions.showsToast(state.message, MosaedColors.danger, context);
          context.read<AuthCubit>().reset();
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          backgroundColor: MosaedColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: MosaedColors.textPrimary,
                size: 20.sp,
              ),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const MosaedLogo(width: 180),
                    SizedBox(height: 16.h),
                    Text(
                      'mosaedProviderRegisterTitle'.tr(),
                      style: getBoldStyle(
                        fontSize: 22.sp,
                        color: MosaedColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'mosaedProviderRegisterSubtitle'.tr(),
                      textAlign: TextAlign.center,
                      style: getRegularStyle(
                        fontSize: 13.sp,
                        color: MosaedColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: MosaedColors.surface,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: MosaedColors.border),
                      ),
                      child: Column(
                        children: [
                          MosaedInputField(
                            label: 'fullName'.tr(),
                            controller: _nameController,
                            hint: 'mosaedFullNameHint'.tr(),
                            icon: Icons.person_outline_rounded,
                            validator: (v) =>
                                v == null || v.isEmpty ? 'nameRequired'.tr() : null,
                          ),
                          SizedBox(height: 14.h),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'phoneNumber'.tr(),
                                style: getMediumStyle(
                                  fontSize: 13.sp,
                                  color: MosaedColors.textSecondary,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              MosaedPhoneField(
                                controller: _phoneController,
                                validator: (v) => v == null || v.isEmpty
                                    ? 'phoneRequired'.tr()
                                    : null,
                              ),
                            ],
                          ),
                          SizedBox(height: 14.h),
                          MosaedInputField(
                            label: 'email'.tr(),
                            controller: _emailController,
                            hint: 'mosaedEmailHint'.tr(),
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'mosaedEmailRequired'.tr();
                              }
                              if (!v.contains('@')) {
                                return 'mosaedEmailInvalid'.tr();
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 14.h),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'mosaedSpecialization'.tr(),
                                style: getMediumStyle(
                                  fontSize: 13.sp,
                                  color: MosaedColors.textSecondary,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              MosaedDropdown<String>(
                                title: '',
                                hint: 'mosaedSelectSpecialization'.tr(),
                                icon: Icons.handyman_outlined,
                                selectedValue: _selectedSpecializationId,
                                isLoading: _loadingSpecs,
                                items: _specializations
                                    .map(
                                      (s) => MosaedDropdownItem(
                                        value: s.id,
                                        label: s.name,
                                      ),
                                    )
                                    .toList(),
                                onSelected: (v) =>
                                    setState(() => _selectedSpecializationId = v),
                              ),
                            ],
                          ),
                          SizedBox(height: 14.h),
                          MosaedInputField(
                            label: 'mosaedNationalId'.tr(),
                            controller: _nationalIdController,
                            hint: 'mosaedNationalIdHint'.tr(),
                            icon: Icons.badge_outlined,
                            keyboardType: TextInputType.number,
                            validator: (v) => v == null || v.isEmpty
                                ? 'mosaedNationalIdRequired'.tr()
                                : null,
                          ),
                          SizedBox(height: 14.h),
                          MosaedInputField(
                            label: 'mosaedCommercialRegistration'.tr(),
                            controller: _commercialRegController,
                            hint: 'mosaedCommercialRegistrationHint'.tr(),
                            icon: Icons.business_outlined,
                            validator: (v) => v == null || v.isEmpty
                                ? 'fieldRequired'.tr()
                                : null,
                          ),
                          SizedBox(height: 14.h),
                          _ContractImagePicker(
                            image: _contractImage,
                            onPick: _pickContractImage,
                            onRemove: () => setState(() => _contractImage = null),
                          ),
                          SizedBox(height: 20.h),
                          MosaedPrimaryButton(
                            text: 'mosaedCreateAccount'.tr(),
                            isLoading: isLoading,
                            icon: Icons.person_add_alt_1_rounded,
                            onPressed: _register,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.h),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: RichText(
                        text: TextSpan(
                          style: getRegularStyle(
                            fontSize: 14.sp,
                            color: MosaedColors.textSecondary,
                          ),
                          children: [
                            TextSpan(text: '${'alreadyHaveAccount'.tr()} '),
                            TextSpan(
                              text: 'login'.tr(),
                              style: getBoldStyle(
                                fontSize: 14.sp,
                                color: MosaedColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'mosaedRegisterTerms'.tr(),
                      textAlign: TextAlign.center,
                      style: getRegularStyle(
                        fontSize: 11.sp,
                        color: MosaedColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 24.h),
                  ],
                ),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'mosaedContractImage'.tr(),
          style: getMediumStyle(
            fontSize: 13.sp,
            color: MosaedColors.textSecondary,
          ),
        ),
        SizedBox(height: 8.h),
        InkWell(
          onTap: onPick,
          borderRadius: BorderRadius.circular(14.r),
          child: Container(
            width: double.infinity,
            height: image != null ? 160.h : 100.h,
            decoration: BoxDecoration(
              color: MosaedColors.inputFill,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: image != null ? MosaedColors.primary : MosaedColors.border,
                width: image != null ? 1.5 : 1,
              ),
            ),
            child: image != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(13.r),
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
                        color: MosaedColors.primary,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'mosaedUploadContract'.tr(),
                        style: getMediumStyle(
                          fontSize: 13.sp,
                          color: MosaedColors.primary,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'mosaedContractImageHint'.tr(),
                        style: getRegularStyle(
                          fontSize: 11.sp,
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
