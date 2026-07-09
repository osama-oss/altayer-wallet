import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RouterRefreshNotifier extends ChangeNotifier {
  void notifyAuthChanged() => notifyListeners();
}

final routerRefreshProvider = Provider<RouterRefreshNotifier>(
  (ref) => RouterRefreshNotifier(),
);
