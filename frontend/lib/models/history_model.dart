import 'dart:convert';

class HistoryModel {
  final int id;
  final String filename;
  final String fileType;
  final String? detectedLang;
  final double? langConfidence;
  final String? ocrText;
  final String? summary;
  final String? keywords;
  final String? category;
  final int? wordCount;
  final int? sentenceCount;
  final DateTime createdAt;

  HistoryModel({
    required this.id,
    required this.filename,
    required this.fileType,
    this.detectedLang,
    this.langConfidence,
    this.ocrText,
    this.summary,
    this.keywords,
    this.category,
    this.wordCount,
    this.sentenceCount,
    required this.createdAt,
  });

  factory HistoryModel.fromJson(Map<String, dynamic> json) {
    return HistoryModel(
      id: json['id'],
      filename: json['filename'] ?? '',
      fileType: json['file_type'] ?? 'image',
      detectedLang: json['detected_lang'],
      langConfidence: (json['lang_confidence'] as num?)?.toDouble(),
      ocrText: json['ocr_text'],
      summary: json['summary'],
      keywords: json['keywords'],
      category: json['category'],
      wordCount: json['word_count'],
      sentenceCount: json['sentence_count'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  List<String> get keywordsList {
    if (keywords == null) return [];
    try {
      return List<String>.from(jsonDecode(keywords!));
    } catch (_) {
      return keywords!.split(',').map((e) => e.trim()).toList();
    }
  }

  String get langBadge => detectedLang ?? 'N/A';
  int get confidencePercent => ((langConfidence ?? 0) * 100).round();
}

class UserModel {
  final int id;
  final String fullName;
  final String email;
  final String role;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      createdAt: _parseDate(json['created_at']),
    );
  }

  static DateTime _parseDate(dynamic date) {
    if (date == null) return DateTime.now();
    try {
      return DateTime.parse(date.toString());
    } catch (_) {
      return DateTime.now();
    }
  }

  bool get isAdmin => role == 'admin';
}
