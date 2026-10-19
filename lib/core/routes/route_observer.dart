import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

/// Suit la route affichée (utilisé par le mini-lecteur). Ne touche pas à l'audio.
class AppRouteObserver extends NavigatorObserver {
  static final RxString currentRoute = ''.obs;

  void _update(Route<dynamic>? route) {
    // Les dialogues et feuilles n'ont pas de nom : on garde la page en dessous.
    final name = route?.settings.name;
    if (route is PageRoute && name != null) {
      currentRoute.value = name;
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => _update(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _update(previousRoute);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) => _update(newRoute);
}
