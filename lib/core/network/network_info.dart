import 'package:internet_connection_checker/internet_connection_checker.dart';

import '../../app/di.dart';



abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  final InternetConnectionChecker _connectionChecker =
      instance<InternetConnectionChecker>();

  @override
  Future<bool> get isConnected => _connectionChecker.hasConnection;
}
