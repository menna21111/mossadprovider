import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app/app.dart';
import 'app/bloc_observer.dart';
import 'app/di.dart';
import 'app/theme_cubit.dart/theme_cubit.dart';
import 'core/caching/cach_helper.dart';
import 'core/network/dio_helper.dart';
import 'core/services/notification/notification_service.dart';
import 'core/services/notification/push_notification_service.dart';
import 'firebase_options.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/custom_service/data/custom_service_repository.dart';
import 'features/chat/data/chat_repository.dart';
import 'features/notifications/data/notifications_repository.dart';
import 'features/notifications/presentation/cubit/notification_cubit.dart';
import 'features/orders/data/provider_orders_repository.dart';
import 'features/services/data/services_repository.dart';
import 'features/payments/data/provider_dues_repository.dart';
import 'features/payments/data/provider_wallet_repository.dart';
import 'features/payments/presentation/cubit/provider_due_lock_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  Bloc.observer = MyBlocObserver();
  await DioHelper.init();
  await CacheHelper().init();
  await initAppModule();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await NotificationService.initialize();
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    await NotificationService.handleInitialMessage(initialMessage);
  } catch (e) {
    debugPrint('Firebase/Push init skipped: $e');
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('ar'),
      child: MultiRepositoryProvider(
        providers: [
          RepositoryProvider(create: (_) => AuthRepository()),
          RepositoryProvider(create: (_) => ServicesRepository()),
          RepositoryProvider(create: (_) => CustomServiceRepository()),
          RepositoryProvider(create: (_) => ProviderOrdersRepository()),
          RepositoryProvider(create: (_) => ProviderWalletRepository()),
          RepositoryProvider(create: (_) => ProviderDuesRepository()),
          RepositoryProvider(create: (_) => NotificationsRepository()),
          RepositoryProvider(create: (_) => ChatRepository()),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => ThemeCubit()..setLightTheme()),
            BlocProvider(
              create: (context) => AuthCubit(context.read<AuthRepository>()),
            ),
            BlocProvider(
              create: (context) => ProviderDueLockCubit(
                context.read<ProviderDuesRepository>(),
              ),
            ),
            BlocProvider(
              create: (context) {
                final cubit =
                    NotificationCubit(context.read<NotificationsRepository>());
                final dueLockCubit = context.read<ProviderDueLockCubit>();
                cubit.onDuePaymentRequired = dueLockCubit.handleDuePaymentRequired;
                cubit.onAccountUnblocked = dueLockCubit.handleAccountUnblocked;
                PushNotificationService.bindNotificationsRepository(
                  context.read<NotificationsRepository>(),
                );
                PushNotificationService.onForegroundPushData = (data) {
                  cubit.handlePushPayload(data);
                };
                return cubit;
              },
            ),
          ],
          child: const MyApp(),
        ),
      ), 
    ),
  );
}
