import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/aiIntegrations/speech_to_text_service.dart';

class SpeechToTextConfig {
  final String provider;
  final String model;

  const SpeechToTextConfig({required this.provider, required this.model});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpeechToTextConfig &&
          provider == other.provider &&
          model == other.model;

  @override
  int get hashCode => provider.hashCode ^ model.hashCode;
}

class SpeechToTextState {
  final String? text;
  final Map<String, dynamic>? fullResponse;
  final bool isLoading;
  final Exception? error;

  const SpeechToTextState({
    this.text,
    this.fullResponse,
    this.isLoading = false,
    this.error,
  });

  SpeechToTextState copyWith({
    String? text,
    Map<String, dynamic>? fullResponse,
    bool? isLoading,
    Exception? error,
    bool clearError = false,
    bool clearResult = false,
  }) {
    return SpeechToTextState(
      text: clearResult ? null : (text ?? this.text),
      fullResponse: clearResult ? null : (fullResponse ?? this.fullResponse),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class SpeechToTextNotifier extends StateNotifier<SpeechToTextState> {
  final String provider;
  final String model;

  SpeechToTextNotifier({required this.provider, required this.model})
    : super(const SpeechToTextState());

  Future<Map<String, dynamic>?> transcribe(
    Uint8List fileBytes,
    String filename, {
    Map<String, dynamic> parameters = const {},
  }) async {
    state = const SpeechToTextState(isLoading: true);
    try {
      final result = await transcribeAudio(
        provider,
        model,
        fileBytes,
        filename,
        parameters: parameters,
      );
      state = SpeechToTextState(
        text: result['text'] as String?,
        fullResponse: result,
        isLoading: false,
      );
      return result;
    } catch (error) {
      state = SpeechToTextState(
        error: error is Exception ? error : Exception(error.toString()),
        isLoading: false,
      );
      return null;
    }
  }

  void clearResult() => state = const SpeechToTextState();
}

final speechToTextNotifierProvider =
    StateNotifierProvider.family<
      SpeechToTextNotifier,
      SpeechToTextState,
      SpeechToTextConfig
    >(
      (ref, config) =>
          SpeechToTextNotifier(provider: config.provider, model: config.model),
    );
