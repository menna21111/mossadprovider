import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/functions.dart';
import '../../../core/constants/assets_manager.dart';
import '../../../core/constants/mosaed_colors.dart';
import '../../../core/constants/styles_manager.dart';
import '../../../core/network/failure.dart';
import '../../auth/presentation/widgets/mosaed_buttons.dart';
import '../data/completion_form_model.dart';
import '../data/provider_orders_repository.dart';

enum CompletionUploadPhase { before, after, finish }

class CompletionFormUploadScreen extends StatefulWidget {
  const CompletionFormUploadScreen({
    super.key,
    required this.bookingId,
    this.serviceTitle,
    this.kind = CompletionFormKind.booking,
    this.startOnFinishStep = false,
    this.forcePhase,
  });

  final String bookingId;
  final String? serviceTitle;
  final CompletionFormKind kind;
  final bool startOnFinishStep;
  final CompletionUploadPhase? forcePhase;

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
  File? _pickedFile;

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

  CompletionUploadPhase get _phase {
    if (widget.forcePhase != null) return widget.forcePhase!;
    if (widget.startOnFinishStep) return CompletionUploadPhase.finish;
    final form = _completionForm;
    if (form == null || form.workNotStarted) {
      return CompletionUploadPhase.before;
    }
    if (form.needsAfterUpload) return CompletionUploadPhase.after;
    if (form.readyToFinish) return CompletionUploadPhase.finish;
    return CompletionUploadPhase.before;
  }

  bool get _isFinished => _completionForm?.isFinished == true;

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

