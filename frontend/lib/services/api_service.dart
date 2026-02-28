import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/history_model.dart';

class ApiService {
  static const String _baseUrl = 'http://localhost:8000';
  static final _storage = const FlutterSecureStorage();
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      contentType: Headers.jsonContentType,
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (e, handler) {
        if (e.response?.statusCode == 401) {
          _storage.delete(key: 'access_token');
        }
        return handler.next(e);
      },
    ));
  }

  // --- Auth ---
  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final response = await _dio.post('/api/auth/register', data: {
      'full_name': fullName,
      'email': email,
      'password': password,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post('/api/auth/login', data: {
      'email': email,
      'password': password,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await _dio.get('/api/auth/me');
    return response.data;
  }

  // --- Upload & Analysis ---
  Future<Map<String, dynamic>> uploadAndAnalyze({
    String? filePath,
    Uint8List? fileBytes,
    required String fileName,
    required String mimeType,
    bool enhance = false,
    String mode = 'auto',
  }) async {
    MultipartFile fileData;
    if (fileBytes != null) {
      fileData = MultipartFile.fromBytes(fileBytes, filename: fileName, contentType: DioMediaType.parse(mimeType));
    } else if (filePath != null) {
      fileData = await MultipartFile.fromFile(filePath, filename: fileName, contentType: DioMediaType.parse(mimeType));
    } else {
      throw Exception('Fayl yoki ma`lumotlar topilmadi.');
    }

    final formData = FormData.fromMap({
      'file': fileData,
      'enhance': enhance.toString(),
      'mode': mode,
    });
    final response = await _dio.post('/api/upload', data: formData,
        options: Options(contentType: 'multipart/form-data'));
    return response.data;
  }

  Future<Map<String, dynamic>> detectLanguage(String text, {String mode = 'auto'}) async {
    final formData = FormData.fromMap({'text': text, 'mode': mode});
    final response = await _dio.post('/api/detect-language', data: formData,
        options: Options(contentType: 'multipart/form-data'));
    return response.data;
  }

  Future<Map<String, dynamic>> analyzeText(String text, {String mode = 'auto'}) async {
    final formData = FormData.fromMap({'text': text, 'mode': mode});
    final response = await _dio.post('/api/analyze', data: formData,
        options: Options(contentType: 'multipart/form-data'));
    return response.data;
  }

  // --- History ---
  Future<List<HistoryModel>> getHistory({
    int skip = 0,
    int limit = 20,
    String? lang,
    String? search,
  }) async {
    final params = <String, dynamic>{'skip': skip, 'limit': limit};
    if (lang != null) params['lang'] = lang;
    if (search != null) params['search'] = search;
    final response = await _dio.get('/api/history/', queryParameters: params);
    return (response.data as List).map((e) => HistoryModel.fromJson(e)).toList();
  }

  Future<void> deleteHistory(int id) async {
    await _dio.delete('/api/history/$id');
  }

  // --- Admin ---
  Future<Map<String, dynamic>> getStats() async {
    final response = await _dio.get('/api/admin/stats');
    return response.data;
  }

  // --- Feedback ---
  Future<void> submitFeedback({
    required int historyId,
    String? comment,
    String? correctLang,
  }) async {
    await _dio.post('/api/feedback/', data: {
      'history_id': historyId,
      if (comment != null) 'comment': comment,
      if (correctLang != null) 'correct_lang': correctLang,
    });
  }

  // --- Token management ---
  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'access_token', value: token);
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: 'access_token');
  }

  static Future<bool> hasToken() async {
    final token = await _storage.read(key: 'access_token');
    return token != null && token.isNotEmpty;
  }
}
