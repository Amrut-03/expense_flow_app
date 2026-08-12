import 'dart:math' as math;
import 'dart:typed_data';

import 'package:expense_flow_app/features/ai/domain/entities/encoded_sequence.dart';
import 'package:expense_flow_app/features/ai/domain/services/embedding/embedding_model.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../../datasources/local/embedding_model_datasource.dart';
import '../minilm/minilm_model_config.dart';

/// TensorFlow Lite implementation of [EmbeddingModel] for MiniLM.
///
/// Loads the graph from the bundled `assets/models/minilm/model.tflite`
/// asset and runs the forward pass to produce sentence embeddings.
///
/// The model is expected to expose either a final pooled vector (output
/// shape `[1, 384]`) or the last hidden states (output shape
/// `[1, 128, 384]`); in the latter case the embedding is mean-pooled over
/// the non-padded positions and L2-normalised, matching the standard
/// sentence-transformers post-processing for all-MiniLM-L6-v2.
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

    final Uint8List modelBytes;
    try {
      modelBytes = await _dataSource.loadModelBytes();
    } catch (error) {
      throw StateError(
        'MiniLM model asset not found at ${MiniLmModelConfig.modelAssetPath}. '
        'Bundle the model file to enable semantic retrieval. ($error)',
      );
    }

    try {
      _interpreter = Interpreter.fromBuffer(modelBytes);
    } catch (error) {
      throw StateError(
        'Failed to initialise the MiniLM TensorFlow Lite interpreter: $error',
      );
    }
  }

  @override
  Future<List<double>> embed(EncodedSequence encodedText) async {
    final interpreter = _interpreter;
    if (interpreter == null) {
      throw StateError('MiniLM model is not loaded. Call load() before embed().');
    }

    // The bundled graph (all-MiniLM-L6-v2) exposes two `[1, seqLen]` INT32
    // inputs: `input_ids` (token ids) and `attention_mask` (1 for real tokens,
    // 0 for padding). Both are declared with a placeholder shape `[1, 1]`;
    // tflite_flutter resizes each input tensor to the shape of the supplied
    // nested list, so we wrap the fixed-length sequences as `[1, maxTokens]`.
    final inputs = <Object>[
      [encodedText.inputIds],
      [encodedText.attentionMask],
    ];

    final outputShape = interpreter.getOutputTensor(0).shape;
    final output = _allocateOutput(outputShape);

    interpreter.runForMultipleInputs(inputs, {0: output});

    return _toVector(output, outputShape, encodedText.attentionMask);
  }

  /// Builds a nested list matching [shape] so the interpreter can write the
  /// output tensor in place (e.g. `[1, 384]` -> one row of 384 zeros).
  List<dynamic> _allocateOutput(List<int> shape) {
    if (shape.length <= 1) {
      return List<double>.filled(shape.isEmpty ? 0 : shape[0], 0.0);
    }
    return [
      for (var i = 0; i < shape[0]; i++) _allocateOutput(shape.sublist(1)),
    ];
  }

  /// Extracts a `[embeddingSize]` vector from the raw output tensor.
  ///
  /// * `[1, hidden]`/`[hidden]` output is used directly.
  /// * `[1, seqLen, hidden]` output is mean-pooled over the non-padded
  ///   positions (padding is tracked by [attentionMask]) and normalised.
  List<double> _toVector(
    List<dynamic> output,
    List<int> shape,
    List<int> attentionMask,
  ) {
    if (shape.length <= 2) {
      final row = output.length == 1 ? output[0] as List : output;
      return _normalize(
        row.map((e) => (e as num).toDouble()).toList(),
      );
    }

    final seqLen = shape[1];
    final hidden = shape[2];
    final pooled = List<double>.filled(hidden, 0.0);
    final rows = output[0] as List;

    var count = 0;
    for (var t = 0; t < seqLen && t < rows.length; t++) {
      if (t < attentionMask.length && attentionMask[t] == 0) break;
      final row = rows[t] as List;
      for (var d = 0; d < hidden; d++) {
        pooled[d] += (row[d] as num).toDouble();
      }
      count++;
    }

    if (count > 0) {
      for (var d = 0; d < hidden; d++) {
        pooled[d] /= count;
      }
    }

    return _normalize(pooled);
  }

  /// L2-normalises [vector] so cosine similarity equals the dot product.
  List<double> _normalize(List<double> vector) {
    var normSquared = 0.0;
    for (final value in vector) {
      normSquared += value * value;
    }

    final norm = math.sqrt(normSquared);
    if (norm == 0) {
      return List<double>.filled(vector.length, 0.0);
    }

    return [for (final value in vector) value / norm];
  }

  /// Releases the loaded interpreter. Safe to call when nothing is loaded.
  Future<void> dispose() async {
    final interpreter = _interpreter;
    _interpreter = null;
    interpreter?.close();
  }
}