      final notes = completionForm.notes?.trim() ?? '';
      setState(() {
        _completionForm = completionForm;
        if (notes.isNotEmpty) _notesController.text = notes;
        _pickedFile = null;
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

  Future<void> _showImageSourceSheet() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: MosaedColors.surfaceWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) => const _AddPhotoSheet(),
    );
    if (source == null || !mounted) return;

    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 2000,
        imageQuality: 85,
      );
      if (picked == null) return;
      setState(() => _pickedFile = File(picked.path));
    } catch (_) {
      if (!mounted) return;
      AppFunctions.showsToast(
        'mosaedPreviousWorkUploadError'.tr(),
        MosaedColors.danger,
        context,
      );
    }
  }

  Future<void> _submit() async {
    if (_isFinished) return;
    final phase = _phase;

    if (phase == CompletionUploadPhase.before) {
      await _uploadBefore();
      return;
    }
    if (phase == CompletionUploadPhase.after) {
      await _uploadAfterThenMaybeFinish();
      return;
    }
    await _finishJob();
  }

  Future<void> _uploadBefore() async {
    if (_pickedFile == null) {
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
            beforeImageFile: _pickedFile!,
            kind: widget.kind,
          );

      if (!mounted) return;
      setState(() => _uploading = false);
      AppFunctions.showsToast(
        'mosaedServiceStarted'.tr(),
        MosaedColors.success,
        context,
      );
      Navigator.pop(context, true);
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

  Future<void> _uploadAfterThenMaybeFinish() async {
    if (_pickedFile == null) {
      AppFunctions.showsToast(
        'mosaedAfterImageRequired'.tr(),
        MosaedColors.danger,
        context,
      );
      return;
    }

    setState(() => _uploading = true);
    try {
      final repo = context.read<ProviderOrdersRepository>();
      await repo.updatePreviousWorkAfter(
        bookingId: _bookingId,
        afterImageFile: _pickedFile!,
        kind: widget.kind,
      );

      final notes = _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : 'تم تنفيذ الخدمة بالكامل وتسليمها للعميل';

      final updated = await repo.submitCompletionForm(
        bookingId: _bookingId,
        notes: notes,
        isFinished: true,
        kind: widget.kind,
      );

      if (!mounted) return;
      setState(() {
        _completionForm = updated;
        _uploading = false;
      });
      AppFunctions.showsToast(
        'mosaedJobFinishedSuccessfully'.tr(),
        MosaedColors.success,
        context,
      );
      Navigator.pop(context, true);
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

  bool get _busy => _uploading || _submitting;

  bool get _canSubmit {
    if (_busy || _isFinished) return false;
    final phase = _phase;
    if (phase == CompletionUploadPhase.finish) return true;
    return _pickedFile != null;
  }

  String get _title {
    final phase = _phase;
    if (phase == CompletionUploadPhase.finish) {
      return 'mosaedFinishJob'.tr();
    }
    return 'mosaedWorkPhotosUpload'.tr();
  }

  String get _heading {
    switch (_phase) {
      case CompletionUploadPhase.before:
        return 'mosaedAddBeforeProblemPhotos'.tr();
      case CompletionUploadPhase.after:
        return 'mosaedAddAfterWorkPhotos'.tr();
      case CompletionUploadPhase.finish:
        return 'mosaedFinishJob'.tr();
    }
  }

  String get _ctaLabel {
    if (_busy) {
      return _phase == CompletionUploadPhase.finish
          ? 'mosaedFinishingJob'.tr()
          : 'mosaedUploadingImage'.tr();
    }
    if (_phase == CompletionUploadPhase.after) {
      return 'mosaedDeliverWork'.tr();
    }
    if (_phase == CompletionUploadPhase.finish) {
      return 'mosaedFinishJob'.tr();
    }
    return 'mosaedUploadThePhoto'.tr();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MosaedColors.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: MosaedColors.surfaceWhite,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_forward_ios_rounded,
            color: MosaedColors.textPrimary,
            size: 18.sp,
          ),
        ),
        title: Text(
          _title,
          style: getBoldStyle(fontSize: 16.sp, color: MosaedColors.textPrimary),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: const Divider(height: 1, color: MosaedColors.fieldBorder),
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: _loading || _error != null || _isFinished
          ? null
          : Container(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
              decoration: const BoxDecoration(
                color: MosaedColors.surfaceWhite,
                border: Border(
                  top: BorderSide(color: MosaedColors.fieldBorder),
                ),
              ),
              child: SafeArea(
                top: false,
                child: MosaedPrimaryButton(
                  text: _ctaLabel,
                  isLoading: _busy,
                  onPressed: _canSubmit ? _submit : null,
                ),
              ),
            ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: MosaedColors.brand),
      );
    }

    if (_error != null || _completionForm == null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _error ?? 'mosaedCompletionFormLoadError'.tr(),
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

    if (_isFinished) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Text(
            'mosaedJobAlreadyFinished'.tr(),
            textAlign: TextAlign.center,
            style: getMediumStyle(
              fontSize: 14.sp,
              color: MosaedColors.success,
            ),
          ),
        ),
      );
    }

    final phase = _phase;
    final showPicker = phase == CompletionUploadPhase.before ||
        phase == CompletionUploadPhase.after;
    final showNotes = _pickedFile != null ||
        phase == CompletionUploadPhase.finish ||
        phase == CompletionUploadPhase.after;

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 24.h),
      children: [
        Text(
          _heading,
          style: getBoldStyle(fontSize: 18.sp, color: MosaedColors.textPrimary),
        ),
        if (showPicker) ...[
          SizedBox(height: 16.h),
          _PhotoDropZone(
            file: _pickedFile,
            sectionLabel: phase == CompletionUploadPhase.before
                ? 'mosaedProblemPhotos'.tr()
                : 'mosaedWorkImages'.tr(),
            onTap: _busy ? null : _showImageSourceSheet,
            onClear: _busy
                ? null
                : () => setState(() => _pickedFile = null),
          ),
        ],
        if (showNotes) ...[
          SizedBox(height: 20.h),
          Text(
            'mosaedIHaveANote'.tr(),
            style: getBoldStyle(
              fontSize: 15.sp,
              color: MosaedColors.textPrimary,
            ),
          ),
          SizedBox(height: 10.h),
          TextField(
            controller: _notesController,
            maxLines: 5,
            enabled: !_busy,
            decoration: InputDecoration(
              hintText: 'mosaedWriteYourNotes'.tr(),
              hintStyle: getRegularStyle(
                fontSize: 13.sp,
                color: MosaedColors.textHint,
              ),
              filled: true,
              fillColor: MosaedColors.surfaceWhite,
              contentPadding: EdgeInsets.all(14.w),
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
      ],
    );
  }
}

