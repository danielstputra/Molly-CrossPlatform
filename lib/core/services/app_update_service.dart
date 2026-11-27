import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'local_storage_service.dart';
import 'molly_background_service.dart';

class GitHubReleaseAsset {
  final String name;
  final String downloadUrl;
  final int size;

  const GitHubReleaseAsset({
    required this.name,
    required this.downloadUrl,
    required this.size,
  });

  String get formattedSize {
    if (size <= 0) return '0 B';
    final mb = size / (1024 * 1024);
    return '${mb.toStringAsFixed(2)} MB';
  }
}

class GitHubRelease {
  final String tagName;
  final String name;
  final String body;
  final DateTime publishedAt;
  final String htmlUrl;
  final List<GitHubReleaseAsset> assets;

  const GitHubRelease({
    required this.tagName,
    required this.name,
    required this.body,
    required this.publishedAt,
    required this.htmlUrl,
    required this.assets,
  });

  String? get apkDownloadUrl {
    final apk = assets.firstWhere(
      (a) => a.name.toLowerCase().endsWith('.apk'),
      orElse: () => const GitHubReleaseAsset(name: '', downloadUrl: '', size: 0),
    );
    return apk.downloadUrl.isNotEmpty ? apk.downloadUrl : null;
  }

  String? get ipaDownloadUrl {
    final ipa = assets.firstWhere(
      (a) => a.name.toLowerCase().endsWith('.ipa'),
      orElse: () => const GitHubReleaseAsset(name: '', downloadUrl: '', size: 0),
    );
    return ipa.downloadUrl.isNotEmpty ? ipa.downloadUrl : null;
  }

  String get formattedDate {
    return '${publishedAt.day.toString().padLeft(2, '0')}/${publishedAt.month.toString().padLeft(2, '0')}/${publishedAt.year} ${publishedAt.hour.toString().padLeft(2, '0')}:${publishedAt.minute.toString().padLeft(2, '0')}';
  }

  factory GitHubRelease.fromJson(Map<String, dynamic> json) {
    final assetList = <GitHubReleaseAsset>[];
    if (json['assets'] != null && json['assets'] is List) {
      for (final a in json['assets']) {
        assetList.add(GitHubReleaseAsset(
          name: a['name'] as String? ?? '',
          downloadUrl: a['browser_download_url'] as String? ?? '',
          size: a['size'] as int? ?? 0,
        ));
      }
    }

    DateTime pubDate = DateTime.now();
    if (json['published_at'] != null) {
      try {
        pubDate = DateTime.parse(json['published_at'] as String);
      } catch (_) {}
    }

    return GitHubRelease(
      tagName: json['tag_name'] as String? ?? 'v2.6.0',
      name: json['name'] as String? ?? 'Molly AI Studio Release',
      body: json['body'] as String? ?? 'Pembaruan stabilitas dan peningkatan fitur.',
      publishedAt: pubDate,
      htmlUrl: json['html_url'] as String? ?? 'https://github.com/danielstputra/Molly-CrossPlatform/releases',
      assets: assetList,
    );
  }
}

class AppUpdateCheckResult {
  final bool isUpdateAvailable;
  final GitHubRelease? latestRelease;
  final String currentVersionTag;
  final String? errorMessage;

  const AppUpdateCheckResult({
    required this.isUpdateAvailable,
    this.latestRelease,
    required this.currentVersionTag,
    this.errorMessage,
  });
}

class AppUpdateService {
  AppUpdateService._();
  static final AppUpdateService instance = AppUpdateService._();

  // Versi rilis aplikasi saat ini
  static const String currentVersion = '2.6.0';
  static const String currentTag = 'v2.6.0-20261127-0756';

  static const String _repoOwner = 'danielstputra';
  static const String _repoName = 'Molly-CrossPlatform';

  GitHubRelease? _latestKnownRelease;
  GitHubRelease? get latestKnownRelease => _latestKnownRelease;

