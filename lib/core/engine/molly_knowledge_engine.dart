import 'dart:convert';
import 'dart:math';
import '../database/molly_local_database.dart';
import '../models/knowledge_base.dart';

class SearchResultChunk {
  final String docName;
  final String text;
  final double score;

  const SearchResultChunk({
    required this.docName,
    required this.text,
    required this.score,
  });
}

class MollyKnowledgeEngine {
  MollyKnowledgeEngine._();
  static final MollyKnowledgeEngine instance = MollyKnowledgeEngine._();

  final _db = MollyLocalDatabase.instance;

  /// Ingests a raw document into on-device SQLite with local chunking
  Future<void> ingestDocument({
    required String datasetId,
    required String docName,
    required String rawContent,
    int chunkSize = 350,
    int overlap = 50,
  }) async {
    // 1. Chunking
    final chunks = _chunkText(rawContent, chunkSize, overlap);

    // 2. Compute vectors & insert each chunk into local SQLite
    for (int i = 0; i < chunks.length; i++) {
      final chunkText = chunks[i];
      final vector = _computeLocalEmbedding(chunkText);

      await _db.insertChunk(
        id: 'chunk-${DateTime.now().millisecondsSinceEpoch}-$i',
        datasetId: datasetId,
        docName: docName,
        chunkText: chunkText,
        embedding: vector,
      );
    }
  }

  /// Performs local Vector Cosine Similarity Search directly on phone's SQLite
  Future<List<SearchResultChunk>> searchSimilarity({
    required String query,
    String? datasetId,
    int topK = 3,
  }) async {
    final queryVector = _computeLocalEmbedding(query);
    final rawChunks = await _db.getAllChunks(datasetId: datasetId);

    final scored = <SearchResultChunk>[];

    for (final row in rawChunks) {
      final docName = row['doc_name'] as String;
      final text = row['chunk_text'] as String;
      final rawEmbedding = row['embedding_json'] as String?;

      if (rawEmbedding != null && rawEmbedding.isNotEmpty) {
        try {
          final List decoded = jsonDecode(rawEmbedding);
          final vector = decoded.map((e) => (e as num).toDouble()).toList();
          final score = _cosineSimilarity(queryVector, vector);
          scored.add(SearchResultChunk(docName: docName, text: text, score: score));
        } catch (_) {}
      }
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(topK).toList();
  }

  List<String> _chunkText(String text, int size, int overlap) {
    final chunks = <String>[];
    int start = 0;

    while (start < text.length) {
      int end = start + size;
      if (end > text.length) end = text.length;

      final slice = text.substring(start, end).trim();
      if (slice.isNotEmpty) chunks.add(slice);

      if (end >= text.length) break;
      start += (size - overlap);
    }

    return chunks;
  }

  /// On-device pseudo-embedding generator using character & n-gram frequency distribution
  List<double> _computeLocalEmbedding(String text) {
    const dim = 64;
    final vector = List<double>.filled(dim, 0.0);
    final lower = text.toLowerCase();

    for (int i = 0; i < lower.length; i++) {
      final code = lower.codeUnitAt(i);
      final idx = code % dim;
      vector[idx] += 1.0;
    }

    // Normalize
    double norm = 0.0;
    for (final v in vector) {
      norm += v * v;
    }
    norm = sqrt(norm);

    if (norm > 0) {
      for (int i = 0; i < dim; i++) {
        vector[i] /= norm;
      }
    }

    return vector;
  }

  double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) return 0.0;
    double dot = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    final denom = sqrt(normA) * sqrt(normB);
    if (denom == 0) return 0.0;
    return dot / denom;
  }
}
