class KnowledgeDataset {
  final String id;
  final String name;
  final String description;
  final int documentCount;
  final int chunkCount;
  final String embeddingModel;
  final DateTime updatedAt;

  const KnowledgeDataset({
    required this.id,
    required this.name,
    required this.description,
    this.documentCount = 0,
    this.chunkCount = 0,
    this.embeddingModel = 'text-embedding-3-small',
    required this.updatedAt,
  });

  factory KnowledgeDataset.fromJson(Map<String, dynamic> json) {
    return KnowledgeDataset(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Basis Pengetahuan',
      description: json['description'] ?? 'Kumpulan dokumen referensi untuk RAG.',
      documentCount: json['document_count'] ?? json['docs_count'] ?? 0,
      chunkCount: json['chunk_count'] ?? json['chunks_count'] ?? 0,
      embeddingModel: json['embedding_model'] ?? 'text-embedding-3-small',
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
