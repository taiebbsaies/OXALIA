import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/errors/api_exception.dart';
import '../../../core/utils/image_preprocessor.dart';
import '../../../data/models/exam.dart';
import '../../../data/models/inference_result.dart';
import '../../../data/repositories/exam_repository.dart';

enum AnalysisStep {
  /// No image picked yet — scanner idle.
  idle,

  /// Scan animation while the native compressor normalizes the image.
  scanning,

  /// Multipart upload in flight (with retry inside the repository).
  uploading,

  /// Upload accepted; polling until inference resolves.
  processing,

  /// Result available.
  completed,

  /// Unrecoverable error; see [errorMessage].
  failed,
}

class AnalysisViewModel extends ChangeNotifier {
  AnalysisViewModel(this._repository);

  final ExamRepository _repository;
  final ImagePicker _picker = ImagePicker();

  AnalysisStep _step = AnalysisStep.idle;
  Uint8List? _imageBytes;
  String? _errorMessage;
  Exam? _exam;
  InferenceResult? _result;
  bool _cancelRequested = false;
  double _uploadProgress = 0;

  AnalysisStep get step => _step;
  Uint8List? get imageBytes => _imageBytes;
  String? get errorMessage => _errorMessage;
  Exam? get exam => _exam;
  InferenceResult? get result => _result;

  /// Upload completion ratio (0.0 – 1.0) reported by Dio's send progress.
  double get uploadProgress => _uploadProgress;

  bool get isBusy =>
      _step == AnalysisStep.scanning ||
      _step == AnalysisStep.uploading ||
      _step == AnalysisStep.processing;

  /// Pick from camera or gallery, preprocess, then auto-start the pipeline.
  Future<void> pickImage(ImageSource source) async {
    if (isBusy) return;

    final picked = await _picker.pickImage(source: source);
    if (picked == null) return;

    _step = AnalysisStep.scanning;
    _errorMessage = null;
    _exam = null;
    _result = null;
    _uploadProgress = 0;
    notifyListeners();

    try {
      final rawBytes = await picked.readAsBytes();
      _imageBytes = await ImagePreprocessor.normalize(rawBytes);
    } catch (_) {
      _errorMessage = 'Unsupported image format. Pick a JPEG or PNG photo.';
      _step = AnalysisStep.failed;
      notifyListeners();
      return;
    }

    notifyListeners();
    await startAnalysis();
  }

  /// Full pipeline: upload (with retry) → poll → fetch result.
  Future<void> startAnalysis() async {
    final bytes = _imageBytes;
    if (bytes == null) return;
    if (_step == AnalysisStep.uploading || _step == AnalysisStep.processing) {
      return;
    }

    _cancelRequested = false;
    _errorMessage = null;
    _uploadProgress = 0;
    _step = AnalysisStep.uploading;
    notifyListeners();

    try {
      _exam = await _repository.uploadExam(
        imageBytes: bytes,
        filename: 'exam.jpg',
        onSendProgress: (sent, total) {
          if (total > 0) {
            _uploadProgress = sent / total;
            notifyListeners();
          }
        },
      );

      _step = AnalysisStep.processing;
      notifyListeners();

      final completed = await _repository.waitForCompletion(
        _exam!.id,
        isCancelled: () => _cancelRequested,
      );
      _exam = completed;
      _result = await _repository.getResult(completed.id);

      _step = AnalysisStep.completed;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _step = AnalysisStep.failed;
    }
    notifyListeners();
  }

  /// Stops the polling loop; the server-side inference keeps running and
  /// its result remains reachable from the History tab later.
  void cancelWait() {
    if (_step == AnalysisStep.processing) {
      _cancelRequested = true;
    }
  }

  void reset() {
    _cancelRequested = true;
    _step = AnalysisStep.idle;
    _imageBytes = null;
    _errorMessage = null;
    _exam = null;
    _result = null;
    _uploadProgress = 0;
    notifyListeners();
  }
}
