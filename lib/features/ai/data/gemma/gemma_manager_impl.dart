import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_mediapipe/flutter_gemma_mediapipe.dart';
import '../../domain/services/gemma/gemma_manager.dart';
import 'gemma_model_config.dart';

/// `flutter_gemma`-backed implementation of [GemmaManager].
///
/// The core `flutter_gemma` package registers no inference engine on its own.
/// To actually run inference, add an engine package (for example
/// `flutter_gemma_mediapipe` for `.task`/`.bin` models or
/// `flutter_gemma_litertlm` for `.litertlm` models) and pass its provider to
/// `FlutterGemma.initialize(...)` before calling [initialize].
class GemmaManagerImpl implements GemmaManager {
  GemmaManagerImpl({required this.config});

  final GemmaModelConfig config;

  InferenceModel? _model;
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    await FlutterGemma.initialize(
      inferenceEngines: [MediaPipeEngine()],
      huggingFaceToken: config.huggingFaceToken,
    );
    _initialized = true;

    if (FlutterGemma.hasActiveModel()) {
      await _getActiveModel();
    }
  }

  @override
  Future<void> downloadModel({
    required String url,
    void Function(int progress)? onProgress,
  }) async {
    await _ensureInitialized();

    final builder = FlutterGemma.installModel(
      modelType: config.modelType,
      fileType: config.fileType,
    ).fromNetwork(url);

    if (onProgress != null) {
      builder.withProgress(onProgress);
    }

    await builder.install();
  }

  @override
  Future<bool> isModelDownloaded({required String modelId}) async {
    await _ensureInitialized();

    return FlutterGemma.isModelInstalled(modelId);
  }

  @override
  Future<Stream<String>> generateResponse(String prompt) async {
    if (!FlutterGemma.hasActiveModel()) {
      final defaultUrl = config.defaultModelUrl;
      if (defaultUrl == null) {
        throw StateError(
          'No AI model installed yet and no default model URL is configured. '
          'Please set a defaultModelUrl in GemmaModelConfig or download a model first.',
        );
      }
      await downloadModel(url: defaultUrl);
    }

    final model = await _getActiveModel();
    final chat = await model.createChat();
    await chat.addQueryChunk(Message.text(text: prompt, isUser: true));

    return chat
        .generateChatResponseAsync()
        .map((response) {
          if (response is TextResponse && response.token.isNotEmpty) {
            return response.token;
          }
          return '';
        })
        .where((token) => token.isNotEmpty);
  }

  @override
  Future<void> dispose() async {
    final model = _model;
    _model = null;

    await model?.close();
    await FlutterGemma.dispose();
    _initialized = false;
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }

  Future<InferenceModel> _getActiveModel() async {
    final existing = _model;
    if (existing != null) return existing;

    final model = await FlutterGemma.getActiveModel(
      maxTokens: config.maxTokens,
    );
    _model = model;
    return model;
  }
}
