import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class AntigravityOAuthProfile {
  final String email;
  final String name;
  final String picture;
  final String accessToken;
  final String refreshToken;
  final int expiryTimestamp;

  const AntigravityOAuthProfile({
    required this.email,
    required this.name,
    required this.picture,
    required this.accessToken,
    required this.refreshToken,
    required this.expiryTimestamp,
  });

  bool get isExpired => DateTime.now().millisecondsSinceEpoch >= (expiryTimestamp - 60000);

  Map<String, dynamic> toJson() => {
    'email': email,
    'name': name,
    'picture': picture,
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'expiry_timestamp': expiryTimestamp,
  };

  factory AntigravityOAuthProfile.fromJson(Map<String, dynamic> json) {
    return AntigravityOAuthProfile(
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      picture: json['picture'] as String? ?? '',
      accessToken: json['access_token'] as String? ?? '',
      refreshToken: json['refresh_token'] as String? ?? '',
      expiryTimestamp: json['expiry_timestamp'] as int? ?? 0,
    );
  }
}

class AntigravityOAuthService {
  AntigravityOAuthService._();
  static final AntigravityOAuthService instance = AntigravityOAuthService._();

  // Reverse-engineered OAuth Credentials from Antigravity Tools
  static const String defaultClientId =
      '1071006060591-tmhssin2h21lcre235vtolojh4g403ep.apps.googleusercontent.com';
  static const String defaultClientSecret =
      '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';

  static const List<String> scopes = [
    'https://www.googleapis.com/auth/cloud-platform',
    'https://www.googleapis.com/auth/userinfo.email',
    'https://www.googleapis.com/auth/userinfo.profile',
    'https://www.googleapis.com/auth/cclog',
  ];

  static const String _keyProfile = 'antigravity_oauth_profile';

  AntigravityOAuthProfile? _currentProfile;
  AntigravityOAuthProfile? get currentProfile => _currentProfile;
  bool get isAuthenticated => _currentProfile != null && _currentProfile!.accessToken.isNotEmpty;

