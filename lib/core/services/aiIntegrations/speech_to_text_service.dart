import 'dart:convert';
import 'dart:typed_data';
import '../ai_client.dart';

const String _speechToTextEndpoint = String.fromEnvironment(
  'AWS_LAMBDA_SPEECH_TO_TEXT_URL',
);

/// Transcribe audio bytes via the Lambda STT endpoint.
///
/// `filename` must include an extension (e.g. `speech.mp3`, `rec_123.m4a`);
/// the provider uses it to identify the audio format.
Future<Map<String, dynamic>> transcribeAudio(
  String provider,
  String model,
  Uint8List fileBytes,
  String filename, {
  Map<String, dynamic> parameters = const {},
}) async {
  final payload = <String, dynamic>{
    'provider': provider,
    'model': model,
    'file': base64Encode(fileBytes),
    'filename': filename,
    'parameters': parameters,
  };
  return await callLambdaFunction(_speechToTextEndpoint, payload);
}
