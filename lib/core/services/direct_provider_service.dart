import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';
import 'antigravity_oauth_service.dart';
import 'local_storage_service.dart';

class DirectProviderService {
  DirectProviderService._();
  static final DirectProviderService instance = DirectProviderService._();

  final _storage = LocalStorageService.instance;

  /// Fetch Real Live Models dynamically from Provider APIs
  Future<List<String>> fetchLiveModels(String provider, {String? apiKey}) async {
    final prov = provider.toLowerCase();
    final key = apiKey ?? _storage.getApiKey(prov);

    try {
      if (prov.contains('antigravity')) {
        return [
          'gemini-3.8-flash-medium',
          'gemini-3.8-flash-low',
          'gemini-3.8-flash-high',
          'gemini-3.8-pro',
          'gemini-2.5-pro',
          'claude-sonnet-4-6-thinking',
          'claude-opus-4-6-thinking',
          'deepseek-r1-thinking',
        ];
      }

      if (prov == 'openai') {
        if (key.isEmpty) return [];
        final res = await http.get(
          Uri.parse('https://api.openai.com/v1/models'),
          headers: {'Authorization': 'Bearer $key'},
        ).timeout(const Duration(seconds: 10));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final List list = data['data'] ?? [];
          final models = list
              .map((m) => m['id'] as String)
              .where((id) => id.startsWith('gpt-') || id.startsWith('o1') || id.startsWith('chatgpt'))
              .toList();
          models.sort();
          return models;
        }
      }

      if (prov == 'groq') {
        if (key.isEmpty) return [];
        final res = await http.get(
          Uri.parse('https://api.groq.com/openai/v1/models'),
          headers: {'Authorization': 'Bearer $key'},
        ).timeout(const Duration(seconds: 10));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final List list = data['data'] ?? [];
          final models = list.map((m) => m['id'] as String).toList();
          models.sort();
          return models;
        }
      }