  /// Mengambil daftar riwayat changelog rilis dari GitHub
  Future<List<GitHubRelease>> fetchChangelogHistory({int limit = 15}) async {
    final url = Uri.parse('https://api.github.com/repos/$_repoOwner/$_repoName/releases?per_page=$limit');
    try {
      final res = await http.get(
        url,
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'MollyAIStudio-CrossPlatform',
        },
      ).timeout(const Duration(seconds: 12));

      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        return list.map((item) => GitHubRelease.fromJson(item as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Gagal memuat changelog (HTTP ${res.statusCode})');
      }
    } catch (e) {
      debugPrint('[AppUpdateService] fetchChangelogHistory error: $e');
      rethrow;
    }
  }

  /// Memeriksa apakah ada rilis versi terbaru di GitHub Releases
  Future<AppUpdateCheckResult> checkForUpdates({bool notifyIfAvailable = false}) async {
    final url = Uri.parse('https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest');
    try {
      final res = await http.get(
        url,
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'MollyAIStudio-CrossPlatform',
        },
      ).timeout(const Duration(seconds: 12));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final release = GitHubRelease.fromJson(json);
        _latestKnownRelease = release;

        // Bandingkan tag versi
        final isNewer = _isVersionTagNewer(release.tagName, currentTag);

        if (isNewer && notifyIfAvailable) {
          await MollyBackgroundService.instance.notifyAppUpdateAvailable(
            newVersion: release.tagName,
            releaseNotes: release.name,
          );
        }

        return AppUpdateCheckResult(
          isUpdateAvailable: isNewer,
          latestRelease: release,
          currentVersionTag: currentTag,
        );
      } else {
        // Fallback coba ambil dari endpoint list jika latest 404 (misal draft/prerelease)
        final history = await fetchChangelogHistory(limit: 1);
        if (history.isNotEmpty) {
          final release = history.first;
          _latestKnownRelease = release;
          final isNewer = _isVersionTagNewer(release.tagName, currentTag);

          if (isNewer && notifyIfAvailable) {
            await MollyBackgroundService.instance.notifyAppUpdateAvailable(
              newVersion: release.tagName,
              releaseNotes: release.name,
            );
          }

          return AppUpdateCheckResult(
            isUpdateAvailable: isNewer,
            latestRelease: release,
            currentVersionTag: currentTag,
          );
        }

        return AppUpdateCheckResult(
          isUpdateAvailable: false,
          currentVersionTag: currentTag,
          errorMessage: 'Respon GitHub HTTP ${res.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('[AppUpdateService] checkForUpdates error: $e');
      return AppUpdateCheckResult(
        isUpdateAvailable: false,
        currentVersionTag: currentTag,
        errorMessage: e.toString(),
      );
    }
  }

  /// Membandingkan tag rilis GitHub (misal v2.6.0-20261127-0756 vs v2.6.0-20261127-0736)
  bool _isVersionTagNewer(String remoteTag, String currentTag) {
    if (remoteTag.trim().toLowerCase() == currentTag.trim().toLowerCase()) {
      return false;
    }

    // Ekstrak timestamp dari tag: v2.6.0-YYYYMMDD-HHMM
    final regex = RegExp(r'(\d{8})-(\d{4})');
    final remoteMatch = regex.firstMatch(remoteTag);
    final currentMatch = regex.firstMatch(currentTag);

    if (remoteMatch != null && currentMatch != null) {
      final remoteTs = '${remoteMatch.group(1)}${remoteMatch.group(2)}';
      final currentTs = '${currentMatch.group(1)}${currentMatch.group(2)}';
      return remoteTs.compareTo(currentTs) > 0;
    }

    // Fallback: Jika string berbeda dan bukan tag yang sama
    return remoteTag != currentTag;
  }

  /// Membuka tautan download langsung untuk paket APK / IPA
  Future<bool> launchDownload(GitHubRelease release) async {
    String? targetUrl;

    if (!kIsWeb && Platform.isAndroid) {
      targetUrl = release.apkDownloadUrl;
    } else if (!kIsWeb && Platform.isIOS) {
      targetUrl = release.ipaDownloadUrl;
    }

    targetUrl ??= release.htmlUrl;

    try {
      final uri = Uri.parse(targetUrl);
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('[AppUpdateService] launchDownload error: $e');
      return false;
    }
  }
}
