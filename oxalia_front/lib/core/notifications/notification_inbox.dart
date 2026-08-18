import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/app_notification.dart';

/// Persistent in-app inbox for push / analysis notifications.
class NotificationInbox extends ChangeNotifier {
  NotificationInbox();

  static const _prefsKey = 'oxalia_notification_inbox_v1';
  static const _maxItems = 100;

  final List<AppNotification> _items = [];
  bool _loaded = false;

  List<AppNotification> get items => List.unmodifiable(_items);
  bool get isLoaded => _loaded;
  int get unreadCount => _items.where((n) => !n.read).length;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    _items.clear();
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        _items.addAll(
          list
              .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
        _items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      } catch (e) {
        debugPrint('NotificationInbox load failed: $e');
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(_items.map((e) => e.toJson()).toList()),
    );
  }

  /// Adds a notification, deduping recent entries for the same exam+status.
  Future<void> add(AppNotification notification) async {
    final duplicate = _items.any(
      (n) =>
          n.examId != null &&
          n.examId == notification.examId &&
          n.status == notification.status &&
          n.createdAt.difference(notification.createdAt).abs() <
              const Duration(minutes: 2),
    );
    if (duplicate) return;

    _items.insert(0, notification);
    if (_items.length > _maxItems) {
      _items.removeRange(_maxItems, _items.length);
    }
    notifyListeners();
    await _persist();
  }

  Future<void> addAnalysisUpdate({
    required String title,
    required String body,
    String? examId,
    String? status,
  }) {
    return add(
      AppNotification(
        id: '${DateTime.now().microsecondsSinceEpoch}',
        title: title,
        body: body,
        createdAt: DateTime.now(),
        examId: examId,
        type: 'exam_status',
        status: status,
      ),
    );
  }

  Future<void> markRead(String id) async {
    final index = _items.indexWhere((n) => n.id == id);
    if (index < 0 || _items[index].read) return;
    _items[index] = _items[index].copyWith(read: true);
    notifyListeners();
    await _persist();
  }

  Future<void> markAllRead() async {
    var changed = false;
    for (var i = 0; i < _items.length; i++) {
      if (!_items[i].read) {
        _items[i] = _items[i].copyWith(read: true);
        changed = true;
      }
    }
    if (!changed) return;
    notifyListeners();
    await _persist();
  }

  Future<void> remove(String id) async {
    final before = _items.length;
    _items.removeWhere((n) => n.id == id);
    if (_items.length == before) return;
    notifyListeners();
    await _persist();
  }

  Future<void> clearAll() async {
    if (_items.isEmpty) return;
    _items.clear();
    notifyListeners();
    await _persist();
  }
}
