import 'package:flutter_gemma/flutter_gemma.dart';

/// Identity of the Gemma model the manager downloads and runs.
class GemmaModelConfig {
  /// Architecture of the model (chat instruct variant).
  final ModelType modelType;

  /// Format of the model file (for example `.task`).
  final ModelFileType fileType;

  /// Maximum number of output tokens per response.
  final int maxTokens;

  /// Default model URL used when no model is installed and one is needed.
  final String? defaultModelUrl;

  /// HuggingFace token for [defaultModelUrl] when it points to a gated model.
  ///
  /// Only needed for gated repos. The default on-device model
  /// (`functiongemma-270M-it.task`) is public, so this is `null`. Never
  /// commit a real token.
  final String? huggingFaceToken;

  const GemmaModelConfig({
    this.modelType = ModelType.gemmaIt,
    this.fileType = ModelFileType.task,
    this.maxTokens = 1024,
    this.defaultModelUrl,
    this.huggingFaceToken,
  });
}
