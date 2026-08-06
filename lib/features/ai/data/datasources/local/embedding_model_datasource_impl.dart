import 'package:flutter/services.dart';

import '../../models/minilm/minilm_model_config.dart';
import 'embedding_model_datasource.dart';

/// Asset-bundle backed implementation of [EmbeddingModelDataSource].
///
/// Reads `assets/models/minilm/model.tflite` and
/// `assets/models/minilm/vocab.txt` from the bundled assets. These files are
/// not part of the repository yet and will be added later.
class AssetEmbeddingModelDataSource implements EmbeddingModelDataSource {
  final AssetBundle _bundle;

  AssetEmbeddingModelDataSource({AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  @override
  Future<Uint8List> loadModelBytes() async {
    final data = await _bundle.load(MiniLmModelConfig.modelAssetPath);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  @override
  Future<String> loadVocabulary() async {
    return _bundle.loadString(MiniLmModelConfig.vocabAssetPath);
  }
}