      if (prov == 'gemini') {
        if (key.isEmpty) return [];
        final res = await http.get(
          Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$key'),
        ).timeout(const Duration(seconds: 10));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final List list = data['models'] ?? [];
          final models = list
              .map((m) => (m['name'] as String).replaceFirst('models/', ''))
              .where((id) => id.contains('gemini'))
              .toList();
          models.sort();
          return models;
        }
      }

      if (prov == 'ollama') {
        final url = key.isNotEmpty ? key : 'http://localhost:11434';
        final res = await http.get(Uri.parse('$url/api/tags')).timeout(const Duration(seconds: 6));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final List list = data['models'] ?? [];
          return list.map((m) => m['name'] as String).toList();
        }
      }

      if (prov == 'anthropic') {
        return [
          'claude-3-5-sonnet-20241022',
          'claude-3-5-haiku-20241022',
          'claude-3-opus-20240229',
          'claude-3-haiku-20240307',
        ];
      }
    } catch (e) {
      debugPrint('Failed to fetch live models for $provider: $e');
    }

    return [];
  }

  Stream<String> streamChat({
    required List<ChatMessage> history,
    required String prompt,
    String? systemPrompt,
  }) async* {
    final provider = _storage.getActiveProvider().toLowerCase();
    final model = _storage.getActiveModel();
    final apiKey = _storage.getApiKey(provider);

    // Gemini Antigravity uses OAuth tokens instead of manual API Key
    final isOAuthProvider = provider.contains('antigravity');

    // If no API Key configured, yield helpful guidance
    if (apiKey.isEmpty && provider != 'ollama' && !isOAuthProvider) {
      yield 'Halo! Anda saat ini berada dalam **Mode Standalone (Berdiri Sendiri)**.\n\n';
      yield 'Untuk menghubungkan langsung ke provider AI tanpa server Molly:\n';
      yield '1. Buka tab **Pengaturan**.\n';
      yield '2. Masukkan **API Key** untuk provider **$provider** (atau pilih Gemini Antigravity / Ollama).\n';
      yield '3. Kirim kembali pesan Anda untuk streaming real-time.';
      return;
    }

    try {
      if (isOAuthProvider) {
        yield* _streamGeminiAntigravity(
          model: model,
          history: history,
          prompt: prompt,
          systemPrompt: systemPrompt,
        );
      } else if (provider == 'openai' || provider == 'groq') {
        yield* _streamOpenAiCompatible(
          endpoint: provider == 'groq'
              ? 'https://api.groq.com/openai/v1/chat/completions'
              : 'https://api.openai.com/v1/chat/completions',
          apiKey: apiKey,
          model: model,
          history: history,
          prompt: prompt,
          systemPrompt: systemPrompt,
        );
      } else if (provider == 'anthropic') {
        yield* _streamAnthropic(
          apiKey: apiKey,
          model: model,
          history: history,
          prompt: prompt,
          systemPrompt: systemPrompt,
        );
      } else if (provider == 'gemini') {
        yield* _streamGemini(
          apiKey: apiKey,
          model: model,
          history: history,
          prompt: prompt,
          systemPrompt: systemPrompt,
        );
      } else if (provider == 'ollama') {
        yield* _streamOllama(
          baseUrl: apiKey.isNotEmpty ? apiKey : 'http://localhost:11434',
          model: model,
          history: history,
          prompt: prompt,
          systemPrompt: systemPrompt,
        );
      } else {
        yield 'Provider "$provider" belum didukung secara langsung di mode Standalone.';
      }
    } catch (e) {
      debugPrint('Error direct streaming: $e');
      yield '\n\n*(Gagal menghubungkan ke $provider: $e)*';
    }
  }

  // ==========================================
  // OPENAI & GROQ COMPATIBLE STREAM
  // ==========================================
  Stream<String> _streamOpenAiCompatible({
    required String endpoint,
    required String apiKey,
    required String model,
    required List<ChatMessage> history,
    required String prompt,
    String? systemPrompt,
  }) async* {
    final messages = <Map<String, String>>[];
    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      messages.add({'role': 'system', 'content': systemPrompt});
    }
    for (final m in history) {
      messages.add({'role': m.isUser ? 'user' : 'assistant', 'content': m.text});
    }
    messages.add({'role': 'user', 'content': prompt});

    final request = http.Request('POST', Uri.parse(endpoint))
      ..headers.addAll({
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      })
      ..body = jsonEncode({
        'model': model,
        'messages': messages,
        'stream': true,
      });

    final response = await http.Client().send(request);

    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      yield 'Kesalahan API (${response.statusCode}): $body';
      return;
    }

    final stream = response.stream.transform(utf8.decoder).transform(const LineSplitter());

    await for (final line in stream) {
      final trimmed = line.trim();
      if (!trimmed.startsWith('data:')) continue;
      final payload = trimmed.substring(5).trim();
      if (payload == '[DONE]') break;

      try {
        final json = jsonDecode(payload);
        final delta = json['choices']?[0]?['delta']?['content'];
        if (delta != null && delta is String) {
          yield delta;
        }
      } catch (_) {}
    }
  }

  // ==========================================
  // ANTHROPIC CLAUDE STREAM
  // ==========================================
  Stream<String> _streamAnthropic({
    required String apiKey,
    required String model,
    required List<ChatMessage> history,
    required String prompt,
    String? systemPrompt,
  }) async* {
    final messages = <Map<String, String>>[];
    for (final m in history) {
      messages.add({'role': m.isUser ? 'user' : 'assistant', 'content': m.text});
    }
    messages.add({'role': 'user', 'content': prompt});

    final request = http.Request('POST', Uri.parse('https://api.anthropic.com/v1/messages'))
      ..headers.addAll({
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      })
      ..body = jsonEncode({
        'model': model,
        'max_tokens': 4096,
        'system': systemPrompt ?? 'Anda adalah Molly, asisten AI cerdas berstandar Apple HIG.',
        'messages': messages,
        'stream': true,
      });

    final response = await http.Client().send(request);

    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      yield 'Kesalahan Anthropic API (${response.statusCode}): $body';
      return;
    }

    final stream = response.stream.transform(utf8.decoder).transform(const LineSplitter());

    await for (final line in stream) {
      final trimmed = line.trim();
      if (!trimmed.startsWith('data:')) continue;
      final payload = trimmed.substring(5).trim();

      try {
        final json = jsonDecode(payload);
        if (json['type'] == 'content_block_delta') {
          final delta = json['delta']?['text'];
          if (delta != null && delta is String) {
            yield delta;
          }
        }
      } catch (_) {}
    }
  }

  // ==========================================
  // GOOGLE GEMINI STREAM
  // ==========================================
  Stream<String> _streamGemini({
    required String apiKey,
    required String model,
    required List<ChatMessage> history,
    required String prompt,
    String? systemPrompt,
  }) async* {
    final geminiModel = model.contains('gemini') ? model : 'gemini-1.5-flash';
    final url =
        'https://generativelanguage.googleapis.com/v1beta/models/$geminiModel:streamGenerateContent?key=$apiKey&alt=sse';

    final contents = <Map<String, dynamic>>[];
    for (final m in history) {
      contents.add({
        'role': m.isUser ? 'user' : 'model',
        'parts': [{'text': m.text}],
      });
    }
    contents.add({
      'role': 'user',
      'parts': [{'text': prompt}],
    });

    final request = http.Request('POST', Uri.parse(url))
      ..headers.addAll({'Content-Type': 'application/json'})
      ..body = jsonEncode({
        'contents': contents,
        if (systemPrompt != null)
          'systemInstruction': {
            'parts': [{'text': systemPrompt}]
          },
      });

    final response = await http.Client().send(request);

    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      yield 'Kesalahan Gemini API (${response.statusCode}): $body';
      return;
    }

    final stream = response.stream.transform(utf8.decoder).transform(const LineSplitter());

    await for (final line in stream) {
      final trimmed = line.trim();
      if (!trimmed.startsWith('data:')) continue;
      final payload = trimmed.substring(5).trim();

      try {
        final json = jsonDecode(payload);
        final candidates = json['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final text = candidates[0]['content']?['parts']?[0]?['text'];
          if (text != null && text is String) {
            yield text;
          }
        }
      } catch (_) {}
    }
  }

  // ==========================================
  // LOCAL OLLAMA STREAM
  // ==========================================
  Stream<String> _streamOllama({
    required String baseUrl,
    required String model,
    required List<ChatMessage> history,
    required String prompt,
    String? systemPrompt,
  }) async* {
    final messages = <Map<String, String>>[];
    if (systemPrompt != null) {
      messages.add({'role': 'system', 'content': systemPrompt});
    }
    for (final m in history) {
      messages.add({'role': m.isUser ? 'user' : 'assistant', 'content': m.text});
    }
    messages.add({'role': 'user', 'content': prompt});

    final cleanBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final request = http.Request('POST', Uri.parse('$cleanBase/api/chat'))
      ..headers.addAll({'Content-Type': 'application/json'})
      ..body = jsonEncode({
        'model': model.isNotEmpty ? model : 'llama3',
        'messages': messages,
        'stream': true,
      });

    final response = await http.Client().send(request);

    if (response.statusCode != 200) {
      yield 'Gagal menghubungi Ollama di $cleanBase (${response.statusCode}). Pastikan Ollama aktif.';
      return;
    }

    final stream = response.stream.transform(utf8.decoder).transform(const LineSplitter());

    await for (final line in stream) {
      if (line.trim().isEmpty) continue;
      try {
        final json = jsonDecode(line);
        final message = json['message']?['content'];
        if (message != null && message is String) {
          yield message;
        }
      } catch (_) {}
    }
  }

  // ==========================================
  // GEMINI ANTIGRAVITY (CLOUDCODE INTERNAL STREAM)
  // ==========================================
  Stream<String> _streamGeminiAntigravity({
    required String model,
    required List<ChatMessage> history,
    required String prompt,
    String? systemPrompt,
  }) async* {
    final oauth = AntigravityOAuthService.instance;
    if (!oauth.isAuthenticated) {
      yield '⚠️ **Gemini Antigravity Memerlukan Otentikasi Google**\n\n'
          'Silakan buka menu **Pengaturan**, lalu tekan tombol **"Start OAuth Google (Login Antigravity)"** untuk menghubungkan akun Google Anda.';
      return;
    }

    String token;
    try {
      token = await oauth.getValidAccessToken();
    } catch (e) {
      yield 'Gagal memperoleh access token Google: $e. Silakan lakukan login Google OAuth ulang di Pengaturan.';
      return;
    }

    final antigravityModel = model.isNotEmpty ? model : 'gemini-3.8-flash-medium';
    final url = 'https://cloudcode-pa.googleapis.com/v1internal:streamGenerateContent?alt=sse';
    final fallbackUrl = 'https://daily-cloudcode-pa.googleapis.com/v1internal:streamGenerateContent?alt=sse';

    final contents = <Map<String, dynamic>>[];
    for (final m in history) {
      contents.add({
        'role': m.isUser ? 'user' : 'model',
        'parts': [{'text': m.text}],
      });
    }
    contents.add({
      'role': 'user',
      'parts': [{'text': prompt}],
    });

    final payload = {
      'contents': contents,
      if (systemPrompt != null && systemPrompt.isNotEmpty)
        'systemInstruction': {
          'parts': [{'text': systemPrompt}]
        },
      'generationConfig': {
        'thinkingConfig': {
          'includeThoughts': true,
          'thinkingLevel': antigravityModel.contains('low') ? 'LOW' : 'MEDIUM',
        },
      },
    };

    http.Request createReq(String endpoint) => http.Request('POST', Uri.parse(endpoint))
      ..headers.addAll({
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'User-Agent': 'Antigravity/1.104.0 (Windows NT 10.0; Win64; x64)',
      })
      ..body = jsonEncode(payload);

    http.StreamedResponse response;
    try {
      response = await http.Client().send(createReq(url));
      if (response.statusCode != 200) {
        response = await http.Client().send(createReq(fallbackUrl));
      }
    } catch (_) {
      response = await http.Client().send(createReq(fallbackUrl));
    }

    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      yield 'Kesalahan Gemini Antigravity API (${response.statusCode}): $body';
      return;
    }

    final stream = response.stream.transform(utf8.decoder).transform(const LineSplitter());

    await for (final line in stream) {
      final trimmed = line.trim();
      if (!trimmed.startsWith('data:')) continue;
      final dataStr = trimmed.substring(5).trim();
      if (dataStr == '[DONE]') break;

      try {
        final json = jsonDecode(dataStr);
        final candidates = json['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final parts = candidates[0]['content']?['parts'] as List?;
          if (parts != null) {
            for (final part in parts) {
              final text = part['text'];
              if (text != null && text is String) {
                yield text;
              }
            }
          }
        }
      } catch (_) {}
    }
  }
}
