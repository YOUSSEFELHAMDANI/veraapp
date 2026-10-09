import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_localizations.dart';
import '../../routes/app_routes.dart';
import '../../services/vera_api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/password_rules_checklist.dart';

/// Email-OTP verification screen.
///
/// Args (via [args]):
/// - purpose: register_buyer / register_provider / login_buyer /
///   login_provider / reset_password / change_email_buyer /
///   change_email_provider
/// - email: the address the code was sent to
/// - role: buyer (default) or provider
/// - title / subtitle: optional display strings
/// - showPasswordField: true for reset_password (new password is entered here)
/// - expiresInSeconds / resendCooldownSeconds: overrides for the countdowns
class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.args});

  final Map<String, dynamic> args;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  late final String _purpose;
  late final String _email;
  late final String _role;
  late final String _title;
  late final String _subtitle;
  late final bool _showPasswordField;
  late final int _expiresInSeconds;
  late final int _resendCooldownSeconds;

  final _codeController = TextEditingController();
  final _codeFocusNode = FocusNode();

  final _newPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _verifying = false;
  bool _resending = false;
  bool _clearingCode = false;
  String? _errorMessage;

  late int _remaining;
  late int _resendCooldown;
  Timer? _countdownTimer;
  Timer? _resendTimer;

  AppLocalizations get l10n => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    final a = widget.args;
    _purpose = (a['purpose'] as String?) ?? '';
    _email = (a['email'] as String?) ?? '';
    _role = (a['role'] as String?) ?? (_purpose.endsWith('provider') ? 'provider' : 'buyer');
    _title = (a['title'] as String?) ?? l10n.verifyEmail;
    _subtitle = (a['subtitle'] as String?) ??
        l10n.t('weSent6DigitCodeTo', args: {'email': _email});
    _showPasswordField = a['showPasswordField'] == true || _purpose == 'reset_password';
    _expiresInSeconds = (a['expiresInSeconds'] as num?)?.toInt() ?? 300;
    _resendCooldownSeconds = (a['resendCooldownSeconds'] as num?)?.toInt() ?? 30;

    _remaining = _expiresInSeconds;
    _resendCooldown = _resendCooldownSeconds;

    _codeFocusNode.addListener(() {
      if (mounted) setState(() {});
    });

    _startCountdown();
    _startResendTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _resendTimer?.cancel();
    _codeController.dispose();
    _codeFocusNode.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_remaining > 0) _remaining--;
      });
    });
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_resendCooldown > 0) _resendCooldown--;
      });
    });
  }

  String _getCode() => _codeController.text.trim();

  bool _allDigitsFilled() => _codeController.text.length == 6;

  void _onCodeChanged(String value) {
    if (_clearingCode) return;
    setState(() {
      _errorMessage = null;
    });
    if (_allDigitsFilled()) {
      _verify();
    }
  }

  /// Maps the server-side error responses to clear, localized messages.
  String _localizedOtpError(String error) {
    final msg = error.toLowerCase();
    if (msg.contains('session')) {
      return l10n.otpRegistrationSessionExpired;
    }
    if (msg.contains('incorrect') ||
        msg.contains('invalid code') ||
        msg.contains('wrong code')) {
      return l10n.otpIncorrectCode;
    }
    if (msg.contains('expired') || msg.contains('timeout')) {
      return l10n.otpCodeExpired;
    }
    if (msg.contains('too many') || msg.contains('attempt')) {
      return l10n.otpMaxAttempts;
    }
    return error;
  }

  String _formatSeconds(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  Future<void> _verify() async {
    if (_verifying) return;
    final code = _getCode();
    if (code.length != 6) {
      setState(() => _errorMessage = l10n.pleaseEnter6DigitCode);
      return;
    }
    if (_showPasswordField &&
        !PasswordRules.isSatisfied(_newPasswordController.text)) {
      setState(() {
        _errorMessage = l10n.pwInvalidMessage;
      });
      return;
    }

    setState(() {
      _verifying = true;
      _errorMessage = null;
    });

    try {
      final result = await VeraApiService.instance.verifyOtp(
        purpose: _purpose,
        email: _email,
        code: code,
        role: _role,
      );

      if (!mounted) return;

      if (result == null) {
        setState(() {
          _verifying = false;
          _errorMessage = l10n.somethingWentWrong;
        });
        return;
      }

      final error = result['error']?.toString();
      if (error != null && error.isNotEmpty) {
        _clearingCode = true;
        _codeController.clear();
        _clearingCode = false;
        setState(() {
          _verifying = false;
          _errorMessage = _localizedOtpError(error);
        });
        return;
      }

      // ── reset_password: verify → short-lived reset token → confirm.
      if (_purpose == 'reset_password') {
        final resetToken = result['resetToken']?.toString();
        if (resetToken == null || resetToken.isEmpty) {
          setState(() {
            _verifying = false;
            _errorMessage = l10n.unableResetPassword;
          });
          return;
        }
        final confirm = await VeraApiService.instance.confirmPasswordReset(
          resetToken: resetToken,
          newPassword: _newPasswordController.text,
        );
        if (!mounted) return;
        if (confirm == null ||
            (confirm['error']?.toString().isNotEmpty ?? false)) {
          setState(() {
            _verifying = false;
            _errorMessage =
                confirm?['error']?.toString() ??
                l10n.unableUpdatePassword;
          });
          return;
        }
        setState(() => _verifying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.passwordUpdatedSignIn,
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
        return;
      }

      // ── register_provider: activated, but pending admin approval — no session.
      if (_purpose == 'register_provider') {
        setState(() => _verifying = false);
        _showProviderApprovalDialog();
        return;
      }

      // ── login_buyer/login_provider/register_buyer/change_email_*: the
      // session token was persisted by verifyOtp.
      await VeraApiService.instance.setOnboardingDone();
      if (!mounted) return;
      if (_purpose.endsWith('provider')) {
        context.go(AppRoutes.providerDashboardScreen);
      } else {
        context.go(AppRoutes.homeScreen);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _verifying = false;
          _errorMessage = l10n.somethingWentWrong;
        });
      }
    }
  }

  void _showProviderApprovalDialog() {
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
                size: 30,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.emailVerified,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: AppTheme.charcoal,
              ),
            ),
          ],
        ),
        content: Text(
          l10n.providerApprovalPending,
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            fontSize: 12.5.sp,
            color: AppTheme.grayText,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ctx.pop();
              context.go(AppRoutes.providerLoginScreen);
            },
            child: Text(
              l10n.goToSignIn,
              style: GoogleFonts.cairo(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: AppTheme.goldAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resend() async {
    if (_resending || _resendCooldown > 0) return;
    setState(() {
      _resending = true;
      _errorMessage = null;
    });

    try {
      final result = await VeraApiService.instance.sendOtp(
        purpose: _purpose,
        email: _email,
        role: _role,
      );

      if (!mounted) return;
      setState(() => _resending = false);

      final error = result?['error']?.toString();
      if (error != null && error.isNotEmpty) {
        final retry = (result?['retryAfterSeconds'] as num?)?.toInt();
        setState(() {
          _errorMessage = error;
          if (retry != null && retry > 0) _resendCooldown = retry;
        });
        return;
      }

      final cooldown = (result?['resendCooldownSeconds'] as num?)?.toInt();
      setState(() {
        _resendCooldown = cooldown ?? _resendCooldownSeconds;
        _errorMessage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.t('newCodeSentTo', args: {'email': _email}),
            style: GoogleFonts.cairo(color: Colors.white),
          ),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isProvider = _purpose.endsWith('provider');
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => context.canPop()
                    ? context.pop()
                    : context.go(AppRoutes.loginScreen),
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
              Center(
                child: Container(
                  width: 18.w,
                  height: 18.w,
                  decoration: BoxDecoration(
                    gradient: isProvider
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppTheme.goldAccent, AppTheme.primaryPink],
                          )
                        : AppTheme.primaryGradient,
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
              Center(
                child: Text(
                  _title,
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
                  _subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 13.sp,
                    color: AppTheme.grayText,
                    height: 1.5,
                  ),
                ),
              ),
              SizedBox(height: 4.h),

              // OTP boxes
              _buildOtpInput(),
              SizedBox(height: 2.5.h),

              // Expiry countdown
              Center(
                child: Text(
                  _remaining > 0
                      ? l10n.t('codeExpiresIn', args: {
                          'time': _formatSeconds(_remaining),
                        })
                      : l10n.codeExpired,
                  style: GoogleFonts.cairo(
                    fontSize: 12.sp,
                    color: _remaining > 0
                        ? AppTheme.grayText
                        : AppTheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(height: 2.5.h),

              if (_showPasswordField) ...[
                Text(
                  l10n.newPassword,
                  style: GoogleFonts.cairo(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.charcoal,
                  ),
                ),
                SizedBox(height: 0.8.h),
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _verify(),
                  style: GoogleFonts.cairo(
                    fontSize: 13.sp,
                    color: AppTheme.charcoal,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.min8Characters,
                    hintStyle: GoogleFonts.cairo(
                      fontSize: 13.sp,
                      color: AppTheme.grayText,
                    ),
                    prefixIcon: Icon(
                      Icons.lock_outline_rounded,
                      color: AppTheme.grayText,
                      size: 20,
                    ),
                    suffixIcon: GestureDetector(
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
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
                SizedBox(height: 1.2.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 1.w),
                  child: PasswordRulesChecklist(
                    controller: _newPasswordController,
                  ),
                ),
                SizedBox(height: 2.5.h),
              ],

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

              // Verify button
              SizedBox(
                width: double.infinity,
                height: 6.h,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: isProvider
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.goldAccent,
                              AppTheme.primaryPink,
                            ],
                          )
                        : AppTheme.primaryGradient,
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
                    onPressed: _verifying ? null : _verify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.0),
                      ),
                    ),
                    child: _verifying
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            l10n.verify,
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

              // Resend
              Center(
                child: TextButton(
                  onPressed: _resendCooldown > 0 ? null : _resend,
                  child: _resending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primaryPink,
                          ),
                        )
                      : Text(
                          _resendCooldown > 0
                              ? l10n.t('resendCodeIn', args: {
                                  'seconds': '$_resendCooldown',
                                })
                              : l10n.resendCode,
                          style: GoogleFonts.cairo(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: _resendCooldown > 0
                                ? AppTheme.grayText
                                : AppTheme.primaryPinkDark,
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

  /// A single hidden capture field (handles typing, paste and SMS autofill)
  /// layered under 6 fixed LTR boxes so the digits always read in the correct
  /// order regardless of the app's RTL/LTR direction.
  Widget _buildOtpInput() {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: double.infinity,
          height: 11.w,
          child: TextField(
            controller: _codeController,
            focusNode: _codeFocusNode,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.center,
            enableSuggestions: false,
            autocorrect: false,
            cursorColor: Colors.transparent,
            style: const TextStyle(color: Colors.transparent, fontSize: 1),
            decoration: const InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              counterText: '',
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
            onChanged: _onCodeChanged,
            onSubmitted: (_) => _verify(),
          ),
        ),
        IgnorePointer(
          child: Row(
            textDirection: TextDirection.ltr,
            children: [
              for (var i = 0; i < 6; i++) ...[
                if (i > 0) SizedBox(width: 1.5.w),
                _buildDigitDisplay(i),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDigitDisplay(int index) {
    final text = _codeController.text;
    final char = index < text.length ? text[index] : '';
    final isNext = _codeFocusNode.hasFocus && index == text.length;
    return Container(
      width: 11.w,
      height: 11.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isNext ? AppTheme.primaryPink : AppTheme.borderLight,
          width: isNext ? 2 : 1,
        ),
      ),
      child: Text(
        char,
        textDirection: TextDirection.ltr,
        style: GoogleFonts.cairo(
          fontSize: 20.sp,
          fontWeight: FontWeight.w700,
          color: AppTheme.charcoal,
        ),
      ),
    );
  }
}
