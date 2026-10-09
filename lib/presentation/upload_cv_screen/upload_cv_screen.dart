import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sizer/sizer.dart';
import '../../theme/app_theme.dart';
import '../../core/app_localizations.dart';
import '../../core/auth_gate.dart';
import '../../services/vera_api_service.dart';

class UploadCvScreen extends StatefulWidget {
  const UploadCvScreen({super.key});

  @override
  State<UploadCvScreen> createState() => _UploadCvScreenState();
}

class _UploadCvScreenState extends State<UploadCvScreen> with AuthGuard {
  final bool _isDragging = false;
  String? _uploadedFileName;
  bool _isUploading = false;

  final List<Map<String, dynamic>> _cvTips = [
    {'text': 'Keep it updated', 'icon': Icons.check_circle_outline_rounded},
    {
      'text': 'Highlight your skills',
      'icon': Icons.check_circle_outline_rounded,
    },
    {
      'text': 'Use clear formatting',
      'icon': Icons.check_circle_outline_rounded,
    },
    {
      'text': 'Add relevant experience',
      'icon': Icons.check_circle_outline_rounded,
    },
  ];

  String? _uploadedFilePath;

  Future<void> _pickAndUploadCV() async {
    final l10n = AppLocalizations.of(context);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.path == null) return;
      setState(() { _isUploading = true; _uploadedFileName = file.name; _uploadedFilePath = null; });
      final url = await VeraApiService.instance.uploadDocument(file.path!);
      if (mounted) {
        setState(() { _isUploading = false; _uploadedFilePath = url; });
        if (url != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.t('cvUploadedSuccessfully')), backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0))),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload failed. Please try again.'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0))),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return authPlaceholder(_buildGuardedContent(context));
  }

  Widget _buildGuardedContent(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cvTips = [
      {'text': l10n.t('cvTipKeepUpdated'), 'icon': Icons.check_circle_outline_rounded},
      {'text': l10n.t('cvTipHighlightSkills'), 'icon': Icons.check_circle_outline_rounded},
      {'text': l10n.t('cvTipClearFormatting'), 'icon': Icons.check_circle_outline_rounded},
      {'text': l10n.t('cvTipRelevantExperience'), 'icon': Icons.check_circle_outline_rounded},
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
          l10n.uploadCv,
          style: GoogleFonts.cairo(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoal,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDropZone(l10n),
            SizedBox(height: 2.h),
            _buildUploadButton(l10n),
            SizedBox(height: 2.h),
            _buildDivider(l10n),
            SizedBox(height: 2.h),
            _buildCreateProfile(l10n),
            SizedBox(height: 3.h),
            _buildCvTips(cvTips, l10n),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildDropZone(AppLocalizations l10n) {
    return GestureDetector(
      onTap: _pickAndUploadCV,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 4.h),
        decoration: BoxDecoration(
          color: _isDragging
              ? AppTheme.primaryPinkLight
              : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: _isDragging ? AppTheme.primaryPink : AppTheme.borderLight,
            width: _isDragging ? 2 : 1,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isUploading)
              const CircularProgressIndicator(color: AppTheme.primaryPink)
            else if (_uploadedFileName != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPinkLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.description_rounded,
                  color: AppTheme.primaryPinkDark,
                  size: 36,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _uploadedFileName!,
                style: GoogleFonts.cairo(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.charcoal,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.t('tapToChangeFile'),
                style: GoogleFonts.cairo(
                  fontSize: 11.sp,
                  color: AppTheme.grayText,
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPinkLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cloud_upload_outlined,
                  color: AppTheme.primaryPinkDark,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.t('dragDropCvHere'),
                style: GoogleFonts.cairo(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.charcoal,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.t('orBrowseFiles'),
                style: GoogleFonts.cairo(
                  fontSize: 13.sp,
                  color: AppTheme.grayText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.t('pdfDocDocxMax5Mb'),
                style: GoogleFonts.cairo(
                  fontSize: 11.sp,
                  color: AppTheme.grayLight,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUploadButton(AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _pickAndUploadCV,
        icon: const Icon(Icons.upload_file_rounded, size: 20),
        label: Text(
          l10n.uploadCv,
          style: GoogleFonts.cairo(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryPink,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(child: Divider(color: AppTheme.borderLight)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            l10n.t('orCreateYourProfile'),
            style: GoogleFonts.cairo(
              fontSize: 12.sp,
              color: AppTheme.grayText,
            ),
          ),
        ),
        Expanded(child: Divider(color: AppTheme.borderLight)),
      ],
    );
  }

  Widget _buildCreateProfile(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.t('letEmployersFindYou'),
          style: GoogleFonts.cairo(fontSize: 12.sp, color: AppTheme.grayText),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryPinkDark,
              side: const BorderSide(color: AppTheme.primaryPink, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            child: Text(
              l10n.t('createProfile'),
              style: GoogleFonts.cairo(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCvTips(
      List<Map<String, dynamic>> cvTips, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.t('tipsForGreatCv'),
          style: GoogleFonts.cairo(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoal,
          ),
        ),
        SizedBox(height: 1.5.h),
        ...cvTips.map(
          (tip) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.success,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  tip['text'] as String,
                  style: GoogleFonts.cairo(
                    fontSize: 13.sp,
                    color: AppTheme.charcoal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
