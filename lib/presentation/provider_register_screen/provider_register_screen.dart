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
import '../../data/country_codes.dart';
import '../../routes/app_routes.dart';
import '../../services/vera_api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/password_rules_checklist.dart';

class ProviderRegisterScreen extends StatefulWidget {
  const ProviderRegisterScreen({super.key});

  @override
  State<ProviderRegisterScreen> createState() => _ProviderRegisterScreenState();
}

class _ProviderRegisterScreenState extends State<ProviderRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;
  bool _emailAlreadyRegistered = false;
  String? _errorMessage;
  CountryCodeData _selectedCountry = CountryCodes.defaultCountry;

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
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _businessNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _emailAlreadyRegistered = false;
    });

    try {
      final result = await VeraApiService.instance.registerProvider(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phone: CountryCodes.toE164(
          _selectedCountry,
          _phoneController.text.trim(),
        ),
        businessName: _businessNameController.text.trim().isNotEmpty
            ? _businessNameController.text.trim()
            : null,
      );

      if (!mounted) return;

      if (result != null) {
        // A pending registration was created — verify the emailed code before
        // the provider account is stored (still requires admin approval).
        if (result['pending'] == true) {
          if (mounted) {
            context.push(
              AppRoutes.otpScreen,
              extra: {
                'purpose': 'register_provider',
                'email': _emailController.text.trim(),
                'role': 'provider',
                'title': l10n.verifyEmail,
                'subtitle':
                    l10n.t('enter6DigitCodeSentTo',
                        args: {'email': _emailController.text.trim()}),
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
          if (mounted) {
            _showSuccessDialog();
          }
        }
      } else {
        setState(() {
          _errorMessage = l10n.registrationFailed;
        });
      }
    } on VeraAuthException catch (e) {
      if (!mounted) return;
      final msg = e.message.toLowerCase();
      setState(() {
        _emailAlreadyRegistered =
            e.statusCode == 409 ||
                msg.contains('already') ||
                msg.contains('registered') ||
                msg.contains('exists') ||
                msg.contains('مسجل') ||
                msg.contains('موجود');
        _errorMessage = _emailAlreadyRegistered
            ? l10n.emailAlreadyRegistered
            : e.message;
      });
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
      final googleIdToken = auth.idToken;

      if (googleIdToken == null || googleIdToken.isEmpty) {
        await _googleSignIn.signOut();
        if (mounted) {
          setState(() {
            _isGoogleLoading = false;
            _errorMessage = l10n.googleSignInFailed;
          });
        }
        return;
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);

      final result = await VeraApiService.instance.loginWithGoogle(
        idToken: googleIdToken,
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

  void _showSuccessDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppTheme.goldLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppTheme.goldAccent,
                size: 28,
              ),
            ),
            SizedBox(height: 1.5.h),
            Text(
              l10n.t('accountCreated'),
              style: GoogleFonts.cairo(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: AppTheme.charcoal,
              ),
            ),
          ],
        ),
        content: Text(
          l10n.t('providerAccountCreated'),
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(fontSize: 12.sp, color: AppTheme.grayText),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.go(AppRoutes.providerLoginScreen);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                l10n.signIn,
                style: GoogleFonts.cairo(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
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
              // Back button
              GestureDetector(
                onTap: () => context.go(AppRoutes.providerLoginScreen),
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
              SizedBox(height: 2.5.h),

              // Logo / Brand
              Center(
                child: Container(
                  width: 18.w,
                  height: 18.w,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.goldAccent, AppTheme.goldLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
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
              SizedBox(height: 2.5.h),

              Center(
                child: Text(
                  l10n.createProviderAccount,
                  style: GoogleFonts.cairo(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.charcoal,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              SizedBox(height: 0.8.h),
              Center(
                child: Text(
                  l10n.t('joinVeraAsProvider'),
                  style: GoogleFonts.cairo(
                    fontSize: 12.sp,
                    color: AppTheme.grayText,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              SizedBox(height: 3.h),

              // Form
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel(l10n.fullName, true),
                    SizedBox(height: 0.8.h),
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      style: GoogleFonts.cairo(
                        fontSize: 13.sp,
                        color: AppTheme.charcoal,
                      ),
                      decoration: _inputDecoration(
                        hint: l10n.t('yourFullNameHint'),
                        prefixIcon: Icons.person_outline_rounded,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return l10n.t('fullNameRequired');
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 2.h),

                    _buildLabel(l10n.t('businessNameOptional'), false),
                    SizedBox(height: 0.8.h),
                    TextFormField(
                      controller: _businessNameController,
                      textInputAction: TextInputAction.next,
                      style: GoogleFonts.cairo(
                        fontSize: 13.sp,
                        color: AppTheme.charcoal,
                      ),
                      decoration: _inputDecoration(
                        hint: l10n.t('yourBusinessNameHint'),
                        prefixIcon: Icons.storefront_outlined,
                      ),
                    ),
                    SizedBox(height: 2.h),

                    _buildLabel(l10n.email, true),
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
                        hint: 'you@example.com',
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

                    _buildLabel(l10n.phoneNumber, true),
                    SizedBox(height: 0.8.h),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      style: GoogleFonts.cairo(
                        fontSize: 13.sp,
                        color: AppTheme.charcoal,
                      ),
                      decoration: _inputDecoration(
                        hint: l10n.phoneNumberHint,
                        prefixIcon: Icons.phone_outlined,
                        prefix: GestureDetector(
                          onTap: _showCountryPicker,
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
                            child: Text(
                              '${_selectedCountry.flag} +${_selectedCountry.dialCode}',
                              style: GoogleFonts.cairo(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.charcoal,
                              ),
                            ),
                          ),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return l10n.phoneRequired;
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 2.h),

                    _buildLabel(l10n.t('passwordRequiredLabel'), true),
                    SizedBox(height: 0.8.h),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
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
                        return PasswordRules.validate(l10n, v);
                      },
                    ),
                    SizedBox(height: 1.2.h),
                    PasswordRulesChecklist(controller: _passwordController),
                    SizedBox(height: 1.6.h),

                    _buildLabel(l10n.t('confirmPasswordRequired'), true),
                    SizedBox(height: 0.8.h),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleRegister(),
                      style: GoogleFonts.cairo(
                        fontSize: 13.sp,
                        color: AppTheme.charcoal,
                      ),
                      decoration: _inputDecoration(
                        hint: '••••••••',
                        prefixIcon: Icons.lock_outline_rounded,
                        suffix: GestureDetector(
                          onTap: () => setState(
                            () => _obscureConfirmPassword =
                                !_obscureConfirmPassword,
                          ),
                          child: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppTheme.grayText,
                            size: 20,
                          ),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return l10n.pleaseConfirmPassword;
                        }
                        if (v != _passwordController.text) {
                          return l10n.passwordsDoNotMatch;
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 2.5.h),

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
                      if (_emailAlreadyRegistered) ...[
                        SizedBox(height: 1.h),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () => context.go(AppRoutes.providerLoginScreen),
                            child: Text(
                              l10n.signIn,
                              style: GoogleFonts.cairo(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryPink,
                              ),
                            ),
                          ),
                        ),
                      ],
                      SizedBox(height: 2.h),
                    ],

                    // Register Button
                    SizedBox(
                      width: double.infinity,
                      height: 6.h,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.goldAccent, Color(0xFFB8924A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14.0),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.goldAccent.withAlpha(89),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleRegister,
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
                                  l10n.createProviderAccount,
                                  style: GoogleFonts.cairo(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    SizedBox(height: 2.h),

                    // Divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(color: AppTheme.borderLight),
                        ),
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
                        Expanded(
                          child: Divider(color: AppTheme.borderLight),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),

                    // Google Sign-In Button
                    SizedBox(
                      width: double.infinity,
                      height: 6.h,
                      child: OutlinedButton(
                        onPressed: _isGoogleLoading
                            ? null
                            : _handleGoogleSignIn,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: AppTheme.borderLight,
                            width: 1.5,
                          ),
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
                                  color: AppTheme.goldAccent,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _GoogleLogo(),
                                  SizedBox(width: 2.w),
                                  Text(
                                    l10n.signUpWithGoogle,
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
SizedBox(height: 3.h),

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

                    // Already have account
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            l10n.t('alreadyHaveProviderAccount'),
                            style: GoogleFonts.cairo(
                              fontSize: 12.sp,
                              color: AppTheme.grayText,
                            ),
                          ),
                          GestureDetector(
                            onTap: () =>
                                context.go(AppRoutes.providerLoginScreen),
                            child: Text(
                              l10n.signIn,
                              style: GoogleFonts.cairo(
                                fontSize: 12.sp,
                                color: AppTheme.goldAccent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 2.h),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, bool required) {
    return Text(
      required ? '$text *' : text,
      style: GoogleFonts.cairo(
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
        color: AppTheme.charcoal,
      ),
    );
  }

  Future<void> _showCountryPicker() async {
    final selected = await showModalBottomSheet<CountryCodeData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                AppLocalizations.of(context).phoneCountryCode,
                style: GoogleFonts.cairo(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: CountryCodes.sorted.length,
                itemBuilder: (context, index) {
                  final country = CountryCodes.sorted[index];
                  return ListTile(
                    leading: Text(country.flag, style: const TextStyle(fontSize: 24)),
                    title: Text(country.name, style: GoogleFonts.cairo()),
                    trailing: Text(
                      '+${country.dialCode}',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                    ),
                    selected: country.code == _selectedCountry.code,
                    onTap: () => Navigator.of(context).pop(country),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    if (selected != null && mounted) {
      setState(() => _selectedCountry = selected);
    }
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffix,
    Widget? prefix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.cairo(fontSize: 13.sp, color: AppTheme.grayText),
      prefixIcon: Icon(prefixIcon, color: AppTheme.grayText, size: 20),
      prefix: prefix,
      prefixIconConstraints: prefix != null
          ? const BoxConstraints(minWidth: 44, minHeight: 24)
          : null,
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
        borderSide: const BorderSide(color: AppTheme.goldAccent, width: 2),
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
