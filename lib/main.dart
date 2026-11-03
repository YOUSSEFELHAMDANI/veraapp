import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_links/app_links.dart';

import '../core/app_export.dart';
import '../core/app_localizations.dart';
import '../core/auth_session.dart';
import '../core/locale_provider.dart';
import '../core/theme_controller.dart';
import '../core/user_interest_tracker.dart';
import './routes/app_routes.dart';
import './services/vera_api_service.dart';

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();
const AndroidNotificationChannel _notificationChannel =
    AndroidNotificationChannel(
      'vera_default_notifications',
      'VÉRA Notifications',
      description: 'Order, account and service notifications from VÉRA',
      importance: Importance.high,
    );

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> _showForegroundNotification(RemoteMessage message) async {
  final notification = message.notification;
  if (notification == null) return;
  await _localNotifications.show(
    notification.hashCode,
    notification.title ?? 'VÉRA',
    notification.body ?? '',
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'vera_default_notifications',
        'VÉRA Notifications',
        channelDescription:
            'Order, account and service notifications from VÉRA',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    ),
    payload: message.data['route']?.toString(),
  );
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Surface every uncaught error instead of silently aborting startup and
  // leaving a blank/white native window (no first frame is ever rendered).
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('🔴 Uncaught Flutter error: ${details.exception}');
  };
  WidgetsBinding.instance.platformDispatcher.onError = (
    Object error,
    StackTrace stack,
  ) {
    debugPrint('🔴 Uncaught platform error: $error\n$stack');
    return true;
  };

  bool hasShownError = false;

  // 🚨 CRITICAL: Custom error handling - DO NOT REMOVE
  ErrorWidget.builder = (FlutterErrorDetails details) {
    debugPrint('🔴 Flutter build error: ${details.exception}');
    debugPrint('${details.stack ?? ''}');
    if (!hasShownError) {
      hasShownError = true;

      // Reset flag after 3 seconds to allow error widget on new screens
      Future.delayed(Duration(seconds: 5), () {
        hasShownError = false;
      });

      return CustomErrorWidget(errorDetails: details);
    }
    return SizedBox.shrink();
  };

  GoRouter.optionURLReflectsImperativeAPIs = true;

  // Global provider container: bound to AuthSession so a logout / token expiry
  // can purge every cached authenticated object (user, cart, ...).
  final container = ProviderContainer();
  AuthSession.instance.bind(container);

  // Start Firebase setup without waiting for platform channels or permission
  // dialogs. The splash screen must get a Flutter frame even if an iOS plugin
  // is slow or unavailable.
  final firebaseReady = _initializeFirebaseCore();
  runApp(UncontrolledProviderScope(container: container, child: const MyApp()));

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!kIsWeb) {
      unawaited(_lockPortraitOrientation());
      try {
        _setupDeepLinks();
      } catch (e, s) {
        debugPrint('🔴 Deep link setup failed: $e\n$s');
      }
    }
    unawaited(_initializeTheme());
    unawaited(_initializeUserInterests());
    unawaited(_initializeFirebaseMessaging(firebaseReady));
  });
}

Future<bool> _initializeFirebaseCore() async {
  try {
    await Firebase.initializeApp().timeout(const Duration(seconds: 12));
    return true;
  } catch (e, s) {
    debugPrint('🔴 Firebase.initializeApp failed: $e\n$s');
    return false;
  }
}

Future<void> _initializeFirebaseMessaging(Future<bool> firebaseReady) async {
  if (kIsWeb || !await firebaseReady) return;
  try {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    const initialization = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _localNotifications
        .initialize(initialization)
        .timeout(const Duration(seconds: 8));
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_notificationChannel);
    }
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);

    final messaging = FirebaseMessaging.instance;
    final settings = await messaging
        .requestPermission(alert: true, badge: true, sound: true)
        .timeout(const Duration(seconds: 12));
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      try {
        final token = await messaging.getToken().timeout(
          const Duration(seconds: 8),
        );
        if (token != null && token.isNotEmpty) {
          VeraApiService.instance.cacheFcmToken(token);
          unawaited(VeraApiService.instance.registerPushToken(token));
        }
      } catch (e, s) {
        debugPrint('🔴 FCM getToken failed: $e\n$s');
      }
    }
    messaging.onTokenRefresh.listen(
      (token) => unawaited(VeraApiService.instance.registerPushToken(token)),
    );
  } catch (e, s) {
    debugPrint('🔴 Messaging/notifications init failed: $e\n$s');
  }
}

