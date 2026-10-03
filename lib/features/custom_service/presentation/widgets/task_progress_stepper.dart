import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/assets_manager.dart';
import '../../../../core/constants/mosaed_colors.dart';
import '../../../../core/constants/styles_manager.dart';
import '../../../orders/data/completion_form_model.dart';

/// Provider task progress after an offer is accepted.
enum ProviderTaskStage { arrival, execution, handover, payment }

class ProviderTaskProgress {
  const ProviderTaskProgress({this.completion});

  final CompletionForm? completion;

  static const stepCount = 4;

  /// وصل (`started_at`) — يقدر يرفع الصور.
  bool get hasArrived => completion?.hasArrived == true;

  bool get workStarted => hasArrived;

  bool get hasBeforePhoto => completion?.hasBeforeImage == true;

  bool get workFinished => completion?.isFinished == true;

  /// -1 = none done yet (just accepted / not arrived).
  int get completedStepIndex {
    final c = completion;
    if (c == null || !c.hasArrived) return -1;
    if (c.isFinished && c.paymentConfirmed) return 3;
    if (c.isFinished) return 2;
    if (c.hasRealAfterImage) return 1;
    return 0;
  }

  /// Active step to highlight, or -1 when all done.
  int get activeStepIndex {
    final c = completion;
    if (c == null || !c.hasArrived) return 0; // الوصول
    if (c.isFinished && c.paymentConfirmed) return -1;
    if (c.isFinished) return 3; // الدفع
    if (c.hasRealAfterImage) return 2; // التسليم
    return 1; // التنفيذ
  }
}

class TaskProgressStepper extends StatelessWidget {
  const TaskProgressStepper({
    super.key,
    required this.progress,
    this.forceInactive = false,
  });

  final ProviderTaskProgress progress;

  /// When true (just accepted), all steps stay gray until the provider is ready.
  final bool forceInactive;

  static const _steps = [
    'mosaedStepArrival',
    'mosaedStepExecution',
    'mosaedStepHandover',
    'mosaedStepPayment',
  ];

  static const _doneColor = Color(0xFF14B8A6);

  @override
  Widget build(BuildContext context) {
    final completed = forceInactive ? -1 : progress.completedStepIndex;
    final active = forceInactive ? -1 : progress.activeStepIndex;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: MosaedColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: MosaedColors.fieldBorder),
        boxShadow: MosaedColors.softShadow,
      ),
      child: Row(
        children: List.generate(_steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            final stepBefore = index ~/ 2;
            final lineDone = !forceInactive && stepBefore < active;
            final lineActive =
                !forceInactive && (stepBefore == active - 1 || stepBefore <= completed);
            return Expanded(
              child: Container(
                height: 2.h,
                margin: EdgeInsets.only(bottom: 18.h),
                color: lineDone
                    ? _doneColor
                    : lineActive
                        ? MosaedColors.brand
                        : const Color(0xFFE5E7EB),
              ),
            );
          }

          final step = index ~/ 2;
          final isDone = step <= completed;
          final isActive = step == active;
          return _StepNode(
            label: _steps[step].tr(),
            isDone: isDone,
            isActive: isActive,
          );
        }),
      ),
    );
  }
}

class _StepNode extends StatelessWidget {
  const _StepNode({
    required this.label,
    required this.isDone,
    required this.isActive,
  });

  final String label;
  final bool isDone;
  final bool isActive;

  static const _doneColor = Color(0xFF14B8A6);

  @override
  Widget build(BuildContext context) {
    final Color ring;
    final Color fill;
    final Color labelColor;
    final Color iconColor;

    if (isDone) {
      ring = _doneColor;
      fill = _doneColor;
      labelColor = _doneColor;
      iconColor = Colors.white;
    } else if (isActive) {
      ring = MosaedColors.brand;
      fill = MosaedColors.brand;
      labelColor = MosaedColors.brand;
      iconColor = Colors.white;
    } else {
      ring = const Color(0xFFD1D5DB);
      fill = const Color(0xFFF3F4F6);
      labelColor = MosaedColors.textHint;
      iconColor = const Color(0xFF9CA3AF);
    }

    return SizedBox(
      width: 56.w,
      child: Column(
        children: [
          Container(
            width: 26.w,
            height: 26.w,
            decoration: BoxDecoration(
              color: fill,
              shape: BoxShape.circle,
              border: Border.all(color: ring, width: 1.5),
            ),
            alignment: Alignment.center,
            child: SvgPicture.asset(
              ImageAssets.checkmarkCircle03,
              width: 14.w,
              height: 14.w,
              colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: getMediumStyle(fontSize: 11.sp, color: labelColor),
          ),
        ],
      ),
    );
  }
}
