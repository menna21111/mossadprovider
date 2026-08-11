import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui' as ui;

import 'package:flutter_styled_toast/flutter_styled_toast.dart';

import 'package:http/http.dart' as http;

import 'package:intl/intl.dart';
import 'package:page_transition/page_transition.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/color_manager.dart';
import 'navigator_key.dart';

class AppFunctions {
  static String reverseString(String originalString) {
    List<String> charList = originalString.split('');
    List<String> reversedList = charList.reversed.toList();
    String reversedString = reversedList.join();

    debugPrint('Original String: $originalString');
    debugPrint('Reversed String: $reversedString');

    return reversedString;
  }

  static Future<void> showLoadingDialog(
    BuildContext context, {
    String? message,
    bool barrierDismissible = false,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black.withOpacity(0.25),
      builder: (context) {
        return WillPopScope(
          onWillPop: () async => barrierDismissible,
          child: Dialog(
            elevation: 0,
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            insetPadding: EdgeInsets.zero, // يمنع تكبير المساحة
            child: Padding(
              padding: const EdgeInsets.all(20.0), // padding صغير
              child: SizedBox(
                height: 40.h,
                width: 40.w,
                child: Center(
                  child: const CircularProgressIndicator(strokeWidth: 3),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// اقفلي الدايالوج (لو مفتوح)
  static void hideLoadingDialog(BuildContext context) {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  static Future<int?> fetchCityIdFromAPI(double lat, double long) async {
    try {
      final response = await http.post(
        Uri.parse(
          'https://AIzaSyBcqYSQUB84VBJOwAqgyMmHlfGfW3Yl68A/location/city',
        ),
        body: {'latitude': lat.toString(), 'longitude': long.toString()},
      );
      log('result');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['city_id'];
      }
    } catch (e) {
      debugPrint('Error fetching city ID: $e');
    }
    return null;
  }

  static void showsToast(
    String text,
    Color color,
    BuildContext context, {
    int seconds = 5,
  }) {
    final toastContext = resolveToastContext(context);
    if (toastContext == null) return;

    showToast(
      text,
      context: toastContext,
      backgroundColor: color,
      animation: StyledToastAnimation.slideFromTopFade,
      reverseAnimation: StyledToastAnimation.slideToTopFade,
      position: StyledToastPosition.top,
      animDuration: const Duration(seconds: 2),
      duration: Duration(seconds: seconds),
      curve: Curves.elasticOut,
      reverseCurve: Curves.easeInOutCirc,
    );
  }

  /// [navigatorKey.currentContext] is the Navigator itself (parent of Overlay).
  /// Styled toast needs a context under Overlay — use a child entry when needed.
  static BuildContext? resolveToastContext(BuildContext context) {
    if (Overlay.maybeOf(context) != null) return context;

    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return null;

    BuildContext? childContext;
    overlay.context.visitChildElements((element) {
      childContext ??= element;
    });
    return childContext;
  }

  static String prettyTime(String timeString) {
    DateTime time = DateTime.parse("$timeString");

    String formattedTime = DateFormat('h:mm a').format(time);

    return formattedTime;
  }

  static String prettyDate(String dateString) {
    DateTime date = DateTime.parse(dateString);

    String formattedTime = DateFormat('MM-dd-yyyy').format(date);

    return formattedTime;
  }

  static String convertTo12Hour(String time24) {
    try {
      DateTime parsedTime = DateFormat("HH:mm:ss").parseLoose(time24);
      return DateFormat("h:mm a", 'en_US').format(parsedTime);
    } catch (e) {
      try {
        DateTime parsedTime = DateFormat("HH:mm").parseLoose(time24);
        return DateFormat("h:mm a", 'en_US').format(parsedTime);
      } catch (e) {
        return time24;
      }
    }
  }

  static bool pickerActive = false;

  static Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
  }

  static Future<void> navigateTo(
    BuildContext context,
    Widget screen,
    PageTransitionType type,
  ) async {
    await (Platform.isIOS
        ? Navigator.of(
          context,
        ).push(CupertinoPageRoute(builder: (context) => screen))
        : Navigator.of(context).push(
          PageTransition(
            child: screen,
            type: type,
            alignment: Alignment.center,
            duration: const Duration(milliseconds: 300),
            reverseDuration: const Duration(milliseconds: 200),
          ),
        ));
  }

  static Future<void> navigateWithCubit<T extends Cubit<Object>>({
    required BuildContext context,
    required Widget screen,
    required PageTransitionType type,
    required T cubit,
  }) async {
    final Widget wrappedScreen = BlocProvider<T>.value(
      value: cubit,
      child: screen,
    );

    await (Platform.isIOS
        ? Navigator.of(
          context,
        ).push(CupertinoPageRoute(builder: (_) => wrappedScreen))
        : Navigator.of(context).push(
          PageTransition(
            child: wrappedScreen,
            type: type,
            alignment: Alignment.center,
            duration: const Duration(milliseconds: 300),
            reverseDuration: const Duration(milliseconds: 200),
          ),
        ));
  }

  static Future<void> navigateWithMultiBloc({
    required BuildContext context,
    required Widget screen,
    required List<BlocProvider> blocProviders,
    required PageTransitionType type,
  }) async {
    final Widget wrappedScreen = MultiBlocProvider(
      providers: blocProviders,
      child: screen,
    );

    await (Platform.isIOS
        ? Navigator.of(
          context,
        ).push(CupertinoPageRoute(builder: (_) => wrappedScreen))
        : Navigator.of(context).push(
          PageTransition(
            child: wrappedScreen,
            type: type,
            alignment: Alignment.center,
            duration: const Duration(milliseconds: 300),
            reverseDuration: const Duration(milliseconds: 200),
          ),
        ));
  }

  static void navigateToAndReplacement(BuildContext context, Widget screen) {
    Platform.isIOS
        ? Navigator.of(
          context,
        ).pushReplacement(CupertinoPageRoute(builder: (context) => screen))
        : Navigator.of(context).pushReplacement(
          PageTransition(
            child: screen,
            type: PageTransitionType.rightToLeft,
            alignment: Alignment.center,
            duration: const Duration(milliseconds: 500),
            reverseDuration: const Duration(milliseconds: 500),
          ),
        );
  }

  static void navigateToAndFinish(BuildContext context, Widget screen) {
    Platform.isIOS
        ? Navigator.of(context).pushAndRemoveUntil(
          CupertinoPageRoute(builder: (context) => screen),
          (route) => false,
        )
        : Navigator.of(context).pushAndRemoveUntil(
          PageTransition(
            child: screen,
            type: PageTransitionType.fade,
            alignment: Alignment.center,
            duration: const Duration(milliseconds: 500),
            reverseDuration: const Duration(milliseconds: 500),
          ),
          (route) => false,
        );
  }

  static void popThenNavigateTo(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Navigator.of(context).push(
      PageTransition(
        child: screen,
        type: PageTransitionType.rightToLeft,
        alignment: Alignment.center,
        duration: const Duration(milliseconds: 500),
        reverseDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  static String convertToArabic(int number) {
    List<String> arabicDigits = [
      '٠',
      '١',
      '٢',
      '٣',
      '٤',
      '٥',
      '٦',
      '٧',
      '٨',
      '٩',
    ];

    String result = '';
    String numberStr = number.toString();

    for (int i = 0; i < numberStr.length; i++) {
      int digit = int.parse(numberStr[i]);
      result += arabicDigits[digit];
    }

    return result;
  }

  static void loadingshowdialgo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: ColorManager.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: SizedBox(
            width: 40.w,
            height: 40.h,
            child: Center(
              child: CircularProgressIndicator(color: ColorManager.primary),
            ),
          ),
        );
      },
    );
  }

  static String optimizeVideoUrl(String url) {
    // Handle relative paths
    if (!url.startsWith('http')) {
      final base =
          AppConstants.baseUrl.endsWith('/')
              ? AppConstants.baseUrl.substring(
                0,
                AppConstants.baseUrl.length - 1,
              )
              : AppConstants.baseUrl;
      final path = url.startsWith('/') ? url : '/$url';
      url = '$base$path';
    }

    // Handle Cloudinary optimization
    if (url.contains('cloudinary.com') && url.contains('/video/upload/')) {
      if (!url.contains('q_auto')) {
        url = url.replaceFirst(
          '/video/upload/',
          '/video/upload/q_auto,f_auto,w_1080/',
        );
      }
    }

    // Ensure extension for compatibility if no query params and no proper extension
    if (!url.contains('?') &&
        !url.toLowerCase().endsWith('.mp4') &&
        !url.toLowerCase().endsWith('.m3u8') &&
        !url.toLowerCase().endsWith('.mov') &&
        !url.toLowerCase().endsWith('.avi')) {
      return url;
    }
    return url;
  }

  static String optimizeAudioUrl(String url) {
    if (url.isEmpty) return url;

    // Handle relative paths
    if (!url.startsWith('http')) {
      final base =
          AppConstants.baseUrl.endsWith('/')
              ? AppConstants.baseUrl.substring(
                0,
                AppConstants.baseUrl.length - 1,
              )
              : AppConstants.baseUrl;
      final path = url.startsWith('/') ? url : '/$url';
      url = '$base$path';
    }

    // Ensure extension for compatibility if no query params and no proper extension
    if (!url.contains('?') &&
        !url.toLowerCase().endsWith('.mp3') &&
        !url.toLowerCase().endsWith('.wav') &&
        !url.toLowerCase().endsWith('.m4a') &&
        !url.toLowerCase().endsWith('.aac')) {
      url += '.mp3';
    }

    return url;
  }
}

// void logout(BuildContext context) {
//   showDialog(
//     context: context,
//     builder: (context) {
//       return AlertDialog(
//         backgroundColor: ColorManager.white,
//         content: Text(
//           context.tr("are you sure you want logout?"),
//           style: getMediumStyle(fontSize: 12.sp, color: ColorManager.black),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.of(context).pop(false);
//             },
//             child: Text(
//               context.tr("No"),
//               style: getMediumStyle(fontSize: 12.sp, color: ColorManager.black),
//             ),
//           ),
//           TextButton(
//             onPressed: () {
//               AppFunctions.navigateToAndFinish(context, LoginScrean());
//               CacheHelper().removeData(key: 'user_id');
//               CacheHelper().removeData(key: 'name');
//               CacheHelper().removeData(key: 'access_token');
//               CacheHelper().removeData(key: 'image');
//             },
//             child: Text(
//               context.tr("yes"),
//               style: getMediumStyle(fontSize: 12.sp, color: ColorManager.red),
//             ),
//           ),
//         ],
//       );
//     },
//   );
// }
