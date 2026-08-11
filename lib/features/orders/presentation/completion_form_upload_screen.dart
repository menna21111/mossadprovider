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
import '../../auth/presentation/widgets/mosaed_buttons.dart';
import '../data/completion_form_model.dart';
import '../data/provider_orders_repository.dart';

class CompletionFormUploadScreen extends StatefulWidget {
  const CompletionFormUploadScreen({
    super.key,
    required this.bookingId,
    this.serviceTitle,
    this.kind = CompletionFormKind.booking,
    this.startOnFinishStep = false,
  });

  final String bookingId;
  final String? serviceTitle;
  final CompletionFormKind kind;
  final bool startOnFinishStep;

  @override
  State<CompletionFormUploadScreen> createState() =>
      _CompletionFormUploadScreenState();
}

class _CompletionFormUploadScreenState extends State<CompletionFormUploadScreen> {
  final _notesController = TextEditingController();
  final _picker = ImagePicker();

  CompletionForm? _completionForm;
  bool _loading = true;
  bool _submitting = false;
  bool _uploading = false;
  String? _error;
  File? _beforeFile;
  File? _afterFile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String get _bookingId => widget.bookingId;

  bool get _isFinished => _completionForm?.isFinished == true;

  bool get _workNotStarted => _completionForm?.workNotStarted ?? true;

  bool get _needsAfterUpdate => _completionForm?.needsAfterUpload ?? false;

  bool get _hasBothImages => _completionForm?.hasRealAfterImage ?? false;

  bool get _readyToFinish => _completionForm?.readyToFinish ?? false;

  String? get _displayBefore => _completionForm?.beforeImage;

  String? get _displayAfter => _completionForm?.afterImage;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final completionForm = await context
          .read<ProviderOrdersRepository>()
          .getCompletionFormDetail(_bookingId, kind: widget.kind);

      if (!mounted) return;

      final notes = completionForm.notes?.trim().isNotEmpty == true
          ? completionForm.notes!
          : 'تم تنفيذ الخدمة بالكامل وتسليمها للعميل';