class _PhotoDropZone extends StatelessWidget {
  const _PhotoDropZone({
    required this.file,
    required this.sectionLabel,
    this.onTap,
    this.onClear,
  });

  final File? file;
  final String sectionLabel;
  final VoidCallback? onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final hasFile = file != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sectionLabel,
          style: getMediumStyle(
            fontSize: 13.sp,
            color: MosaedColors.textSecondary,
          ),
        ),
        SizedBox(height: 8.h),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: hasFile ? null : onTap,
            borderRadius: BorderRadius.circular(16.r),
            child: CustomPaint(
              painter: hasFile
                  ? null
                  : _DashedRRectPainter(
                      color: MosaedColors.brand.withValues(alpha: 0.55),
                      radius: 16.r,
                    ),
              child: Container(
                width: double.infinity,
                height: 200.h,
                decoration: BoxDecoration(
                  color: hasFile
                      ? MosaedColors.surfaceWhite
                      : MosaedColors.brand.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16.r),
                  border: hasFile
                      ? Border.all(color: MosaedColors.fieldBorder)
                      : null,
                ),
                clipBehavior: Clip.antiAlias,
                child: hasFile
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(file!, fit: BoxFit.cover),
                          if (onClear != null)
                            Positioned(
                              top: 10.h,
                              right: 10.w,
                              child: InkWell(
                                onTap: onClear,
                                borderRadius: BorderRadius.circular(20.r),
                                child: Container(
                                  width: 28.w,
                                  height: 28.w,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.55),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close_rounded,
                                    color: Colors.white,
                                    size: 16.sp,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            ImageAssets.image02,
                            width: 40.w,
                            height: 40.w,
                            colorFilter: const ColorFilter.mode(
                              MosaedColors.brand,
                              BlendMode.srcIn,
                            ),
                          ),
                          SizedBox(height: 10.h),
                          Text(
                            'mosaedAddPhoto'.tr(),
                            style: getBoldStyle(
                              fontSize: 14.sp,
                              color: MosaedColors.brand,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            child: Text(
                              'mosaedSupportedImageFormats'.tr(),
                              textAlign: TextAlign.center,
                              style: getRegularStyle(
                                fontSize: 11.sp,
                                color: MosaedColors.textHint,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

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
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

class _AddPhotoSheet extends StatelessWidget {
  const _AddPhotoSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 20.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: MosaedColors.fieldBorder,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'mosaedAddPhotoTitle'.tr(),
              style: getBoldStyle(
                fontSize: 16.sp,
                color: MosaedColors.textPrimary,
              ),
            ),
            SizedBox(height: 16.h),
            _SheetOption(
              svgAsset: ImageAssets.cameraIcon,
              label: 'mosaedTakePhoto'.tr(),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            SizedBox(height: 10.h),
            _SheetOption(
              svgAsset: ImageAssets.image02,
              label: 'mosaedPickFromGallery'.tr(),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  const _SheetOption({
    required this.svgAsset,
    required this.label,
    required this.onTap,
  });

  final String svgAsset;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: MosaedColors.surfaceWhite,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: MosaedColors.brand.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                svgAsset,
                width: 22.w,
                height: 22.w,
                colorFilter: const ColorFilter.mode(
                  MosaedColors.brand,
                  BlendMode.srcIn,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  label,
                  style: getMediumStyle(
                    fontSize: 14.sp,
                    color: MosaedColors.textPrimary,
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
