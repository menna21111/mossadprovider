import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/assets_manager.dart';
import '../../../../core/constants/mosaed_colors.dart';
import '../../../../core/constants/styles_manager.dart';

class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.enabled,
    required this.sending,
    required this.recording,
    required this.recordDuration,
    required this.onSend,
    required this.onAttach,
    required this.onMicTap,
    required this.onCancelRecord,
    required this.onSendRecord,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool sending;
  final bool recording;
  final Duration recordDuration;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final VoidCallback onMicTap;
  final VoidCallback onCancelRecord;
  final VoidCallback onSendRecord;

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: MosaedColors.surfaceWhite,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 8.h),
          child: recording ? _recordingRow() : _composeRow(),
        ),
      ),
    );
  }

  Widget _composeRow() {
    return Row(
      children: [
        Expanded(
          child: _pill(
            child: Row(
              children: [
                _attachButton(),
                Expanded(
                  child: TextField(
                    controller: controller,
                    enabled: enabled && !sending,
                    textAlign: TextAlign.start,
                    style: getRegularStyle(
                      fontSize: 14.sp,
                      color: MosaedColors.textPrimary,
                    ),
                    decoration: _fieldDecoration(
                      hint: 'mosaedWriteMessage'.tr(),
                    ),
                    onSubmitted: (_) => onSend(),
                  ),
                ),
                _micButton(),
              ],
            ),
          ),
        ),
        SizedBox(width: 10.w),
        _sendButton(
          onTap: enabled && !sending ? onSend : null,
        ),
      ],
    );
  }

  Widget _recordingRow() {
    return Row(
      children: [
        Expanded(
          child: _pill(
            color: const Color(0xFFFFF1F1),
            child: Row(
              children: [
                IconButton(
                  onPressed: onCancelRecord,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.close_rounded,
                    color: MosaedColors.danger,
                    size: 22.sp,
                  ),
                ),
                Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: const BoxDecoration(
                    color: MosaedColors.danger,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  'mosaedRecording'.tr(),
                  style: getMediumStyle(
                    fontSize: 13.sp,
                    color: MosaedColors.danger,
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: EdgeInsetsDirectional.only(end: 14.w),
                  child: Text(
                    _formatDuration(recordDuration),
                    style: getBoldStyle(
                      fontSize: 13.sp,
                      color: MosaedColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 10.w),
        _sendButton(onTap: sending ? null : onSendRecord),
      ],
    );
  }

  Widget _pill({required Widget child, Color? color}) {
    return Container(
      height: 52.h,
      decoration: BoxDecoration(
        color: color ?? MosaedColors.surfaceWhite,
        borderRadius: BorderRadius.circular(26.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  InputDecoration _fieldDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: getRegularStyle(
        fontSize: 14.sp,
        color: MosaedColors.textHint,
      ),
      isDense: true,
      filled: false,
      fillColor: Colors.transparent,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 14.h),
    );
  }

  Widget _attachButton() {
    return Padding(
      padding: EdgeInsetsDirectional.only(start: 8.w),
      child: Material(
        color: const Color(0xFFF1F1F1),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled && !sending ? onAttach : null,
          child: SizedBox(
            width: 34.w,
            height: 34.w,
            child: Center(
              child: SvgPicture.asset(
                ImageAssets.chatDocument,
                width: 18.w,
                height: 18.w,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _micButton() {
    return IconButton(
      onPressed: enabled && !sending ? onMicTap : null,
      visualDensity: VisualDensity.compact,
      icon: SvgPicture.asset(
        ImageAssets.chatMic,
        width: 22.w,
        height: 22.w,
      ),
    );
  }

  Widget _sendButton({required VoidCallback? onTap}) {
    return Material(
      color: MosaedColors.brand,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 48.w,
          height: 48.w,
          child: Center(
            child: SvgPicture.asset(
              ImageAssets.chatSend,
              width: 20.w,
              height: 20.w,
            ),
          ),
        ),
      ),
    );
  }
}
