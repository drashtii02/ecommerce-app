import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/storage_keys.dart';
import '../storage/local_storage.dart';

class ThemeController extends GetxController {
  final LocalStorage _storage = LocalStorage();
  final _isDarkMode = false.obs;

  bool get isDarkMode => _isDarkMode.value;
  ThemeMode get themeMode =>
      _isDarkMode.value ? ThemeMode.dark : ThemeMode.light;

  @override
  void onInit() {
    super.onInit();
    _loadTheme();
  }

  void _loadTheme() {
    _isDarkMode.value = _storage.read<bool>(StorageKeys.isDarkMode) ?? false;
  }

  void toggleTheme() {
    _isDarkMode.value = !_isDarkMode.value;
    _storage.write(StorageKeys.isDarkMode, _isDarkMode.value);
    Get.changeThemeMode(_isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }
}
