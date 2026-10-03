import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../app/functions.dart';
import '../app/navigator_key.dart';
import '../app/theme_cubit.dart/theme_cubit.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/payments/presentation/cubit/provider_due_lock_cubit.dart';

import '../features/payments/presentation/provider_due_lock_dialog.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _dueLockDialogOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final cubit = context.read<ProviderDueLockCubit>();
      cubit.fetchStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(440, 956),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, themeState) {
            return BlocListener<ProviderDueLockCubit, ProviderDueLockState>(
              listener: (context, dueState) async {
                if (dueState.isBlocked && !_dueLockDialogOpen) {
                  _dueLockDialogOpen = true;
                  final navContext = navigatorKey.currentContext;
                  if (navContext != null) {
                    await showModalBottomSheet<void>(
                      context: navContext,
                      useRootNavigator: true,
                      isScrollControlled: true,
                      isDismissible: false,
                      enableDrag: false,
                      backgroundColor: Colors.transparent,
                      builder: (_) => ProviderDueLockDialog(state: dueState),
                    );
                  }
                  _dueLockDialogOpen = false;
                }

                if (!dueState.isBlocked && _dueLockDialogOpen) {
                  final nav = navigatorKey.currentState;
                  if (nav?.canPop() == true) {
                    nav!.pop();
                  }
                  _dueLockDialogOpen = false;
                }
              },
              child: MaterialApp(
                navigatorKey: navigatorKey,
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
                locale: context.locale,
                debugShowCheckedModeBanner: false,
                theme: themeState.themeData,
                home: const SplashScrean(),
                routes: {
                  '/login': (_) => const LoginScrean(),
                  '/notifications': (_) => const NotificationsScreen(),
                },
                builder: (context, child) {
                  AppFunctions.toastHostContext = context;
                  return MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: const TextScaler.linear(1.0),
                    ),
                    child: child ?? const SizedBox.shrink(),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
