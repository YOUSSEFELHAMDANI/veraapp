import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sizer/sizer.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_image_widget.dart';
import '../../core/app_localizations.dart';
import '../../routes/app_routes.dart';
import '../../core/auth_gate.dart';
import '../../services/vera_api_service.dart';

class ApplyJobScreen extends StatefulWidget {
  final Map<String, dynamic>? jobData;
  const ApplyJobScreen({super.key, this.jobData});

  @override
  State<ApplyJobScreen> createState() => _ApplyJobScreenState();
}

class _ApplyJobScreenState extends State<ApplyJobScreen> with AuthGuard {
  int _currentStep = 0; // 0=Resume, 1=Details, 2=Review, 3=Submit

  // Form controllers
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _coverLetterController = TextEditingController();
  String? _noticePeriod;
  String? _selectedResume;
  bool _isSubmitting = false;

  final List<String> _noticePeriods = [
    'Immediately',
    '2 Weeks',
    '30 Days',
    '60 Days',
    '90 Days',
  ];

  Map<String, dynamic> get _job =>
      widget.jobData ??
      const {
        'title': '',
        'company': '',
        'location': '',
        'logo': '',
      };

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _coverLetterController.dispose();
    super.dispose();
  }

  final List<IconData> _stepIcons = [
    Icons.description_outlined,
    Icons.person_outline_rounded,
    Icons.rate_review_outlined,
    Icons.send_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return authPlaceholder(_buildGuardedContent(context));
  }

  Widget _buildGuardedContent(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    _noticePeriod ??= l10n.t('notice30Days');
    final stepLabels = [
      l10n.t('resumeStep'),
      l10n.t('detailsStep'),
      l10n.t('reviewStep'),
      l10n.t('submitStep'),
    ];
    final noticePeriods = [
      l10n.t('noticeImmediately'),
      l10n.t('notice2Weeks'),
      l10n.t('notice30Days'),
      l10n.t('notice60Days'),
      l10n.t('notice90Days'),
    ];
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundLight,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: AppTheme.charcoal,
            ),
          ),
        ),
        title: Text(
          l10n.t('applyForJob'),
          style: GoogleFonts.cairo(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoal,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildJobHeader(l10n),
          _buildStepIndicator(stepLabels),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              child: _buildCurrentStep(l10n, noticePeriods),
            ),
          ),
          _buildBottomBar(l10n),
        ],
      ),
    );
  }

  Widget _buildJobHeader(AppLocalizations l10n) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: CustomImageWidget(
              imageUrl: _job['logo'] as String,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              semanticLabel: l10n.companyLogoLabel(_job['company'] as String),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _job['title'] as String,
                  style: GoogleFonts.cairo(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.charcoal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${_job['company']} – ${_job['location']}',
                  style: GoogleFonts.cairo(
                    fontSize: 11.sp,
                    color: AppTheme.grayText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(List<String> stepLabels) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.5.h),
      child: Row(
        children: List.generate(stepLabels.length, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? AppTheme.success
                              : isActive
                              ? AppTheme.primaryPink
                              : AppTheme.ivoryLight,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isActive
                                ? AppTheme.primaryPink
                                : AppTheme.borderLight,
                            width: isActive ? 2 : 1,
                          ),
                        ),
                        child: Icon(
                          isCompleted ? Icons.check_rounded : _stepIcons[index],
                          size: 18,
                          color: isCompleted || isActive
                              ? Colors.white
                              : AppTheme.grayText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stepLabels[index],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(
                          fontSize: 9.sp,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isActive
                              ? AppTheme.primaryPinkDark
                              : AppTheme.grayText,
                        ),
                      ),
                    ],
                  ),
                ),
                if (index < stepLabels.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 20),
                      color: index < _currentStep
                          ? AppTheme.success
                          : AppTheme.borderLight,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep(AppLocalizations l10n, List<String> noticePeriods) {
    switch (_currentStep) {
      case 0:
        return _buildResumeStep(l10n);
      case 1:
        return _buildDetailsStep(l10n, noticePeriods);
      case 2:
        return _buildReviewStep(l10n);
      case 3:
        return _buildSubmitStep(l10n);
      default:
        return _buildResumeStep(l10n);
    }
  }

  Widget _buildResumeStep(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.t('selectResume'),
          style: GoogleFonts.cairo(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoal,
          ),
        ),
        SizedBox(height: 1.5.h),
        if (_selectedResume != null)
          _buildResumeOption(_selectedResume!, l10n.t('selected')),
        SizedBox(height: 1.5.h),
        OutlinedButton.icon(
          onPressed: () async {
            final result = await FilePicker.platform.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['pdf', 'doc', 'docx'],
            );
            if (result != null && result.files.isNotEmpty) {
              final file = result.files.first;
              setState(() => _selectedResume = file.name);
            }
          },
          icon: const Icon(Icons.upload_file_rounded, size: 18),
          label: Text(
            l10n.t('uploadNewCv'),
            style: GoogleFonts.cairo(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primaryPinkDark,
            side: const BorderSide(color: AppTheme.primaryPink),
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResumeOption(String name, String subtitle) {
    final isSelected = _selectedResume == name;
    return GestureDetector(
      onTap: () => setState(() => _selectedResume = name),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryPinkLight : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isSelected ? AppTheme.primaryPink : AppTheme.borderLight,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryPink : AppTheme.ivoryLight,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Icon(
                Icons.description_rounded,
                size: 20,
                color: isSelected ? Colors.white : AppTheme.grayText,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.cairo(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.charcoal,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.cairo(
                      fontSize: 11.sp,
                      color: AppTheme.grayText,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppTheme.primaryPink,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsStep(AppLocalizations l10n, List<String> noticePeriods) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.t('personalInformation'),
          style: GoogleFonts.cairo(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoal,
          ),
        ),
        SizedBox(height: 1.5.h),
        _buildTextField(
          l10n.fullName,
          _fullNameController,
          Icons.person_outline_rounded,
        ),
        _buildTextField(
          l10n.email,
          _emailController,
          Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        _buildTextField(
          l10n.phoneNumber,
          _phoneController,
          Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        _buildTextField(
          l10n.location,
          _locationController,
          Icons.location_on_outlined,
        ),
        SizedBox(height: 0.5.h),
        Text(
          l10n.t('noticePeriod'),
          style: GoogleFonts.cairo(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: AppTheme.grayText,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
               value: _noticePeriod!,
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppTheme.grayText,
              ),
              style: GoogleFonts.cairo(
                fontSize: 13.sp,
                color: AppTheme.charcoal,
              ),
              items: noticePeriods
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (val) => setState(() => _noticePeriod = val!),
            ),
          ),
        ),
        SizedBox(height: 1.5.h),
        Text(
          l10n.t('coverLetterOptional'),
          style: GoogleFonts.cairo(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: AppTheme.grayText,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _coverLetterController,
          maxLines: 5,
          maxLength: 1000,
          style: GoogleFonts.cairo(fontSize: 12.sp, color: AppTheme.charcoal),
          decoration: InputDecoration(
            hintText: l10n.t('coverLetterHint'),
            hintStyle: GoogleFonts.cairo(
              fontSize: 12.sp,
              color: AppTheme.grayText,
            ),
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
            filled: true,
            fillColor: AppTheme.surfaceLight,
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: AppTheme.grayText,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: GoogleFonts.cairo(
              fontSize: 13.sp,
              color: AppTheme.charcoal,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 18, color: AppTheme.grayText),
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
              filled: true,
              fillColor: AppTheme.surfaceLight,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.t('reviewApplication'),
          style: GoogleFonts.cairo(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoal,
          ),
        ),
        SizedBox(height: 1.5.h),
        _buildReviewSection(l10n.t('resumeStep'), [
          {'label': l10n.t('fileLabel'),
                       'value': _selectedResume ?? l10n.t('notSelected')},
        ]),
        _buildReviewSection(l10n.t('personalInformation'), [
          {'label': l10n.fullName, 'value': _fullNameController.text},
          {'label': l10n.email, 'value': _emailController.text},
          {'label': l10n.phoneNumber, 'value': _phoneController.text},
          {'label': l10n.location, 'value': _locationController.text},
          {'label': l10n.t('noticePeriod'), 'value': _noticePeriod ?? ''},
        ]),
        if (_coverLetterController.text.isNotEmpty)
          _buildReviewSection(l10n.t('coverLetterStep'), [
            {'label': l10n.t('messageLabel'), 'value': _coverLetterController.text},
          ]),
      ],
    );
  }

  Widget _buildReviewSection(String title, List<Map<String, String>> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.charcoal,
            ),
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 30.w,
                    child: Text(
                      item['label']!,
                      style: GoogleFonts.cairo(
                        fontSize: 11.sp,
                        color: AppTheme.grayText,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item['value']!,
                      style: GoogleFonts.cairo(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.charcoal,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitStep(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 4.h),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppTheme.primaryPinkLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppTheme.primaryPinkDark,
              size: 56,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            l10n.t('applicationSubmitted'),
            style: GoogleFonts.cairo(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.charcoal,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            l10n.t('applicationSubmittedMessage', args: {
              'title': _job['title'] as String,
              'company': _job['company'] as String,
            }),
            style: GoogleFonts.cairo(
              fontSize: 12.sp,
              color: AppTheme.grayText,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 3.h),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => context.push(AppRoutes.myApplicationsScreen),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPink,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              child: Text(
                l10n.t('viewMyApplications'),
                style: GoogleFonts.cairo(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () => context.go(AppRoutes.jobsScreen),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryPinkDark,
                side: const BorderSide(color: AppTheme.primaryPink),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              child: Text(
                l10n.t('browseMoreJobs'),
                style: GoogleFonts.cairo(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(AppLocalizations l10n) {
    if (_currentStep == 3) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.fromLTRB(4.w, 1.h, 4.w, 3.h),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        border: Border(top: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep--),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.charcoal,
                  side: BorderSide(color: AppTheme.borderLight),
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: Text(
                  l10n.back,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        if (_currentStep < 2) {
                          setState(() => _currentStep++);
                        } else {
                          setState(() { _isSubmitting = true; });
                          final jobId = _job['id']?.toString() ?? _job['serviceId']?.toString() ?? '';
                          final result = await VeraApiService.instance.applyForJob(
                            jobId: jobId,
                            fullName: _fullNameController.text.trim(),
                            email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
                            phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
                            location: _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : null,
                            coverLetter: _coverLetterController.text.trim().isNotEmpty ? _coverLetterController.text.trim() : null,
                            noticePeriod: _noticePeriod,
                          );
                          if (mounted) {
                            setState(() { _isSubmitting = false; });
                            if (result != null && (result['success'] == true || result['application_id'] != null)) {
                              setState(() { _currentStep = 3; });
                            } else {
                              final error = result?['error']?.toString() ?? 'Failed to submit. Please try again.';
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(error), backgroundColor: Colors.red),
                              );
                            }
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPink,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _currentStep == 2
                            ? l10n.t('submitApplication')
                            : l10n.next,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
