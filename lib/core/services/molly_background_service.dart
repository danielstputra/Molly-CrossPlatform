import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'local_storage_service.dart';

class MollyBackgroundService with WidgetsBindingObserver {
  MollyBackgroundService._();
  static final MollyBackgroundService instance = MollyBackgroundService._();

  static const MethodChannel _channel = MethodChannel('com.molly.crossplatform/background_service');

  bool _initialized = false;
  bool _isAppInBackground = false;
  bool _isTaskActive = false;
  String? _currentAgentName;
  String? _currentTaskDescription;
  DateTime? _taskStartTime;

  final StreamController<bool> _taskStatusController = StreamController<bool>.broadcast();
  Stream<bool> get taskStatusStream => _taskStatusController.stream;

  bool get isAppInBackground => _isAppInBackground;
  bool get isTaskActive => _isTaskActive;
  String? get currentAgentName => _currentAgentName;
  String? get currentTaskDescription => _currentTaskDescription;
  DateTime? get taskStartTime => _taskStartTime;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    WidgetsBinding.instance.addObserver(this);

    // Initial permission request for notifications on mobile
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        await _channel.invokeMethod('requestPermissions');
      } catch (e) {
        debugPrint('[MollyBackgroundService] requestPermissions error: $e');
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        _isAppInBackground = true;
        debugPrint('[MollyBackgroundService] App masuk background/minimize (Task Active: $_isTaskActive)');
        break;
      case AppLifecycleState.resumed:
        _isAppInBackground = false;
        debugPrint('[MollyBackgroundService] App kembali ke foreground');
        break;
      case AppLifecycleState.detached:
        _isAppInBackground = true;
        break;
    }
  }

  /// Memulai background task & mengakuisisi WakeLock pada CPU HP
  Future<void> startAgentTask({
    required String agentName,
    required String prompt,
  }) async {
    _isTaskActive = true;
    _currentAgentName = agentName;
    _currentTaskDescription = prompt;
    _taskStartTime = DateTime.now();
    _taskStatusController.add(true);

    if (kIsWeb) return;

    final keepAliveEnabled = LocalStorageService.instance.getBackgroundKeepAlive();
    if (!keepAliveEnabled) return;

    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final shortPrompt = prompt.length > 80 ? '${prompt.substring(0, 77)}...' : prompt;
        await _channel.invokeMethod('startBackgroundTask', {
          'title': 'Molly AI: Agen "$agentName" Sedang Bekerja',
          'content': shortPrompt,
        });
        debugPrint('[MollyBackgroundService] WakeLock & Keep-Alive dimulai untuk agen: $agentName');
      }
    } catch (e) {
      debugPrint('[MollyBackgroundService] startBackgroundTask error: $e');
    }
  }

  /// Menghentikan background task & melepaskan WakeLock
  Future<void> stopAgentTask() async {
    _isTaskActive = false;
    _currentAgentName = null;
    _currentTaskDescription = null;
    _taskStartTime = null;
    _taskStatusController.add(false);

    if (kIsWeb) return;

    try {
      if (Platform.isAndroid || Platform.isIOS) {
        await _channel.invokeMethod('stopBackgroundTask');
        debugPrint('[MollyBackgroundService] WakeLock & Keep-Alive dihentikan.');
      }
    } catch (e) {
      debugPrint('[MollyBackgroundService] stopBackgroundTask error: $e');
    }
  }

  /// Mengirim notifikasi sistem jika agen membutuhkan konfirmasi dari user
  Future<void> notifyConfirmationRequired({
    required String agentName,
    required String actionDescription,
  }) async {
    final notificationsEnabled = LocalStorageService.instance.getBackgroundNotifications();
    final notifyConfirm = LocalStorageService.instance.getNotifyConfirmation();
    if (!notificationsEnabled || !notifyConfirm) return;

    if (kIsWeb) return;

    try {
      if (Platform.isAndroid || Platform.isIOS) {
        await _channel.invokeMethod('showNotification', {
          'type': 'confirmation',
          'title': '⚠️ Konfirmasi Diperlukan - $agentName',
          'body': actionDescription,
          'id': 2001,
        });
        debugPrint('[MollyBackgroundService] Notifikasi konfirmasi dikirim.');
      }
    } catch (e) {
      debugPrint('[MollyBackgroundService] notifyConfirmationRequired error: $e');
    }
  }

  /// Mengirim notifikasi sistem saat pengerjaan task agen AI sukses
  Future<void> notifyTaskSuccess({
    required String agentName,
    required String summary,
  }) async {
    final notificationsEnabled = LocalStorageService.instance.getBackgroundNotifications();
    final notifySuccess = LocalStorageService.instance.getNotifySuccess();
    if (!notificationsEnabled || !notifySuccess) return;

    // Jika app masih di foreground dan user sedang melihat langsung,
    // notifikasi HP tetap dikirimkan jika disetel atau saat app sempat di background.
    if (kIsWeb) return;

    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final cleanSummary = summary.replaceAll(RegExp(r'[#*`_\[\]]'), '').trim();
        final shortSummary = cleanSummary.length > 120 ? '${cleanSummary.substring(0, 117)}...' : cleanSummary;
        
        await _channel.invokeMethod('showNotification', {
          'type': 'success',
          'title': '✅ Task Selesai - $agentName',
          'body': shortSummary.isNotEmpty ? shortSummary : 'Pengerjaan task selesai dengan sukses.',
          'id': 2002,
        });
        debugPrint('[MollyBackgroundService] Notifikasi sukses dikirim.');
      }
    } catch (e) {
      debugPrint('[MollyBackgroundService] notifyTaskSuccess error: $e');
    }
  }

  /// Mengirim notifikasi sistem saat pengerjaan task agen AI gagal
  Future<void> notifyTaskFailed({
    required String agentName,
    required String errorMessage,
  }) async {
    final notificationsEnabled = LocalStorageService.instance.getBackgroundNotifications();
    final notifyFailure = LocalStorageService.instance.getNotifyFailure();
    if (!notificationsEnabled || !notifyFailure) return;

    if (kIsWeb) return;

    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final cleanError = errorMessage.replaceAll(RegExp(r'[#*`_\[\]]'), '').trim();
        final shortError = cleanError.length > 120 ? '${cleanError.substring(0, 117)}...' : cleanError;

        await _channel.invokeMethod('showNotification', {
          'type': 'failed',
          'title': '❌ Task Gagal - $agentName',
          'body': shortError.isNotEmpty ? shortError : 'Terjadi kendala saat memproses task.',
          'id': 2003,
        });
        debugPrint('[MollyBackgroundService] Notifikasi gagal dikirim.');
      }
    } catch (e) {
      debugPrint('[MollyBackgroundService] notifyTaskFailed error: $e');
    }
  }

  /// Cek status optimasi baterai (Doze mode) pada Android
  Future<bool> isBatteryOptimizationIgnored() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    try {
      final res = await _channel.invokeMethod<bool>('checkBatteryOptimizations');
      return res ?? true;
    } catch (e) {
      return true;
    }
  }

  /// Membuka prompt sistem agar Molly dikecualikan dari pembatasan baterai Android
  Future<void> requestBatteryOptimizationExemption() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('requestIgnoreBatteryOptimizations');
    } catch (e) {
      debugPrint('[MollyBackgroundService] requestIgnoreBatteryOptimizations error: $e');
    }
  }

  /// Minta izin notifikasi (Android 13+ & iOS)
  Future<void> requestNotificationPermissions() async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod('requestPermissions');
    } catch (e) {
      debugPrint('[MollyBackgroundService] requestNotificationPermissions error: $e');
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _taskStatusController.close();
  }
}