Future<void> _initializeTheme() async {
  try {
    await ThemeController.instance.init().timeout(const Duration(seconds: 8));
  } catch (e, s) {
    debugPrint('🔴 ThemeController.init failed: $e\n$s');
  }
}

Future<void> _initializeUserInterests() async {
  try {
    await UserInterestTracker.instance.init().timeout(
      const Duration(seconds: 8),
    );
  } catch (e, s) {
    debugPrint('🔴 UserInterestTracker.init failed: $e\n$s');
  }
}

Future<void> _lockPortraitOrientation() async {
  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]).timeout(const Duration(seconds: 4));
  } catch (e) {
    debugPrint('🔴 Orientation lock failed: $e');
  }
}

void _setupDeepLinks() {
  final appLinks = AppLinks();
  appLinks.uriLinkStream.listen((uri) {
    _handleDeepLink(uri);
  });
  appLinks.getInitialLink().then((uri) {
    if (uri == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleDeepLink(uri);
    });
  });
}

void _handleDeepLink(Uri uri) {
  if (uri.scheme != 'veraapp') return;
  final path = uri.host;
  final q = uri.queryParameters;
  final orderId = q['orderId'];
  final planId = q['plan_id'];
  final provider = q['provider'] ?? '';
  switch (path) {
    case 'payment-success':
      AppRouter.appRouter.go(
        '/payment-result?kind=order&status=success&orderId=$orderId&provider=$provider',
      );
      break;
    case 'payment-cancelled':
      AppRouter.appRouter.go(
        '/payment-result?kind=order&status=cancelled&orderId=$orderId&provider=$provider',
      );
      break;
    case 'subscription-success':
      AppRouter.appRouter.go(
        '/payment-result?kind=subscription&status=success&planId=$planId&provider=$provider',
      );
      break;
    case 'subscription-cancelled':
      AppRouter.appRouter.go(
        '/payment-result?kind=subscription&status=cancelled&planId=$planId&provider=$provider',
      );
      break;
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final isRtl = const {'ar', 'ur'}.contains(locale.languageCode);

    return Sizer(
      builder: (context, orientation, screenType) {
        return ListenableBuilder(
          listenable: ThemeController.instance,
          builder: (context, _) {
            return MaterialApp.router(
              title: 'VÉRA',
              locale: locale,
              supportedLocales: [
                for (final code in AppLocalizations.supportedLanguageCodes)
                  Locale(code),
              ],
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              theme: isRtl ? AppTheme.arabicTheme : AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: ThemeController.instance.mode,
              // 🚨 CRITICAL: NEVER REMOVE OR MODIFY
              builder: (context, child) {
                return _AuthLifecycleObserver(
                  child: MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: TextScaler.linear(1.0)),
                    child: Directionality(
                      textDirection: isRtl
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      child: child!,
                    ),
                  ),
                );
              },
              // 🚨 END CRITICAL SECTION
              debugShowCheckedModeBanner: false,
              routerConfig: AppRouter.appRouter,
            );
          },
        );
      },
    );
  }
}

/// Re-validates the session whenever the app returns to the foreground (from
/// background / inactivity / lock screen) so an expired or revoked session is
/// detected immediately and the user is logged out.
class _AuthLifecycleObserver extends StatefulWidget {
  const _AuthLifecycleObserver({required this.child});

  final Widget child;

  @override
  State<_AuthLifecycleObserver> createState() => _AuthLifecycleObserverState();
}

class _AuthLifecycleObserverState extends State<_AuthLifecycleObserver>
    with WidgetsBindingObserver {
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
      AuthSession.instance.validateNow();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
