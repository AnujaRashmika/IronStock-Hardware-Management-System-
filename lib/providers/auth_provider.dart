import 'package:flutter/material.dart';
import '../models/user.dart';
import '../repositories/user_repository.dart';

class AuthProvider extends ChangeNotifier {
  final _repo = UserRepository();
  User? _user;
  bool _initialized = false;
  bool _loading = false;
  String? _error;

  User? get currentUser => _user;
  bool get isAuthenticated => _user != null;
  bool get initialized => _initialized;
  bool get isLoading => _loading;
  String? get errorMessage => _error;
  bool get isAdmin => _user?.isAdmin ?? false;

  Future<void> initialize() async {
    _initialized = true;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final u = await _repo.login(username.trim(), password);
      if (u == null) {
        _error = 'Invalid username or password';
        _loading = false;
        notifyListeners();
        return false;
      }
      _user = u;
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _user = null;
    notifyListeners();
  }
}
