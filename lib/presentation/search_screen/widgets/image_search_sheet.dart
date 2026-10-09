import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_localizations.dart';
import '../../../providers/chat_notifier.dart';
import '../../../theme/app_theme.dart';

/// Chat configuration used to turn an image into a search query.
const chatImageSearchConfig = ChatConfig(
  provider: 'OPEN_AI',
  model: 'gpt-4o-mini',
  streaming: false,
);

/// Picks an image from [source] and asks the AI to describe it as a search
/// query. The generated query is delivered through the
/// [chatImageSearchConfig] notifier, which the caller listens to.
Future<void> pickAndAnalyzeImage(
  BuildContext context,
  WidgetRef ref,
  ImageSource source,
) async {
  try {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    final ext = file.name.split('.').last.toLowerCase();
    final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';
    final dataUri = 'data:$mimeType;base64,${base64Encode(bytes)}';

    ref.read(chatNotifierProvider(chatImageSearchConfig).notifier).sendMessage(
          [
            {
              'role': 'system',
              'content':
                  'You are a visual search assistant for VÉRA, a Gulf marketplace. Analyze the image and generate a short, specific search query (max 8 words) that describes what the user might be looking for. Only return the search query text, nothing else.',
            },
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': 'What should I search for based on this image?',
                },
                {
                  'type': 'image_url',
                  'image_url': {'url': dataUri, 'detail': 'low'},
                },
              ],
            },
          ],
          parameters: {'max_completion_tokens': 50},
        );
  } catch (_) {
    if (context.mounted) {
      Fluttertoast.showToast(
        msg: AppLocalizations.of(context).t('couldNotPickImage'),
        backgroundColor: Colors.red,
        toastLength: Toast.LENGTH_SHORT,
      );
    }
  }
}

/// Bottom sheet that asks the user where the image should come from:
/// the camera or the gallery.
class ImageSourceSheet extends StatelessWidget {
  final ValueChanged<ImageSource> onChoose;

  const ImageSourceSheet({super.key, required this.onChoose});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.chooseImageSource,
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.charcoal,
            ),
          ),
          const SizedBox(height: 8),
          _sourceTile(
            icon: Icons.photo_camera_outlined,
            label: l10n.takePhoto,
            onTap: () => onChoose(ImageSource.camera),
          ),
          _sourceTile(
            icon: Icons.photo_library_outlined,
            label: l10n.chooseFromGallery,
            onTap: () => onChoose(ImageSource.gallery),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _sourceTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.2.h),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryPinkLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: AppTheme.primaryPinkDark),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.charcoal,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_left_rounded,
              size: 20,
              color: AppTheme.grayText,
            ),
          ],
        ),
      ),
    );
  }
}
