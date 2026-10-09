import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:record/record.dart';

import '../../../core/app_localizations.dart';
import '../../../providers/speech_to_text_notifier.dart';
import '../../../theme/app_theme.dart';

/// Bottom sheet that records the user's speech with the device microphone,
/// transcribes it through the VÉRA STT lambda and reports the recognized
/// text via [onQuery].
class VoiceSearchSheet extends ConsumerStatefulWidget {
  final Function(String) onQuery;

  const VoiceSearchSheet({required this.onQuery, super.key});

  static const sttConfig = SpeechToTextConfig(
    provider: 'OPEN_AI',
    model: 'whisper-1',
  );

  @override
  ConsumerState<VoiceSearchSheet> createState() => _VoiceSearchSheetState();
}

class _VoiceSearchSheetState extends ConsumerState<VoiceSearchSheet>
    with SingleTickerProviderStateMixin {
  AudioRecorder? _recorder;
  bool _isRecording = false;
  bool _isProcessing = false;
  String? _errorText;
  int _elapsedSeconds = 0;
  double _level = 0.0;

  late AnimationController _waveController;
  Timer? _ticker;
  StreamSubscription<Amplitude>? _amplitudeSub;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _startRecording();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _amplitudeSub?.cancel();
    _waveController.dispose();
    _cleanupRecorder();
    super.dispose();
  }

  Future<void> _cleanupRecorder() async {
    final recorder = _recorder;
    if (recorder == null) return;
    try {
      if (await recorder.isRecording()) {
        final path = await recorder.stop();
        if (path != null) {
          try {
            final file = File(path);
            if (await file.exists()) await file.delete();
          } catch (_) {}
        }
      }
      await recorder.dispose();
    } catch (_) {}
    _recorder = null;
  }

  Future<void> _startRecording() async {
    setState(() {
      _isRecording = false;
      _isProcessing = false;
      _errorText = null;
      _elapsedSeconds = 0;
      _level = 0.0;
    });

    final recorder = AudioRecorder();
    try {
      final hasPermission = await recorder.hasPermission();
      if (!hasPermission) {
        setState(() => _errorText = AppLocalizations.of(context).t(
          'micPermissionDenied',
        ));
        return;
      }

      final dir = Directory.systemTemp;
      final path =
          '${dir.path}/vera_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );

      _amplitudeSub = recorder
          .onAmplitudeChanged(const Duration(milliseconds: 100))
          .listen((amp) {
        final normalized = ((amp.current + 60) / 60).clamp(0.0, 1.0);
        if (mounted) setState(() => _level = normalized);
      });

      setState(() {
        _recorder = recorder;
        _isRecording = true;
      });

      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted && _isRecording) {
          setState(() => _elapsedSeconds++);
        }
      });
    } catch (_) {
      setState(() => _errorText = AppLocalizations.of(context).t(
        'voiceSearchFailed',
      ));
    }
  }

  String _formatElapsed() {
    final m = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _stopAndTranscribe() async {
    final recorder = _recorder;
    if (recorder == null) return;

    _ticker?.cancel();
    _amplitudeSub?.cancel();

    String? path;
    try {
      path = await recorder.stop();
      await recorder.dispose();
      _recorder = null;
    } catch (_) {}

    if (path == null) {
      if (mounted) {
        setState(() {
          _isRecording = false;
          _errorText = AppLocalizations.of(context).t('voiceSearchFailed');
        });
      }
      return;
    }

    setState(() {
      _isRecording = false;
      _isProcessing = true;
    });

    try {
      final bytes = await File(path).readAsBytes();
      final result = await ref
          .read(speechToTextNotifierProvider(VoiceSearchSheet.sttConfig).notifier)
          .transcribe(
            bytes,
            'vera_voice_${DateTime.now().millisecondsSinceEpoch}.m4a',
          );

      if (!mounted) return;

      final text = result?['text']?.toString().trim() ?? '';
      if (text.isNotEmpty) {
        Navigator.pop(context);
        widget.onQuery(text);
      } else {
        setState(() {
          _isProcessing = false;
          _errorText = AppLocalizations.of(context).t('voiceSearchFailed');
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorText = AppLocalizations.of(context).t('voiceSearchFailed');
        });
      }
    } finally {
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
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
            const SizedBox(height: 24),

            if (_isProcessing) ...[
              const SizedBox(height: 20),
              const SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppTheme.primaryPink,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.processingVoice,
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.charcoal,
                ),
              ),
            ] else if (_errorText != null) ...[
              const SizedBox(height: 20),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.tintRed,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mic_off_rounded,
                  color: AppTheme.error,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _errorText!,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.charcoal,
                ),
              ),
            ] else ...[
              // Live mic with real amplitude-driven ripple
              AnimatedBuilder(
                animation: _waveController,
                builder: (_, child) {
                  final ripple =
                      80 + (_level * 40) + (_waveController.value * 12);
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: ripple,
                        height: ripple,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryPink.withAlpha(
                            (20 * (1 - _waveController.value)).toInt(),
                          ),
                        ),
                      ),
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryPink.withAlpha(80),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.mic_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              Text(
                l10n.t('listening'),
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.charcoal,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${l10n.t('speakSearchQuery')} · ${_formatElapsed()}',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: AppTheme.grayText,
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _stopAndTranscribe,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.error,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.error.withAlpha(70),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.stop_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.tapToStop,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: AppTheme.grayText,
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Bottom actions
            if (_errorText != null)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.grayText,
                        side: BorderSide(color: AppTheme.borderLight),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size(0, 44),
                      ),
                      child: Text(
                        l10n.cancel,
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _startRecording,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryPink,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size(0, 44),
                      ),
                      child: Text(
                        l10n.t('retry'),
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.grayText,
                        side: BorderSide(color: AppTheme.borderLight),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size(0, 44),
                      ),
                      child: Text(
                        l10n.cancel,
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_isRecording) {
                          _stopAndTranscribe();
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryPink,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size(0, 44),
                      ),
                      child: Text(
                        l10n.search,
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