  HttpServer? _authServer;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyProfile);
    if (raw != null && raw.isNotEmpty) {
      try {
        _currentProfile = AntigravityOAuthProfile.fromJson(jsonDecode(raw));
        // Auto refresh if expired
        if (_currentProfile != null && _currentProfile!.isExpired && _currentProfile!.refreshToken.isNotEmpty) {
          await refreshAccessToken();
        }
      } catch (e) {
        debugPrint('Failed to load Antigravity OAuth profile: $e');
      }
    }
  }

  /// Start Google OAuth Flow (Interactive Browser Login)
  Future<AntigravityOAuthProfile> startGoogleOAuth({
    String clientId = defaultClientId,
    String clientSecret = defaultClientSecret,
  }) async {
    // 1. Start local loopback HTTP server to receive callback
    await _authServer?.close(force: true);
    _authServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final port = _authServer!.port;
    final redirectUri = 'http://127.0.0.1:$port/oauth-callback';

    final completer = Completer<String>();

    _authServer!.listen((HttpRequest request) async {
      final uri = request.uri;
      if (uri.path == '/oauth-callback') {
        final code = uri.queryParameters['code'];
        final error = uri.queryParameters['error'];

        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.html;

        if (code != null) {
          request.response.write('''
            <!DOCTYPE html>
            <html>
            <head>
              <meta charset="utf-8">
              <title>Molly • Otentikasi Berhasil</title>
              <style>
                body {
                  background-color: #0B0D13;
                  color: #E6EDF3;
                  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
                  display: flex;
                  align-items: center;
                  justify-content: center;
                  height: 100vh;
                  margin: 0;
                }
                .card {
                  background: rgba(18, 22, 34, 0.8);
                  border: 1px solid rgba(234, 179, 8, 0.4);
                  border-radius: 20px;
                  padding: 40px;
                  text-align: center;
                  max-width: 440px;
                  box-shadow: 0 20px 40px rgba(0,0,0,0.6);
                }
                .badge {
                  display: inline-block;
                  background: rgba(234, 179, 8, 0.15);
                  color: #EAB308;
                  font-weight: 700;
                  font-size: 11px;
                  letter-spacing: 1.5px;
                  padding: 6px 14px;
                  border-radius: 20px;
                  margin-bottom: 20px;
                }
                h1 { font-size: 24px; margin-bottom: 10px; color: #FFFFFF; }
                p { font-size: 14px; color: #94A3B8; line-height: 1.5; }
              </style>
            </head>
            <body>
              <div class="card">
                <div class="badge">ANTIGRAVITY OAUTH</div>
                <h1>Otentikasi Berhasil</h1>
                <p>Akun Google Anda berhasil terhubung ke <b>Molly Standalone Studio</b>. Anda dapat menutup tab ini dan kembali ke aplikasi.</p>
              </div>
            </body>
            </html>
          ''');
          await request.response.close();
          if (!completer.isCompleted) completer.complete(code);
        } else {
          request.response.write('''
            <!DOCTYPE html>
            <html>
            <body style="background:#0B0D13;color:#EF4444;font-family:sans-serif;padding:40px;text-align:center;">
              <h2>Otentikasi Dibatalkan</h2>
              <p>Error: ${error ?? 'Unknown error'}</p>
            </body>
            </html>
          ''');
          await request.response.close();
          if (!completer.isCompleted) completer.completeError(Exception(error ?? 'Login cancelled'));
        }
      }
    });

    // 2. Build Google OAuth Consent URL
    final authUrl = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'response_type': 'code',
      'scope': scopes.join(' '),
      'access_type': 'offline',
      'prompt': 'consent',
      'include_granted_scopes': 'true',
    });

    // 3. Launch browser
    try {
      if (await canLaunchUrl(authUrl)) {
        await launchUrl(authUrl, mode: LaunchMode.externalApplication);
      } else {
        if (Platform.isWindows) {
          await Process.run('cmd', ['/c', 'start', authUrl.toString()]);
        } else if (Platform.isMacOS) {
          await Process.run('open', [authUrl.toString()]);
        }
      }
    } catch (e) {
      debugPrint('Failed to open browser: $e');
    }

    // 4. Wait for authorization code
    final code = await completer.future.timeout(
      const Duration(minutes: 3),
      onTimeout: () {
        _authServer?.close(force: true);
        throw TimeoutException('Batas waktu login Google OAuth telah habis (3 menit).');
      },
    );

    await _authServer?.close(force: true);

    // 5. Exchange code for access & refresh tokens
    final tokenRes = await http.post(
      Uri.parse('https://oauth2.googleapis.com/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'authorization_code',
        'code': code,
        'client_id': clientId,
        'client_secret': clientSecret,
        'redirect_uri': redirectUri,
      },
    );

    if (tokenRes.statusCode != 200) {
      throw Exception('Gagal menukar token OAuth: ${tokenRes.body}');
    }

    final tokenJson = jsonDecode(tokenRes.body) as Map<String, dynamic>;
    final accessToken = tokenJson['access_token'] as String;
    final refreshToken = tokenJson['refresh_token'] as String? ?? '';
    final expiresIn = tokenJson['expires_in'] as int? ?? 3600;
    final expiryTimestamp = DateTime.now().millisecondsSinceEpoch + (expiresIn * 1000);

    // 6. Fetch Google User Profile
    final userRes = await http.get(
      Uri.parse('https://www.googleapis.com/oauth2/v2/userinfo'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    String email = 'Antigravity User';
    String name = 'Google Developer';
    String picture = '';

    if (userRes.statusCode == 200) {
      final userJson = jsonDecode(userRes.body) as Map<String, dynamic>;
      email = userJson['email'] as String? ?? email;
      name = userJson['name'] as String? ?? name;
      picture = userJson['picture'] as String? ?? '';
    }

    final profile = AntigravityOAuthProfile(
      email: email,
      name: name,
      picture: picture,
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiryTimestamp: expiryTimestamp,
    );

    await _saveProfile(profile);
    _currentProfile = profile;
    return profile;
  }

  /// Refresh Expired Access Token
  Future<String> refreshAccessToken({
    String clientId = defaultClientId,
    String clientSecret = defaultClientSecret,
  }) async {
    if (_currentProfile == null || _currentProfile!.refreshToken.isEmpty) {
      throw Exception('Tidak ada refresh token tersimpan. Silakan login ulang via OAuth.');
    }

    final res = await http.post(
      Uri.parse('https://oauth2.googleapis.com/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': _currentProfile!.refreshToken,
        'client_id': clientId,
        'client_secret': clientSecret,
      },
    );

    if (res.statusCode != 200) {
      throw Exception('Gagal memperbarui access token: ${res.body}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final newAccessToken = data['access_token'] as String;
    final expiresIn = data['expires_in'] as int? ?? 3600;
    final newExpiry = DateTime.now().millisecondsSinceEpoch + (expiresIn * 1000);

    final updated = AntigravityOAuthProfile(
      email: _currentProfile!.email,
      name: _currentProfile!.name,
      picture: _currentProfile!.picture,
      accessToken: newAccessToken,
      refreshToken: _currentProfile!.refreshToken,
      expiryTimestamp: newExpiry,
    );

    await _saveProfile(updated);
    _currentProfile = updated;
    return newAccessToken;
  }

  /// Get Valid Access Token (Auto-refresh if expired)
  Future<String> getValidAccessToken() async {
    if (_currentProfile == null) {
      throw Exception('Belum login ke Google Antigravity. Silakan klik "Start OAuth Google" di Pengaturan.');
    }
    if (_currentProfile!.isExpired && _currentProfile!.refreshToken.isNotEmpty) {
      return await refreshAccessToken();
    }
    return _currentProfile!.accessToken;
  }

  Future<void> _saveProfile(AntigravityOAuthProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProfile, jsonEncode(profile.toJson()));
  }

  Future<void> signOut() async {
    _currentProfile = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyProfile);
  }
}
