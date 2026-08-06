import 'package:expense_flow_app/features/ai/domain/entities/encoded_sequence.dart';
import 'package:expense_flow_app/features/ai/domain/services/embedding/embedding_model.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../../datasources/local/embedding_model_datasource.dart';
import '../minilm/minilm_model_config.dart';

/// TensorFlow Lite implementation of [EmbeddingModel] for MiniLM.
///
/// Loads the graph from the bundled `assets/models/minilm/model.tflite`
/// asset and (once the model file is added) runs the forward pass to
/// produce sentence embeddings.
///
/// The inference itself is intentionally a placeholder: it throws
/// [UnimplementedError] until the model graph is added and the tensor
/// plumbing is wired up.
class TfliteMiniLmEmbeddingModel implements EmbeddingModel {
  TfliteMiniLmEmbeddingModel(this._dataSource);

  final EmbeddingModelDataSource _dataSource;

  Interpreter? _interpreter;

  @override
  int get embeddingSize => MiniLmModelConfig.embeddingSize;

  @override
  int get maxSequenceLength => MiniLmModelConfig.maxSequenceLength;

  @override
  Future<void> load() async {
    if (_interpreter != null) return;

    final modelBytes = await _dataSource.loadModelBytes();

    _interpreter = Interpreter.fromBuffer(modelBytes);
  }

  @override
  Future<List<double>> embed(EncodedSequence encodedText) async {
    throw UnimplementedError(
      'MiniLM embedding inference is not implemented yet. '
      'Run the TensorFlow Lite forward pass once '
      '${MiniLmModelConfig.modelAssetPath} is added.',
    );
  }

  /// Releases the loaded interpreter. Safe to call when nothing is loaded.
  Future<void> dispose() async {
    final interpreter = _interpreter;
    _interpreter = null;
    interpreter?.close();
  }
}
