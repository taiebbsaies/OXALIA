import 'dart:async';

import 'package:flutter/foundation.dart';

enum ActiveAnalysisStatus { idle, uploading, processing, completed, failed }

class ActiveAnalysisTracker extends ChangeNotifier {
  ActiveAnalysisStatus _status = ActiveAnalysisStatus.idle;
  Timer? _processingTimer;
  String? _patientName;
  double _progress = 0;
  String? _message;

  ActiveAnalysisStatus get status => _status;
  String? get patientName => _patientName;
  double get progress => _progress;
  String? get message => _message;
  bool get hasActiveAnalysis =>
      _status == ActiveAnalysisStatus.uploading ||
      _status == ActiveAnalysisStatus.processing;

  void startUpload({required String patientName}) {
    _processingTimer?.cancel();
    _patientName = patientName;
    _status = ActiveAnalysisStatus.uploading;
    _progress = 0.05;
    _message = 'Uploading X-ray to the server';
    notifyListeners();
  }

  void updateUploadProgress(double value) {
    if (_status != ActiveAnalysisStatus.uploading) return;
    _progress = (value.clamp(0, 1) * 0.6).clamp(0.05, 0.6);
    notifyListeners();
  }

  void startProcessing() {
    _status = ActiveAnalysisStatus.processing;
    _progress = _progress < 0.65 ? 0.65 : _progress;
    _message = 'AI analysis running on the server';
    notifyListeners();

    _processingTimer?.cancel();
    _processingTimer = Timer.periodic(const Duration(milliseconds: 900), (_) {
      if (_status != ActiveAnalysisStatus.processing) return;
      if (_progress < 0.92) {
        _progress = (_progress + 0.025).clamp(0, 0.92);
        notifyListeners();
      }
    });
  }

  void complete() {
    _processingTimer?.cancel();
    _status = ActiveAnalysisStatus.completed;
    _progress = 1;
    _message = 'Analysis ready';
    notifyListeners();
  }

  void fail(String message) {
    _processingTimer?.cancel();
    _status = ActiveAnalysisStatus.failed;
    _message = message;
    notifyListeners();
  }

  void clear() {
    _processingTimer?.cancel();
    _status = ActiveAnalysisStatus.idle;
    _patientName = null;
    _progress = 0;
    _message = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _processingTimer?.cancel();
    super.dispose();
  }
}
