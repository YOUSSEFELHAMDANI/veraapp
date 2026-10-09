import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_localizations.dart';
import '../../routes/app_routes.dart';
import '../../services/vera_api_service.dart';
import '../../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  AppLocalizations get l10n => AppLocalizations.of(context);

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;
  String? _errorMessage;

  static const String _webClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '866406669480-he67gobkucf05lm3motos62phamj2g8i.apps.googleusercontent.com',
  );

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: _webClientId,
    scopes: ['email', 'profile'],
  );

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final email = GoRouterState.of(context).uri.queryParameters['email'];
    if (email != null && email.isNotEmpty && _emailController.text.isEmpty) {
      _emailController.text = email;
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await VeraApiService.instance.loginBuyer(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (result != null) {
        // Email-OTP gate enabled on the server: password was validated and a
        // one-time code was emailed — no session token yet.
        if (result['otp_required'] == true) {
          if (mounted) {
            context.push(
              AppRoutes.otpScreen,
              extra: {
                'purpose': 'login_buyer',
                'email': _emailController.text.trim(),
                'role': 'buyer',
                'title': l10n.t('verifyLogin'),
                'subtitle': l10n.t('enterCodeSentTo', args: {
                  'email': _emailController.text.trim(),
                }),
                'expiresInSeconds': result['expiresInSeconds'],
                'resendCooldownSeconds': result['resendCooldownSeconds'],
              },
            );
          }
          return;
        }

        final token =
            result['token'] ??
            result['access_token'] ??
            result['data']?['token'] ??
            result['data']?['access_token'];

        if (token != null && token.toString().isNotEmpty) {
          await VeraApiService.instance.setToken(token.toString());
          await VeraApiService.instance.setOnboardingDone();
          if (mounted) {
            context.go(AppRoutes.homeScreen);
          }
        } else {
          setState(() {
            _errorMessage = l10n.loginFailed;
          });
        }
      } else {
        setState(() {
          _errorMessage = l10n.loginFailed;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = l10n.somethingWentWrong;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    try {
      // ignore: avoid_print
      print('[GoogleSignIn] Starting signIn...');
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        // ignore: avoid_print
        print('[GoogleSignIn] Account is null - user cancelled');
        if (mounted) setState(() => _isGoogleLoading = false);
        return;
      }
      // ignore: avoid_print
      print('[GoogleSignIn] Account obtained: ${account.email}');

      final GoogleSignInAuthentication auth = await account.authentication;
      // ignore: avoid_print
      print('[GoogleSignIn] Auth obtained. accessToken=${auth.accessToken != null}, idToken=${auth.idToken != null}');
      if (auth.idToken == null) {
        // ignore: avoid_print
        print('[GoogleSignIn] ERROR: idToken is null!');
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );
      // ignore: avoid_print
      print('[GoogleSignIn] Firebase credential created');

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      // ignore: avoid_print
      print('[GoogleSignIn] Firebase signIn success: ${userCredential.user?.uid}');
      
      // Send Google ID token to backend (backend verifies with Google OAuth)
      final idTokenToSend = auth.idToken;
      // ignore: avoid_print
      print('[GoogleSignIn] Sending Google idToken to backend (len=${idTokenToSend?.length})');

      final result = await VeraApiService.instance.loginWithGoogle(
        idToken: idTokenToSend ?? '',
        role: 'buyer',
      );
      // ignore: avoid_print
      print('[GoogleSignIn] Backend result: $result');
      if (!mounted) return;

      final token =
          result?['token'] ??
          result?['access_token'] ??
          result?['data']?['token'] ??
          result?['data']?['access_token'];

      if (token != null && token.toString().isNotEmpty) {
        // ignore: avoid_print
        print('[GoogleSignIn] SUCCESS - token obtained');
        await VeraApiService.instance.setToken(token.toString());
        await VeraApiService.instance.setOnboardingDone();
        if (mounted) {
          context.go(AppRoutes.homeScreen);
        }
      } else {
        // ignore: avoid_print
        print('[GoogleSignIn] FAILED - no token in backend response. result=$result');
        await FirebaseAuth.instance.signOut();
        await _googleSignIn.signOut();
        if (mounted) {
          setState(() {
            _isGoogleLoading = false;
            _errorMessage = '${l10n.googleSignInFailed} (${result?['error'] ?? result?['message'] ?? 'no_token'})';
          });
        }
      }
    } catch (e, stackTrace) {
      // ignore: avoid_print
      print('[GoogleSignIn] EXCEPTION: $e');
      // ignore: avoid_print
      print('[GoogleSignIn] STACK: $stackTrace');
      try {
        await FirebaseAuth.instance.signOut();
        await _googleSignIn.signOut();
      } catch (_) {}
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
          _errorMessage = '${l10n.googleSignInFailed} ($e)';
        });
      }
    } finally {
      if (mounted) setState(() => _isAppleLoading = false);
    }
  }

  String _generateNonce() {
    final rng = Random.secure();
    final values = List<int>.generate(32, (_) => rng.nextInt(256));
    return base64Url.encode(values).replaceAll('=', '');
  }

  Future<void> _handleAppleSignIn() async {
    setState(() {
      _isAppleLoading = true;
      _errorMessage = null;
    });

    try {
      final rawNonce = _generateNonce();
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: rawNonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null || idToken.isEmpty) {
        if (mounted) {
          setState(() {
            _isAppleLoading = false;
            _errorMessage = l10n.appleSignInFailed;
          });
        }
        return;
      }

      final appleName = [
        credential.givenName ?? '',
        credential.familyName ?? '',
      ].where((s) => s.trim().isNotEmpty).join(' ').trim();

      final result = await VeraApiService.instance.loginWithApple(
        idToken: idToken,
        role: 'buyer',
        nonce: rawNonce,
        name: appleName.isEmpty ? null : appleName,
      );
      if (!mounted) return;

      final token =
          result?['token'] ??
          result?['access_token'] ??
          result?['data']?['token'] ??
          result?['data']?['access_token'];

      if (token != null && token.toString().isNotEmpty) {
        await VeraApiService.instance.setToken(token.toString());
        await VeraApiService.instance.setOnboardingDone();
        if (mounted) {
          context.go(AppRoutes.homeScreen);
        }
      } else {
        if (mounted) {
          setState(() {
            _isAppleLoading = false;
            _errorMessage = '${l10n.appleSignInFailed} (${result?['error'] ?? result?['message'] ?? 'no_token'})';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAppleLoading = false;
          _errorMessage = '${l10n.appleSignInFailed} ($e)';
        });
      }
    } finally {
      if (mounted) setState(() => _isAppleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              GestureDetector(
                onTap: () => context.canPop()
                    ? context.pop()
                    : context.go(AppRoutes.onboardingScreen),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16,
                    color: AppTheme.charcoal,
                  ),
                ),
              ),
              SizedBox(height: 2.h),
              // Logo / Brand
              Center(
                child: Container(
                  width: 18.w,
                  height: 18.w,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(20.0),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryPink.withAlpha(77),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20.0),
                    child: Image.asset(
                      'assets/images/icon-1785658212252.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 3.h),
              Center(
                child: Text(
                  l10n.welcomeBack,
                  style: GoogleFonts.cairo(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.charcoal,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              SizedBox(height: 0.8.h),
              Center(
                child: Text(
                  l10n.signInToVeraAccount,
                  style: GoogleFonts.cairo(
                    fontSize: 13.sp,
                    color: AppTheme.grayText,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              SizedBox(height: 4.h),

              // Form
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel(l10n.email),
                    SizedBox(height: 0.8.h),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      style: GoogleFonts.cairo(
                        fontSize: 13.sp,
                        color: AppTheme.charcoal,
                      ),
                      decoration: _inputDecoration(
                        hint: l10n.emailExample,
                        prefixIcon: Icons.mail_outline_rounded,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return l10n.emailRequired;
                        }
                        if (!RegExp(
                          r'^[\w\.-]+@[\w\.-]+\.\w+$',
                        ).hasMatch(v.trim())) {
                          return l10n.emailInvalid;
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 2.h),
                    _buildLabel(l10n.password),
                    SizedBox(height: 0.8.h),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleLogin(),
                      style: GoogleFonts.cairo(
                        fontSize: 13.sp,
                        color: AppTheme.charcoal,
                      ),
                      decoration: _inputDecoration(
                        hint: '••••••••',
                        prefixIcon: Icons.lock_outline_rounded,
                        suffix: GestureDetector(
                          onTap: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          child: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppTheme.grayText,
                            size: 20,
                          ),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return l10n.passwordRequired;
                        }
                        if (v.length < 6) return l10n.minCharacters6;
                        return null;
                      },
                    ),
                    SizedBox(height: 1.h),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () =>
                            context.go(AppRoutes.forgotPasswordScreen),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          l10n.forgotPassword,
                          style: GoogleFonts.cairo(
                            fontSize: 12.sp,
                            color: AppTheme.primaryPink,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 2.h),

                    // Error message
                    if (_errorMessage != null) ...[
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 1.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withAlpha(20),
                          borderRadius: BorderRadius.circular(10.0),
                          border: Border.all(
                            color: AppTheme.error.withAlpha(77),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              color: AppTheme.error,
                              size: 18,
                            ),
                            SizedBox(width: 2.w),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: GoogleFonts.cairo(
                                  fontSize: 12.sp,
                                  color: AppTheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 2.h),
                    ],

                    // Sign In Button
                    SizedBox(
                      width: double.infinity,
                      height: 6.h,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(14.0),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryPink.withAlpha(89),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.0),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  l10n.signIn,
                                  style: GoogleFonts.cairo(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 3.h),

              // Divider
              Row(
                children: [
                  Expanded(
                    child: Divider(color: AppTheme.borderLight, thickness: 1),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 3.w),
                    child: Text(
                      l10n.or,
                      style: GoogleFonts.cairo(
                        fontSize: 12.sp,
                        color: AppTheme.grayText,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(color: AppTheme.borderLight, thickness: 1),
                  ),
                ],
              ),

              SizedBox(height: 3.h),

              // Google Sign-In Button
              SizedBox(
                width: double.infinity,
                height: 6.h,
                child: OutlinedButton(
                  onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.borderLight, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.0),
                    ),
                    backgroundColor: Theme.of(context).colorScheme.surface,
                  ),
                  child: _isGoogleLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primaryPink,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _GoogleLogo(),
                            SizedBox(width: 2.w),
                            Text(
                              l10n.signInWithGoogle,
                              style: GoogleFonts.cairo(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.charcoal,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              SizedBox(height: 2.h),

              if (!kIsWeb &&
                  (defaultTargetPlatform == TargetPlatform.iOS ||
                      defaultTargetPlatform == TargetPlatform.macOS)) ...[
                SizedBox(
                  width: double.infinity,
                  height: 6.h,
                  child: SignInWithAppleButton(
                    onPressed: _isAppleLoading ? () {} : () => _handleAppleSignIn(),
                    style: SignInWithAppleButtonStyle.black,
                  ),
                ),
                SizedBox(height: 2.h),
              ],

              // Continue as Guest Button
              SizedBox(
                width: double.infinity,
                height: 6.h,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await VeraApiService.instance.setGuestMode(true);
                    await VeraApiService.instance.setOnboardingDone();
                    if (context.mounted) context.go(AppRoutes.homeScreen);
                  },
                  icon: Icon(
                    Icons.person_outline_rounded,
                    color: AppTheme.grayText,
                    size: 20,
                  ),
                  label: Text(
                    l10n.continueAsGuest,
                    style: GoogleFonts.cairo(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.grayText,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.borderLight, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.0),
                    ),
                    backgroundColor: AppTheme.surfaceLight,
                  ),
                ),
              ),

              SizedBox(height: 3.h),

              // Register link
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.dontHaveAccount,
                      style: GoogleFonts.cairo(
                        fontSize: 13.sp,
                        color: AppTheme.grayText,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go(AppRoutes.registerScreen),
                      child: Text(
                        l10n.createOne,
                        style: GoogleFonts.cairo(
                          fontSize: 13.sp,
                          color: AppTheme.primaryPink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 2.h),
              // Provider login separator
              Row(
                children: [
                  Expanded(child: Divider(color: AppTheme.borderLight)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 3.w),
                    child: Text(
                      l10n.or,
                      style: GoogleFonts.cairo(
                        fontSize: 11.sp,
                        color: AppTheme.grayText,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: AppTheme.borderLight)),
                ],
              ),
              SizedBox(height: 2.h),
              SizedBox(
                width: double.infinity,
                height: 6.h,
                child: OutlinedButton.icon(
                  onPressed: () => context.go(AppRoutes.providerLoginScreen),
                  icon: const Icon(Icons.storefront_outlined, size: 18),
                  label: Text(
                    l10n.signInAsProvider,
                    style: GoogleFonts.cairo(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.goldAccent,
                    side: const BorderSide(
                      color: AppTheme.goldAccent,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 1.5.h),
              SizedBox(
                width: double.infinity,
                height: 6.h,
                child: OutlinedButton.icon(
                  onPressed: () => context.go(AppRoutes.providerRegisterScreen),
                  icon: const Icon(Icons.person_add_outlined, size: 18),
                  label: Text(
                    l10n.createProviderAccount,
                    style: GoogleFonts.cairo(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.goldAccent,
                    side: BorderSide(
                      color: AppTheme.goldAccent.withAlpha(153),
                      width: 1.5,
                    ),
                    backgroundColor: AppTheme.goldAccent.withAlpha(13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 2.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.cairo(
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
        color: AppTheme.charcoal,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.cairo(fontSize: 13.sp, color: AppTheme.grayText),
      prefixIcon: Icon(prefixIcon, color: AppTheme.grayText, size: 20),
      suffixIcon: suffix != null
          ? Padding(padding: const EdgeInsets.only(right: 12), child: suffix)
          : null,
      filled: true,
      fillColor: AppTheme.surfaceLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: AppTheme.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: AppTheme.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: AppTheme.primaryPink, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: AppTheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: AppTheme.error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double r = size.width / 2;

    final paintBlue = Paint()..color = const Color(0xFF4285F4);
    final paintRed = Paint()..color = const Color(0xFFEA4335);
    final paintYellow = Paint()..color = const Color(0xFFFBBC05);
    final paintGreen = Paint()..color = const Color(0xFF34A853);

    // Draw circle segments
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -1.57,
      3.14,
      true,
      paintBlue,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      1.57,
      1.57,
      true,
      paintRed,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      3.14,
      0.785,
      true,
      paintYellow,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      3.925,
      0.785,
      true,
      paintGreen,
    );

    // White center circle
    final paintWhite = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), r * 0.6, paintWhite);

    // Blue right bar (the "G" horizontal bar)
    final barPaint = Paint()..color = const Color(0xFF4285F4);
    canvas.drawRect(Rect.fromLTWH(cx, cy - r * 0.15, r, r * 0.3), barPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
