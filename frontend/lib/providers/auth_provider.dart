import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/history_model.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;

  final _api = ApiService();

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _error = null;
    try {
      final data = await _api.login(email, password);
      await ApiService.saveToken(data['access_token']);
      _user = UserModel.fromJson(data['user']);
      notifyListeners();
      return true;
    } catch (e) {
      _error = _parseError(e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(String fullName, String email, String password) async {
    _setLoading(true);
    _error = null;
    try {
      final data = await _api.register(
          fullName: fullName, email: email, password: password);
      await ApiService.saveToken(data['access_token']);
      _user = UserModel.fromJson(data['user']);
      notifyListeners();
      return true;
    } catch (e) {
      _error = _parseError(e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> tryAutoLogin() async {
    if (!await ApiService.hasToken()) return;
    try {
      final data = await _api.getMe();
      _user = UserModel.fromJson(data);
      notifyListeners();
    } catch (_) {
      await ApiService.clearToken();
    }
  }

  Future<void> logout() async {
    await ApiService.clearToken();
    _user = null;
    notifyListeners();
  }

  String _parseError(dynamic e) {
    try {
      final msg = (e as dynamic).response?.data?['detail'];
      if (msg != null) return msg.toString();
    } catch (_) {}
    return e.toString();
  }
}

class AnalysisProvider extends ChangeNotifier {
  Map<String, dynamic>? _lastResult;
  bool _isLoading = false;
  String? _error;
  List<HistoryModel> _history = [];

  Map<String, dynamic>? get lastResult => _lastResult;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<HistoryModel> get history => _history;

  final _api = ApiService();

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  Future<bool> uploadFile({
    String? filePath,
    Uint8List? fileBytes,
    required String fileName,
    required String mimeType,
    bool enhance = false,
    String mode = 'auto',
  }) async {
    _setLoading(true);
    _error = null;
    try {
      _lastResult = await _api.uploadAndAnalyze(
        filePath: filePath,
        fileBytes: fileBytes,
        fileName: fileName,
        mimeType: mimeType,
        enhance: enhance,
        mode: mode,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadHistory({String? lang, String? search}) async {
    try {
      _history = await _api.getHistory(lang: lang, search: search);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> deleteHistory(int id) async {
    await _api.deleteHistory(id);
    _history.removeWhere((h) => h.id == id);
    notifyListeners();
  }

  void clearResult() {
    _lastResult = null;
    notifyListeners();
  }
}
