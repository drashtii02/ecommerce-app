import 'dart:convert';
import 'package:get_storage/get_storage.dart';

class LocalStorage {
  final GetStorage _box = GetStorage();

  Future<void> write(String key, dynamic value) async {
    await _box.write(key, value);
  }

  T? read<T>(String key) {
    return _box.read<T>(key);
  }

  Future<void> remove(String key) async {
    await _box.remove(key);
  }

  Future<void> writeJson(String key, dynamic data) async {
    final jsonString = json.encode(data);
    await _box.write(key, jsonString);
  }

  dynamic readJson(String key) {
    final jsonString = _box.read<String>(key);
    if (jsonString == null) return null;
    return json.decode(jsonString);
  }
}
