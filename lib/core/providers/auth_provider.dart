import 'package:flutter/material.dart';
import 'package:portal_assoc/features/auth/data/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  bool _showForgotPassword = false;
  bool get showForgotPassword => _showForgotPassword;

  int _month = DateTime.now().month;
  int get month => _month;

  int _year = DateTime.now().year;
  int get year => _year;

  String? _accessToken;
  String? get accessToken => _accessToken;

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  int _type = -1;
  int get type => _type;

  int _company = 0;
  int get company => _company;

  AuthProvider() {
    _loadState();
  }

  Future<void> setAccessToken(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', user.accessToken);
    await prefs.setInt('type', user.type);
    _accessToken = user.accessToken;
    _type = user.type;
    _isLoggedIn = true;
    loadType();
    notifyListeners();
  }

  Future<void> setCompany(int company) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('company', company);
    _company = company;
    notifyListeners();
  }

  Future<void> loadCompany() async {
    final prefs = await SharedPreferences.getInstance();
    _company = prefs.getInt('company') ?? 0;
    notifyListeners();
  }

  Future<void> setYear(int month) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('year', year);
    _year = year;
  }

  Future<void> loadAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    notifyListeners();
  }

  Future<void> loadType() async {
    final prefs = await SharedPreferences.getInstance();
    _type = prefs.getInt('type') ?? -1;
    notifyListeners();
  }

  void setForgotPassword(bool value) async {
    _showForgotPassword = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showForgotPassword', value);
    notifyListeners();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    _showForgotPassword = prefs.getBool('showForgotPassword') ?? false;
    _accessToken = prefs.getString('access_token');

    _isLoggedIn = _accessToken != null && _accessToken!.isNotEmpty;

    _month = prefs.getInt('month') ?? DateTime.now().month;
    _year = prefs.getInt('year') ?? DateTime.now().year;
    _type = prefs.getInt('type') ?? -1;
    _company = prefs.getInt('company') ?? 0;

    notifyListeners();
  }

  Future<void> logout() async {
    _accessToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _accessToken = null;
    _month = DateTime.now().month;
    _year = DateTime.now().year;
    _type = -1;
    _company = 0;
    _isLoggedIn = false;

    notifyListeners();
  }
}
