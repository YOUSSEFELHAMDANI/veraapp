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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  if (!kIsWeb) {
    const initialization = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _localNotifications.initialize(initialization);
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_notificationChannel);
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      final token = await messaging.getToken();
      debugPrint('FCM Token: $token');
      if (token != null && token.isNotEmpty) {
        VeraApiService.instance.cacheFcmToken(token);
        await VeraApiService.instance.registerPushToken(token);
      }
    }
    messaging.onTokenRefresh.listen(
      (token) => VeraApiService.instance.registerPushToken(token),
    );
  }

  await ThemeController.instance.init();
  await UserInterestTracker.instance.init();

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

  // 🚨 CRITICAL: Device orientation lock - DO NOT REMOVE
  // Skipped on web — SystemChrome orientation lock is a no-op on Flutter Web
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  if (!kIsWeb) {
    _setupDeepLinks();
  }

  // Global provider container: bound to AuthSession so a logout / token expiry
  // can purge every cached authenticated object (user, cart, ...).
  final container = ProviderContainer();
  AuthSession.instance.bind(container);

  runApp(UncontrolledProviderScope(container: container, child: const MyApp()));
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
