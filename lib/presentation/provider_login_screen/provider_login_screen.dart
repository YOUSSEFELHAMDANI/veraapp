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

class ProviderLoginScreen extends StatefulWidget {
  const ProviderLoginScreen({super.key});

  @override
  State<ProviderLoginScreen> createState() => _ProviderLoginScreenState();
}

class _ProviderLoginScreenState extends State<ProviderLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
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

  Future<void> _handleProviderLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final result = await VeraApiService.instance.loginProvider(
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
                'purpose': 'login_provider',
                'email': _emailController.text.trim(),
                'role': 'provider',
                'title': l10n.verifyLogin,
                'subtitle':
                    l10n.t('enterCodeSentTo', args: {'email': _emailController.text.trim()}),
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
          await VeraApiService.instance.setProviderToken(token.toString());
          await VeraApiService.instance.setOnboardingDone();
          if (mounted) {
            context.go(AppRoutes.providerDashboardScreen);
          }
        } else {
          setState(
            () =>
                _errorMessage = l10n.loginFailed,
          );
        }
      } else {
        setState(
          () => _errorMessage = l10n.loginFailed,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _errorMessage = l10n.somethingWentWrong,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        if (mounted) setState(() => _isGoogleLoading = false);
        return;
      }

      final GoogleSignInAuthentication auth = await account.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final firebaseToken = await userCredential.user?.getIdToken();

      if (firebaseToken == null || firebaseToken.isEmpty) {
        await FirebaseAuth.instance.signOut();
        await _googleSignIn.signOut();
        if (mounted) {
          setState(() {
            _isGoogleLoading = false;
            _errorMessage = l10n.googleSignInFailed;
          });
        }
        return;
      }

      final result = await VeraApiService.instance.loginWithGoogle(
        idToken: firebaseToken,
        role: 'provider',
      );
      if (!mounted) return;

      final token =
          result?['token'] ??
          result?['access_token'] ??
          result?['data']?['token'] ??
          result?['data']?['access_token'];

      if (token != null && token.toString().isNotEmpty) {
        await VeraApiService.instance.setProviderToken(token.toString());
        await VeraApiService.instance.setOnboardingDone();
        if (mounted) {
          context.go(AppRoutes.providerDashboardScreen);
        }
      } else {
        await FirebaseAuth.instance.signOut();
        await _googleSignIn.signOut();
        if (mounted) {
          setState(() {
            _isGoogleLoading = false;
            _errorMessage = l10n.googleSignInFailed;
          });
        }
      }
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      try {
        await FirebaseAuth.instance.signOut();
        await _googleSignIn.signOut();
      } catch (_) {}
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
          _errorMessage = l10n.googleSignInFailed;
        });
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  String _generateNonce() {
    final rng = Random.secure();
    final values = List<int>.generate(32, (_) => rng.nextInt(256));
    return base64Url.encode(values).replaceAll('=', '');
  }

  Future<void> _handleAppleSignIn() async {
    final l10n = AppLocalizations.of(context);
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
        role: 'provider',
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
        await VeraApiService.instance.setProviderToken(token.toString());
        await VeraApiService.instance.setOnboardingDone();
        if (mounted) {
          context.go(AppRoutes.providerDashboardScreen);
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

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(prefixIcon, color: AppTheme.grayText, size: 20),
      suffixIcon: suffix,
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
        borderSide: const BorderSide(color: AppTheme.goldAccent, width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.8.h),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 2.h),
              // Back button
              GestureDetector(
                onTap: () => context.go(AppRoutes.loginScreen),
                child: Container(
                  width: 10.w,
                  height: 10.w,
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
              SizedBox(height: 3.h),
              // Logo
              Center(
                child: Container(
                  width: 18.w,
                  height: 18.w,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFC8A96A), Color(0xFFEFA9B8)],
                    ),
                    borderRadius: BorderRadius.circular(20.0),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.goldAccent.withAlpha(77),
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
              SizedBox(height: 2.h),
              Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 3.w,
                    vertical: 0.6.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.goldLight,
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Text(
                    l10n.t('providerPortal'),
                    style: GoogleFonts.cairo(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.goldAccent,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 1.5.h),
              Center(
                child: Text(
                  l10n.signInAsProvider,
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
                  l10n.t('manageYourServices'),
                  style: GoogleFonts.cairo(
                    fontSize: 12.sp,
                    color: AppTheme.grayText,
                  ),
                ),
              ),
              SizedBox(height: 4.h),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.t('businessEmail'),
                      style: GoogleFonts.cairo(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.charcoal,
                      ),
                    ),
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
                        hint: l10n.t('providerAtBusiness'),
                        prefixIcon: Icons.business_outlined,
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
                    Text(
                      l10n.password,
                      style: GoogleFonts.cairo(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.charcoal,
                      ),
                    ),
                    SizedBox(height: 0.8.h),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleProviderLogin(),
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
                    SizedBox(height: 2.h),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.go(
                          AppRoutes.forgotPasswordScreen,
                          extra: {'role': 'provider'},
                        ),
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
                            color: AppTheme.error.withAlpha(60),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppTheme.error,
                              size: 18,
                            ),
                            SizedBox(width: 2.w),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: GoogleFonts.cairo(
                                  fontSize: 11.sp,
                                  color: AppTheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 2.h),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 6.h,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleProviderLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.goldAccent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                l10n.signInAsProvider,
                                style: GoogleFonts.cairo(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 3.h),
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

              // Google Sign-In Button
              SizedBox(
                width: double.infinity,
                height: 6.h,
                child: OutlinedButton(
                  onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: AppTheme.borderLight,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    backgroundColor: Theme.of(context).colorScheme.surface,
                  ),
                  child: _isGoogleLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.goldAccent,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _GoogleLogo(),
                            SizedBox(width: 2.w),
                            Text(
                              l10n.t('continueWithGoogle'),
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

              Center(
                child: TextButton(
                  onPressed: () => context.go(AppRoutes.loginScreen),
                  child: Text(
                    l10n.t('signInAsCustomer'),
                    style: GoogleFonts.cairo(
                      fontSize: 12.sp,
                      color: AppTheme.primaryPink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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

    final paintWhite = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), r * 0.6, paintWhite);

    final barPaint = Paint()..color = const Color(0xFF4285F4);
    canvas.drawRect(Rect.fromLTWH(cx, cy - r * 0.15, r, r * 0.3), barPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
