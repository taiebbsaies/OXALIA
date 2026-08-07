import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/errors/api_exception.dart';
import '../../../core/notifications/notification_inbox.dart';
import '../../../core/utils/image_preprocessor.dart';
import '../../../data/models/exam.dart';
import '../../../data/models/inference_result.dart';
import '../../../data/repositories/exam_repository.dart';

enum AnalysisStep {
  /// No image picked yet — scanner idle.
  idle,

  /// Scan animation while the native compressor normalizes the image.
  scanning,

  /// Image loaded — user drags crop corners before upload.
  resizing,

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
  AnalysisViewModel(this._repository, {NotificationInbox? notificationInbox})
      : _notificationInbox = notificationInbox;

  final ExamRepository _repository;
  final NotificationInbox? _notificationInbox;
  final ImagePicker _picker = ImagePicker();

  AnalysisStep _step = AnalysisStep.idle;
  Uint8List? _sourceBytes;
  Uint8List? _imageBytes;
  String? _errorMessage;
  Exam? _exam;
  InferenceResult? _result;
  bool _cancelRequested = false;
  double _uploadProgress = 0;
  String _patientName = '';
  bool _applyingCrop = false;

  AnalysisStep get step => _step;

  /// Bytes shown after crop/upload; during [AnalysisStep.resizing] use
  /// [sourceBytes] for the interactive crop widget.
  Uint8List? get imageBytes => _imageBytes;

  /// Full working image the user crops with their fingers.
  Uint8List? get sourceBytes => _sourceBytes;

  String? get errorMessage => _errorMessage;
  Exam? get exam => _exam;
  InferenceResult? get result => _result;
  String get patientName => _patientName;
  bool get applyingCrop => _applyingCrop;

  /// Upload completion ratio (0.0 – 1.0) reported by Dio's send progress.
  double get uploadProgress => _uploadProgress;

  bool get isBusy =>
      _step == AnalysisStep.scanning ||
      _step == AnalysisStep.uploading ||
      _step == AnalysisStep.processing ||
      _applyingCrop;

  bool get canCapture =>
      !isBusy &&
      _patientName.trim().isNotEmpty &&
      (_step == AnalysisStep.idle || _step == AnalysisStep.failed);

  void setPatientName(String value) {
    if (_patientName == value) return;
    _patientName = value;
    notifyListeners();
  }

  /// Pick from camera or gallery, normalize for preview, then wait for
  /// the user to drag-crop before upload.
  Future<void> pickImage(ImageSource source) async {
    if (!canCapture) {
      _errorMessage = 'Enter the patient name before capturing.';
      notifyListeners();
      return;
    }

    final picked = await _picker.pickImage(
      source: source,
      maxWidth: ImagePreprocessor.previewMaxDimension.toDouble(),
      maxHeight: ImagePreprocessor.previewMaxDimension.toDouble(),
      imageQuality: 95,
    );
    if (picked == null) return;

    _step = AnalysisStep.scanning;
    _errorMessage = null;
    _exam = null;
    _result = null;
    _uploadProgress = 0;
    _sourceBytes = null;
    _imageBytes = null;
    notifyListeners();

    try {
      final rawBytes = await picked.readAsBytes();
      _sourceBytes = await ImagePreprocessor.normalize(
        rawBytes,
        maxEdge: ImagePreprocessor.previewMaxDimension,
      );
      _imageBytes = _sourceBytes;
      _step = AnalysisStep.resizing;
    } catch (_) {
      _errorMessage = 'Unsupported image format. Pick a JPEG or PNG photo.';
      _step = AnalysisStep.failed;
    }
    notifyListeners();
  }

  /// Discard the current preview and return to the capture screen.
  void discardImage() {
    if (_applyingCrop ||
        _step == AnalysisStep.uploading ||
        _step == AnalysisStep.processing) {
      return;
    }
    _sourceBytes = null;
    _imageBytes = null;
    _errorMessage = null;
    _exam = null;
    _result = null;
    _uploadProgress = 0;
    _step = AnalysisStep.idle;
    notifyListeners();
  }

  /// Called when the crop widget finishes; compresses then uploads.
  Future<void> applyCroppedAndUpload(Uint8List croppedBytes) async {
    if (_step != AnalysisStep.resizing) return;

    final name = _patientName.trim();
    if (name.isEmpty) {
      _errorMessage = 'Enter the patient name before capturing.';
      notifyListeners();
      return;
    }

    _applyingCrop = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _imageBytes = await ImagePreprocessor.normalize(croppedBytes);
    } catch (_) {
      _applyingCrop = false;
      _errorMessage = 'Could not process the cropped image. Try again.';
      notifyListeners();
      return;
    }

    _applyingCrop = false;
    await startAnalysis();
  }

  void setCropError(String message) {
    _applyingCrop = false;
    _errorMessage = message;
    notifyListeners();
  }

  void beginCrop() {
    if (_applyingCrop || _step != AnalysisStep.resizing) return;
    _applyingCrop = true;
    _errorMessage = null;
    notifyListeners();
  }

  /// Full pipeline: upload (with retry) → poll → fetch result.
  Future<void> startAnalysis() async {
    final bytes = _imageBytes;
    if (bytes == null) return;
    if (_step == AnalysisStep.uploading || _step == AnalysisStep.processing) {
      return;
    }

    final name = _patientName.trim();
    if (name.isEmpty) {
      _errorMessage = 'Enter the patient name before capturing.';
      _step = AnalysisStep.failed;
      notifyListeners();
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
        patientName: name,
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
      await _notificationInbox?.addAnalysisUpdate(
        title: 'Analysis ready',
        body: 'Results for $name are ready to review.',
        examId: completed.id,
        status: 'completed',
      );
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _step = AnalysisStep.failed;
      await _notificationInbox?.addAnalysisUpdate(
        title: 'Analysis failed',
        body: e.message,
        examId: _exam?.id,
        status: 'failed',
      );
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
    _sourceBytes = null;
    _imageBytes = null;
    _errorMessage = null;
    _exam = null;
    _result = null;
    _uploadProgress = 0;
    _patientName = '';
    _applyingCrop = false;
    notifyListeners();
  }
}
