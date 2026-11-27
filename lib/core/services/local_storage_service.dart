import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import '../models/session.dart';

enum AppEngineMode {
  standalone, // Direct On-Device Engine (Pure SQLite & Local Agent Loop)
}

class LocalStorageService {
  LocalStorageService._();
  static final LocalStorageService instance = LocalStorageService._();

  static const String _keyActiveProvider = 'active_provider';
  static const String _keyActiveModel = 'active_model';
  static const String _keySessions = 'local_chat_sessions';
  static const String _prefixMessages = 'local_session_messages_';

  static const String _keyOpenAiKey = 'key_openai';
  static const String _keyAnthropicKey = 'key_anthropic';
  static const String _keyGeminiKey = 'key_gemini';
  static const String _keyGroqKey = 'key_groq';
  static const String _keyOllamaUrl = 'key_ollama_url';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // ==========================================
  // ENGINE MODE & KEYS (100% STANDALONE)
  // ==========================================

  AppEngineMode getEngineMode() => AppEngineMode.standalone;
  Future<void> setEngineMode(AppEngineMode mode) async {}

  String getActiveProvider() => _prefs?.getString(_keyActiveProvider) ?? 'Gemini Antigravity';
  Future<void> setActiveProvider(String provider) async => await _prefs?.setString(_keyActiveProvider, provider);

  String getActiveModel() => _prefs?.getString(_keyActiveModel) ?? 'gemini-3.8-flash-medium';
  Future<void> setActiveModel(String model) async => await _prefs?.setString(_keyActiveModel, model);

  String getApiKey(String provider) {
    switch (provider.toLowerCase()) {
      case 'openai':
        return _prefs?.getString(_keyOpenAiKey) ?? '';
      case 'anthropic':
        return _prefs?.getString(_keyAnthropicKey) ?? '';
      case 'gemini':
        return _prefs?.getString(_keyGeminiKey) ?? '';
      case 'groq':
        return _prefs?.getString(_keyGroqKey) ?? '';
      case 'ollama':
        return _prefs?.getString(_keyOllamaUrl) ?? 'http://localhost:11434';
      default:
        return '';
    }
  }

  Future<void> setApiKey(String provider, String key) async {
    switch (provider.toLowerCase()) {
      case 'openai':
        await _prefs?.setString(_keyOpenAiKey, key);
        break;
      case 'anthropic':
        await _prefs?.setString(_keyAnthropicKey, key);
        break;
      case 'gemini':
        await _prefs?.setString(_keyGeminiKey, key);
        break;
      case 'groq':
        await _prefs?.setString(_keyGroqKey, key);
        break;
      case 'ollama':
        await _prefs?.setString(_keyOllamaUrl, key);
        break;
    }
  }

  // ==========================================
  // LOCAL SESSIONS & MESSAGES PERSISTENCE
  // ==========================================

  List<ChatSession> getSessions() {
    try {
      final raw = _prefs?.getString(_keySessions);
      if (raw == null || raw.isEmpty) return [];
      final List decoded = jsonDecode(raw);
      return decoded.map((e) => ChatSession.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error loading sessions: $e');
      return [];
    }
  }

  Future<void> saveSessions(List<ChatSession> sessions) async {
    try {
      final raw = jsonEncode(sessions.map((s) => s.toJson()).toList());
      await _prefs?.setString(_keySessions, raw);
    } catch (e) {
      debugPrint('Error saving sessions: $e');
    }
  }

  Future<void> addSession(ChatSession session) async {
    final list = getSessions();
    list.insert(0, session);
    await saveSessions(list);
  }

  List<ChatMessage> getMessages(String sessionId) {
    try {
      final raw = _prefs?.getString('$_prefixMessages$sessionId');
      if (raw == null || raw.isEmpty) return [];
      final List decoded = jsonDecode(raw);
      return decoded.map((e) => ChatMessage.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error loading messages: $e');
      return [];
    }
  }

  Future<void> saveMessages(String sessionId, List<ChatMessage> messages) async {
    try {
      final raw = jsonEncode(messages.map((m) => m.toJson()).toList());
      await _prefs?.setString('$_prefixMessages$sessionId', raw);
    } catch (e) {
      debugPrint('Error saving messages: $e');
    }
  }
}
