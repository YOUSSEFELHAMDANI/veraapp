import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_localizations.dart';
import '../../routes/app_routes.dart';
import '../../services/vera_api_service.dart';
import '../../theme/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String role;

  const ForgotPasswordScreen({super.key, this.role = 'buyer'});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  AppLocalizations get l10n => AppLocalizations.of(context);

  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendResetLink() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // POST /api/auth/password-reset/request — responds generically whether
      // or not the account exists (no user enumeration).
      final result = await VeraApiService.instance.requestPasswordReset(
        email: _emailController.text.trim(),
        role: widget.role,
      );

      if (!mounted) return;

      if (result == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = l10n.somethingWentWrong;
        });
        return;
      }

      final error = result['error']?.toString();
      if (error != null && error.isNotEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = error;
        });
        return;
      }

      setState(() => _isLoading = false);

      // Proceed to code entry + new password on the OTP screen.
      context.push(
        AppRoutes.otpScreen,
        extra: {
          'purpose': 'reset_password',
          'email': _emailController.text.trim(),
          'role': widget.role,
          'title': l10n.resetPassword,
          'subtitle': l10n.t('enterCodeAndChooseNewPassword', args: {
            'email': _emailController.text.trim(),
          }),
          'showPasswordField': true,
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = l10n.somethingWentWrong;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(AppRoutes.loginScreen),
          icon: Icon(Icons.arrow_back_rounded, color: AppTheme.charcoal),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
          child: _emailSent ? _buildConfirmationView() : _buildFormView(),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 1.h),
        // Icon
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
            l10n.forgotPassword,
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
            l10n.forgotPasswordInstructions,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 13.sp,
              color: AppTheme.grayText,
              fontWeight: FontWeight.w400,
              height: 1.5,
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
              Text(
                l10n.email,
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
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _handleSendResetLink(),
                style: GoogleFonts.cairo(
                  fontSize: 13.sp,
                  color: AppTheme.charcoal,
                ),
                decoration: InputDecoration(
                  hintText: l10n.emailExample,
                  hintStyle: GoogleFonts.cairo(
                    fontSize: 13.sp,
                    color: AppTheme.grayText,
                  ),
                  prefixIcon: Icon(
                    Icons.mail_outline_rounded,
                    color: AppTheme.grayText,
                    size: 20,
                  ),
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
                    borderSide: const BorderSide(
                      color: AppTheme.primaryPink,
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(color: AppTheme.error),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(
                      color: AppTheme.error,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return l10n.emailRequired;
                  }
                  if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(v.trim())) {
                    return l10n.emailInvalid;
                  }
                  return null;
                },
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
                    border: Border.all(color: AppTheme.error.withAlpha(77)),
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

              // Send Reset Link Button
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
                    onPressed: _isLoading ? null : _handleSendResetLink,
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
                            l10n.sendCode,
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

        // Back to login
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.rememberYourPassword,
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
    );
  }

  Widget _buildConfirmationView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 4.h),
        // Success icon
        Center(
          child: Container(
            width: 22.w,
            height: 22.w,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryPink.withAlpha(77),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.mark_email_read_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
        ),
        SizedBox(height: 3.h),
        Text(
          l10n.checkYourEmail,
          style: GoogleFonts.cairo(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoal,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 1.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Text(
            l10n.t('weSentResetLinkTo', args: {
              'email': _emailController.text.trim(),
            }),
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 13.sp,
              color: AppTheme.grayText,
              height: 1.6,
            ),
          ),
        ),
        SizedBox(height: 1.5.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Text(
            l10n.resetEmailInstructions,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 12.sp,
              color: AppTheme.grayText.withAlpha(180),
              height: 1.5,
            ),
          ),
        ),
        SizedBox(height: 4.h),

        // Back to login button
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
              onPressed: () => context.go(AppRoutes.loginScreen),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.0),
                ),
              ),
              child: Text(
                l10n.backToSignIn,
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

        // Resend option
        TextButton(
          onPressed: () {
            setState(() {
              _emailSent = false;
              _errorMessage = null;
            });
          },
          child: Text(
            l10n.didntReceiveTryAgain,
            style: GoogleFonts.cairo(
              fontSize: 13.sp,
              color: AppTheme.primaryPinkDark,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(height: 2.h),
      ],
    );
  }
}
