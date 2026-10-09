import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_localizations.dart';
import '../../../providers/chat_notifier.dart';
import '../../../theme/app_theme.dart';
import 'image_search_sheet.dart';
import 'voice_search_sheet.dart';

/// The dedicated "Smart Search" entry point. Keeps the AI-powered ways to
/// search (voice and image) clearly separated from the normal text search.
class SmartSearchCard extends ConsumerStatefulWidget {
  final ValueChanged<String> onQuery;

  const SmartSearchCard({required this.onQuery, super.key});

  @override
  ConsumerState<SmartSearchCard> createState() => _SmartSearchCardState();
}

class _SmartSearchCardState extends ConsumerState<SmartSearchCard> {
  bool _isPicking = false;

  Future<void> _openVoiceSearch() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: VoiceSearchSheet(onQuery: widget.onQuery),
      ),
    );
  }

  Future<void> _openImageSearch() async {
    if (_isPicking) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => ImageSourceSheet(
        onChoose: (source) async {
          Navigator.pop(sheetContext);
          setState(() => _isPicking = true);
          await pickAndAnalyzeImage(context, ref, source);
          if (mounted) setState(() => _isPicking = false);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    ref.listen<ChatState>(chatNotifierProvider(chatImageSearchConfig), (
      prev,
      next,
    ) {
      if (next.error != null) {
        Fluttertoast.showToast(
          msg: l10n.t('imageAnalysisFailed'),
          backgroundColor: Colors.red,
          toastLength: Toast.LENGTH_SHORT,
        );
      }
      if (!next.isLoading &&
          next.response.isNotEmpty &&
          prev?.isLoading == true) {
        widget.onQuery(next.response.trim());
      }
    });

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.aiGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryPink.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight.withAlpha(200),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 18,
                  color: AppTheme.primaryPinkDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.smartSearch,
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.charcoal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.smartSearchSubtitle,
                      style: GoogleFonts.cairo(
                        fontSize: 11.5,
                        color: AppTheme.grayText,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  icon: Icons.mic_rounded,
                  label: l10n.searchWithVoice,
                  onTap: _openVoiceSearch,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _actionButton(
                  icon: Icons.camera_alt_outlined,
                  label: l10n.searchWithImage,
                  isLoading: _isPicking,
                  onTap: _openImageSearch,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primaryPink.withAlpha(50)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primaryPinkDark,
                ),
              )
            else
              Icon(icon, size: 18, color: AppTheme.primaryPinkDark),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.charcoal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
