import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';


import '../../app/theme_cubit.dart/theme_cubit.dart';
import '../constants/color_manager.dart';
import '../constants/styles_manager.dart';

class Buttons extends StatelessWidget {
  const Buttons({
    super.key,
    required this.buttoncolor,
    required this.buttonname,
    required this.onPressed,
    required this.buttonwidth,
    required this.textcolor,
  });
  final Color buttoncolor;
  final String buttonname;
  final VoidCallback onPressed;
  final double buttonwidth;
  final Color textcolor;
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themestate) {
        return GestureDetector(
          onTap: onPressed,
          child: Container(
            width: buttonwidth,
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  themestate.isDark
                      ? ColorManager.primaryDarkColor
                      : ColorManager.gold,
                  themestate.isDark
                      ? ColorManager.primaryDarkColor
                      : Color(0xFFFFA500),
                ],
              ),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Text(
              buttonname,
              style: getBoldStyle(fontSize: 14.sp, color: ColorManager.white),
            ),
          ),
        );
      },
    );
  }
}
