import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  final Connectivity connectivity;
  final InternetConnection _internetConnection;

  NetworkInfoImpl(this.connectivity, {InternetConnection? internetConnection})
    : _internetConnection = internetConnection ?? InternetConnection();

  @override
  Future<bool> get isConnected async {
    final results = await connectivity.checkConnectivity();
    if (results.contains(ConnectivityResult.none)) {
      return false;
    }

    // A network is reported but may have no real internet access (e.g.
    // captive portals). Verify with an actual reachability probe.
    return _internetConnection.hasInternetAccess;
  }
}