      setState(() {
        _completionForm = completionForm;
        _notesController.text = notes;
        _beforeFile = null;
        _afterFile = null;
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
        _error = 'mosaedCompletionFormLoadError'.tr();
        _loading = false;
      });
    }
  }

  Future<void> _showImageSourceSheet({required bool isBefore}) async {
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
      if (picked == null) return;
      setState(() {
        if (isBefore) {
          _beforeFile = File(picked.path);
        } else {
          _afterFile = File(picked.path);
        }
      });
    } catch (_) {
      if (!mounted) return;
      AppFunctions.showsToast(
        'mosaedPreviousWorkUploadError'.tr(),
        MosaedColors.danger,
        context,
      );
    }
  }

  Future<void> _uploadBeforeImage() async {
    if (_isFinished || !_workNotStarted) return;
    if (_beforeFile == null) {
      AppFunctions.showsToast(
        'mosaedBeforeImageRequired'.tr(),
        MosaedColors.danger,
        context,
      );
      return;
    }

    setState(() => _uploading = true);
    try {
      await context.read<ProviderOrdersRepository>().uploadPreviousWork(
            bookingId: _bookingId,
            beforeImageFile: _beforeFile!,
            kind: widget.kind,
          );

      final completionForm = await context
          .read<ProviderOrdersRepository>()
          .getCompletionFormDetail(_bookingId, kind: widget.kind);

      if (!mounted) return;
      setState(() {
        _completionForm = completionForm;
        _beforeFile = null;
        _uploading = false;
      });

      AppFunctions.showsToast(
        'mosaedServiceStarted'.tr(),
        MosaedColors.success,
        context,
      );
    } on ServerFailure catch (e) {
      if (!mounted) return;
      setState(() => _uploading = false);
      AppFunctions.showsToast(e.errMessage, MosaedColors.danger, context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _uploading = false);
      AppFunctions.showsToast(
        'mosaedPreviousWorkUploadError'.tr(),
        MosaedColors.danger,
        context,
      );
    }
  }

  Future<void> _uploadAfterImage() async {
    if (_isFinished || _workNotStarted) return;
    if (_afterFile == null) {
      AppFunctions.showsToast(
        'mosaedAfterImageRequired'.tr(),
        MosaedColors.danger,
        context,
      );
      return;
    }

    setState(() => _uploading = true);
    try {
      await context.read<ProviderOrdersRepository>().updatePreviousWorkAfter(
            bookingId: _bookingId,
            afterImageFile: _afterFile!,
            kind: widget.kind,
          );

      final completionForm = await context
          .read<ProviderOrdersRepository>()
          .getCompletionFormDetail(_bookingId, kind: widget.kind);

      if (!mounted) return;
      setState(() {
        _completionForm = completionForm;
        _afterFile = null;
        _uploading = false;
      });

      AppFunctions.showsToast(
        'mosaedPreviousWorkUploaded'.tr(),
        MosaedColors.success,
        context,
      );
    } on ServerFailure catch (e) {
      if (!mounted) return;
      setState(() => _uploading = false);
      AppFunctions.showsToast(e.errMessage, MosaedColors.danger, context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _uploading = false);
      AppFunctions.showsToast(
        'mosaedPreviousWorkUploadError'.tr(),
        MosaedColors.danger,
        context,
      );
    }
  }

  Future<void> _finishJob() async {
    if (_isFinished) return;
    if (!_readyToFinish) {
      AppFunctions.showsToast(
        'mosaedUploadBeforeAfterFirst'.tr(),
        MosaedColors.danger,
        context,
      );
      return;
    }

    final notes = _notesController.text.trim().isNotEmpty
        ? _notesController.text.trim()
        : 'تم تنفيذ الخدمة بالكامل وتسليمها للعميل';

    setState(() => _submitting = true);
    try {
      final updated =
          await context.read<ProviderOrdersRepository>().submitCompletionForm(
                bookingId: _bookingId,
                notes: notes,
                isFinished: true,
                kind: widget.kind,
              );
      if (!mounted) return;
      setState(() {
        _completionForm = updated;
        _submitting = false;
      });
      AppFunctions.showsToast(
        'mosaedJobFinishedSuccessfully'.tr(),
        MosaedColors.success,
        context,
      );
      Navigator.pop(context, true);
    } on ServerFailure catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      AppFunctions.showsToast(e.errMessage, MosaedColors.danger, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MosaedColors.background,
      appBar: AppBar(
        backgroundColor: MosaedColors.surfaceWhite,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_forward_rounded,
            color: MosaedColors.primary,
            size: 22.sp,
          ),
        ),
        title: Text(
          widget.startOnFinishStep
              ? 'mosaedFinishJob'.tr()
              : 'mosaedWorkPhotosUpload'.tr(),
          style: getBoldStyle(fontSize: 18.sp, color: MosaedColors.textPrimary),
        ),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: Icon(Icons.refresh_rounded, color: MosaedColors.primary),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: MosaedColors.primaryContainer),
      );
    }

    if (_error != null || _completionForm == null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_rounded, size: 48.sp, color: MosaedColors.textHint),
              SizedBox(height: 12.h),
              Text(
                _error ?? 'mosaedCompletionFormLoadError'.tr(),
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

    final finished = _isFinished;

    return RefreshIndicator(
      onRefresh: _load,
      color: MosaedColors.primary,
      child: ListView(
        padding: EdgeInsets.all(20.w),
        children: [
          if (widget.serviceTitle?.trim().isNotEmpty == true) ...[
            Text(
              widget.serviceTitle!,
              style: getBoldStyle(fontSize: 16.sp, color: MosaedColors.textPrimary),
            ),
            SizedBox(height: 4.h),
            Text(
              '#${_bookingId.length > 8 ? _bookingId.substring(0, 8) : _bookingId}',
              style: getRegularStyle(
                fontSize: 12.sp,
                color: MosaedColors.textSecondary,
              ),
            ),
            SizedBox(height: 16.h),
          ],

          if (_workNotStarted && !finished) ...[
            Text(
              'mosaedUploadBeforeStep'.tr(),
              style: getBoldStyle(fontSize: 16.sp, color: MosaedColors.textPrimary),
            ),
            SizedBox(height: 8.h),
            Text(
              'mosaedUploadBeforeStepHint'.tr(),
              style: getRegularStyle(
                fontSize: 13.sp,
                color: MosaedColors.textSecondary,
              ),
            ),
            SizedBox(height: 16.h),
            InkWell(
              onTap: _uploading ? null : () => _showImageSourceSheet(isBefore: true),
              borderRadius: BorderRadius.circular(16.r),
              child: _imageCard(
                label: 'mosaedBefore'.tr(),
                networkUrl: null,
                localFile: _beforeFile,
              ),
            ),
            SizedBox(height: 16.h),
            MosaedPrimaryButton(
              text: _uploading
                  ? 'mosaedUploadingImage'.tr()
                  : 'mosaedUploadBeforeImage'.tr(),
              isLoading: _uploading,
              onPressed: _uploading ? null : _uploadBeforeImage,
            ),
          ],

          if (_needsAfterUpdate) ...[
            Text(
              'mosaedUploadAfterStep'.tr(),
              style: getBoldStyle(fontSize: 16.sp, color: MosaedColors.textPrimary),
            ),
            SizedBox(height: 8.h),
            Text(
              'mosaedUploadAfterStepHint'.tr(),
              style: getRegularStyle(
                fontSize: 13.sp,
                color: MosaedColors.textSecondary,
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: _imageCard(
                    label: 'mosaedBefore'.tr(),
                    networkUrl: _displayBefore,
                    localFile: null,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: InkWell(
                    onTap: _uploading ? null : () => _showImageSourceSheet(isBefore: false),
                    borderRadius: BorderRadius.circular(16.r),
                    child: _imageCard(
                      label: 'mosaedAfter'.tr(),
                      networkUrl: null,
                      localFile: _afterFile,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            MosaedPrimaryButton(
              text: _uploading
                  ? 'mosaedUploadingImage'.tr()
                  : 'mosaedUploadAfterImage'.tr(),
              isLoading: _uploading,
              onPressed: _uploading ? null : _uploadAfterImage,
            ),
          ],

          if (_hasBothImages || finished) ...[
            Text(
              'mosaedWorkImages'.tr(),
              style: getBoldStyle(fontSize: 16.sp, color: MosaedColors.textPrimary),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: _imageCard(
                    label: 'mosaedBefore'.tr(),
                    networkUrl: _displayBefore,
                    localFile: null,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _imageCard(
                    label: 'mosaedAfter'.tr(),
                    networkUrl: _displayAfter,
                    localFile: null,
                  ),
                ),
              ],
            ),
          ],

          if (!finished && _readyToFinish) ...[
            SizedBox(height: 20.h),
            Text(
              'mosaedCompletionNotes'.tr(),
              style: getBoldStyle(fontSize: 15.sp, color: MosaedColors.textPrimary),
            ),
            SizedBox(height: 8.h),
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'mosaedCompletionNotesHint'.tr(),
                filled: true,
                fillColor: MosaedColors.inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: 16.h),
            MosaedPrimaryButton(
              text: _submitting
                  ? 'mosaedFinishingJob'.tr()
                  : 'mosaedFinishJob'.tr(),
              isLoading: _submitting,
              onPressed: (_submitting || _uploading) ? null : _finishJob,
            ),
          ],

          if (finished) ...[
            SizedBox(height: 16.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: MosaedColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: MosaedColors.success.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: MosaedColors.success),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      'mosaedJobAlreadyFinished'.tr(),
                      style: getMediumStyle(
                        fontSize: 14.sp,
                        color: MosaedColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  Widget _imageCard({
    required String label,
    required String? networkUrl,
    required File? localFile,
  }) {
    return Container(
      height: 180.h,
      decoration: BoxDecoration(
        color: MosaedColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: MosaedColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (localFile != null)
            Image.file(localFile, fit: BoxFit.cover)
          else if (networkUrl != null && networkUrl.isNotEmpty)
            Image.network(
              networkUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _imagePlaceholder(label),
            )
          else
            _imagePlaceholder(label),
          Positioned(
            left: 8.w,
            right: 8.w,
            bottom: 8.h,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: getMediumStyle(fontSize: 12.sp, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder(String label) {
    return Container(
      color: MosaedColors.primaryFixed,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo_outlined, color: MosaedColors.primary, size: 28.sp),
          SizedBox(height: 8.h),
          Text(
            label,
            style: getMediumStyle(fontSize: 12.sp, color: MosaedColors.primary),
          ),
        ],
      ),
    );
  }
}
