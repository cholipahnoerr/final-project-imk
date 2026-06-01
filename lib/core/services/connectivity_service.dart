import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// true = online, false = offline
final connectivityProvider = StreamProvider<bool>((ref) {
  return Connectivity().onConnectivityChanged.map(
    (results) => results.isNotEmpty && !results.contains(ConnectivityResult.none),
  );
});

// Synchronous check — use for one-shot reads (not reactive)
Future<bool> isConnected() async {
  final results = await Connectivity().checkConnectivity();
  return results.isNotEmpty && !results.contains(ConnectivityResult.none);
}
