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

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  CountryCodeData _selectedCountry = CountryCodes.defaultCountry;

  AppLocalizations get l10n => AppLocalizations.of(context);

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;
  bool _emailAlreadyRegistered = false;
  String? _errorMessage;

  static const String _webClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
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
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _emailAlreadyRegistered = false;
    });

    try {
      final result = await VeraApiService.instance.registerBuyer(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phone: CountryCodes.toE164(_selectedCountry, _phoneController.text),
      );

      if (!mounted) return;

      if (result != null) {
        // A pending registration was created — verify the emailed code before
        // the account is activated.
        if (result['pending'] == true) {
          if (mounted) {
            context.push(
              AppRoutes.otpScreen,
              extra: {
                'purpose': 'register_buyer',
                'email': _emailController.text.trim(),
                'role': 'buyer',
                'title': l10n.t('verifyEmail'),
                'subtitle': l10n.t('enter6DigitCodeSentTo', args: {
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
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  l10n.accountCreatedSignIn,
                  style: GoogleFonts.cairo(color: Colors.white),
                ),
                backgroundColor: AppTheme.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            );
            context.go(AppRoutes.loginScreen);
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
        role: 'buyer',
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
              SizedBox(height: 1.h),
              // Back button
              GestureDetector(
                onTap: () => context.go(AppRoutes.loginScreen),
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
                    size: 18,
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
              SizedBox(height: 2.5.h),

              // Header
              Text(
                l10n.createAccount,
                style: GoogleFonts.cairo(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.charcoal,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 0.6.h),
              Text(
                l10n.joinVeraDiscover,
                style: GoogleFonts.cairo(
                  fontSize: 13.sp,
                  color: AppTheme.grayText,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: 3.h),

              // Form
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel(l10n.fullName),
                    SizedBox(height: 0.8.h),
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      style: GoogleFonts.cairo(
                        fontSize: 13.sp,
                        color: AppTheme.charcoal,
                      ),
                      decoration: _inputDecoration(
                        hint: l10n.yourFullName,
                        prefixIcon: Icons.person_outline_rounded,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return l10n.nameRequired;
                        }
                        if (v.trim().length < 2) return l10n.nameTooShort;
                        return null;
                      },
                    ),
                    SizedBox(height: 2.h),
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
                    _buildLabel(l10n.phoneNumber),
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
                        prefix: _buildCountryPrefix(),
                      ),
                      validator: (v) {
                        final result = CountryCodes.validate(
                          _selectedCountry,
                          v,
                        );
                        if (result == 'empty') return l10n.phoneRequired;
                        if (result == 'invalid') {
                          return l10n.phoneInvalidForCountry;
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
                      textInputAction: TextInputAction.next,
                      style: GoogleFonts.cairo(
                        fontSize: 13.sp,
                        color: AppTheme.charcoal,
                      ),
                      decoration: _inputDecoration(
                        hint: l10n.min8Characters,
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
                    _buildLabel(l10n.confirmPassword),
                    SizedBox(height: 0.8.h),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleRegister(),
                      style: GoogleFonts.cairo(
                        fontSize: 13.sp,
                        color: AppTheme.charcoal,
                      ),
                      decoration: _inputDecoration(
                        hint: l10n.reEnterPassword,
                        prefixIcon: Icons.lock_outline_rounded,
                        suffix: GestureDetector(
                          onTap: () => setState(
                            () => _obscureConfirm = !_obscureConfirm,
                          ),
                          child: Icon(
                            _obscureConfirm
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
                    SizedBox(height: 3.h),

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
                            onTap: _goToLogin,
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
                                  l10n.createAccount,
                                  style: GoogleFonts.cairo(
                                    fontSize: 14.sp,
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
                          child: Divider(
                            color: AppTheme.borderLight,
                            thickness: 1,
                          ),
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
                          child: Divider(
                            color: AppTheme.borderLight,
                            thickness: 1,
                          ),
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
                                  color: AppTheme.primaryPink,
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

                    // Login link
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            l10n.alreadyHaveAccount,
                            style: GoogleFonts.cairo(
                              fontSize: 13.sp,
                              color: AppTheme.grayText,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.go(AppRoutes.loginScreen),
                            child: Text(
                              l10n.signIn,
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
                  ],
                ),
              ),
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

  Widget _buildCountryPrefix() {
    return GestureDetector(
      onTap: _showCountryPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: BorderDirectional(
            start: BorderSide(color: AppTheme.borderLight, width: 1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _selectedCountry.flag,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 6),
            Text(
              _selectedCountry.dial,
              style: GoogleFonts.cairo(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: AppTheme.charcoal,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down_rounded,
              color: AppTheme.grayText,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _goToLogin() {
    final email = _emailController.text.trim();
    final query = email.isEmpty ? '' : '?email=${Uri.encodeComponent(email)}';
    context.go('${AppRoutes.loginScreen}$query');
  }

  Future<void> _showCountryPicker() async {
    final selected = await showModalBottomSheet<CountryCodeData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _CountryPickerSheet(
        selectedCode: _selectedCountry.code,
      ),
    );
    if (selected != null && mounted) {
      setState(() {
        _selectedCountry = selected;
      });
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

class _CountryPickerSheet extends StatefulWidget {
  const _CountryPickerSheet({required this.selectedCode});

  final String selectedCode;

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<CountryCodeData> _results = CountryCodes.sorted;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() {
      _results = CountryCodes.search(query);
    });
  }

  Map<String, List<CountryCodeData>> _groupByName(List<CountryCodeData> list) {
    final map = <String, List<CountryCodeData>>{};
    for (final c in list) {
      final letter = c.name[0].toUpperCase();
      map.putIfAbsent(letter, () => []).add(c);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isSearching = _searchController.text.isNotEmpty;
    final popular = CountryCodes.gulf;
    final grouped = _groupByName(_results);
    final letters = grouped.keys.toList()..sort();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
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
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.selectCountry,
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).textTheme.titleLarge?.color,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(
                          Icons.close_rounded,
                          color: Theme.of(context).hintColor,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearch,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    decoration: InputDecoration(
                      hintText: l10n.searchCountry,
                      hintStyle: GoogleFonts.cairo(
                        fontSize: 14,
                        color: Theme.of(context).hintColor,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: Theme.of(context).hintColor,
                        size: 20,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryPink,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: CustomScrollView(
                    controller: scrollController,
                    slivers: [
                      if (!isSearching) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                            child: Text(
                              l10n.popularCountries,
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryPink,
                              ),
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          sliver: SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 2.4,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final c = popular[index];
                                final selected = c.code == widget.selectedCode;
                                return GestureDetector(
                                  onTap: () => Navigator.pop(context, c),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? AppTheme.primaryPink.withAlpha(30)
                                          : Theme.of(context).cardColor,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: selected
                                            ? AppTheme.primaryPink
                                            : AppTheme.borderLight,
                                        width: selected ? 1.5 : 1,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(c.flag, style: const TextStyle(fontSize: 16)),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            c.dial,
                                            style: GoogleFonts.cairo(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Theme.of(context).textTheme.bodyLarge?.color,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (selected)
                                          const Icon(Icons.check_rounded, color: AppTheme.primaryPink, size: 14),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              childCount: popular.length,
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                            child: Text(
                              l10n.allCountries,
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).hintColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                      for (final letter in letters) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 10, 20, 2),
                            child: Text(
                              letter,
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryPink,
                              ),
                            ),
                          ),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final c = grouped[letter]![index];
                              final selected = c.code == widget.selectedCode;
                              return InkWell(
                                onTap: () => Navigator.pop(context, c),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? AppTheme.primaryPink.withAlpha(20)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(c.flag, style: const TextStyle(fontSize: 22)),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          c.name,
                                          style: GoogleFonts.cairo(
                                            fontSize: 14,
                                            color: Theme.of(context).textTheme.bodyLarge?.color,
                                            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        c.dial,
                                        style: GoogleFonts.cairo(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context).hintColor,
                                        ),
                                      ),
                                      if (selected) ...[
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          color: AppTheme.primaryPink,
                                          size: 18,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                            childCount: grouped[letter]!.length,
                          ),
                        ),
                      ],
                      const SliverToBoxAdapter(child: SizedBox(height: 40)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
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
