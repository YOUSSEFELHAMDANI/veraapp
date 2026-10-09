import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/vera_api_service.dart';

class CurrentUserNotifier extends StateNotifier<VeraUser?> {
  CurrentUserNotifier() : super(null);

  void setUser(VeraUser? user) => state = user;
}

final currentUserProvider =
    StateNotifierProvider<CurrentUserNotifier, VeraUser?>(
  (ref) => CurrentUserNotifier(),
);
