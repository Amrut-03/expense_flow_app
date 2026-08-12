/// Contract for managing the on-device Gemma model lifecycle.
///
/// Implementations wrap the `flutter_gemma` plugin and keep the concrete
/// package out of the domain and presentation layers. Callers never build
/// prompts here; they pass a ready-to-use prompt string.
abstract interface class GemmaManager {
  /// Initialises the Gemma runtime and preloads the active model when one is
  /// installed. Safe to call repeatedly.
  Future<void> initialize();

  /// Downloads and installs the model from [url], making it the active model.
  ///
  /// [onProgress], when provided, reports download progress as a percentage.
  Future<void> downloadModel({
    required String url,
    void Function(int progress)? onProgress,
  });

  /// Returns whether the model identified by [modelId] is installed.
  Future<bool> isModelDownloaded({required String modelId});

  /// Streams the model's token-by-token response for [prompt].
  ///
  /// [systemInstruction], when provided, is sent as the model's system
  /// message so the model treats it as authoritative context (for example
  /// "answer only from the data below"). The stream completes when
  /// generation finishes.
  Future<Stream<String>> generateResponse(
    String prompt, {
    String? systemInstruction,
  });

  /// Releases the loaded model and resets the Gemma runtime.
  Future<void> dispose();
}
