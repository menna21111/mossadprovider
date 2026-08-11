import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

import '../core/data_sources/local_data_source.dart';
import '../core/data_sources/remote_data_source.dart';
import '../core/network/network_info.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/custom_service/data/custom_service_repository.dart';
import '../features/services/data/services_repository.dart';

final instance = GetIt.instance;

Future<void> initAppModule() async {
  instance.allowReassignment = true;

  instance.registerLazySingleton<InternetConnectionChecker>(
    () => InternetConnectionChecker(),
  );
  instance.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());
  instance.registerLazySingleton<RemoteDataSource>(() => RemoteDataSourceImpl());
  instance.registerLazySingleton<LocalDataSource>(() => LocalDataSourceImpl());
  instance.registerLazySingleton<AuthRepository>(() => AuthRepository());
  instance.registerLazySingleton<ServicesRepository>(() => ServicesRepository());
  instance.registerLazySingleton<CustomServiceRepository>(
    () => CustomServiceRepository(),
  );
  // instance.registerLazySingleton<CloudinaryUploadService>(
  //   () => CloudinaryUploadService(),
  // );
}
