import '../../core/constants/storage_keys.dart';
import '../../core/storage/local_storage.dart';

class AuthRepository {
  final LocalStorage _storage;

  AuthRepository(this._storage);

  bool isLoggedIn() {
    return _storage.read<bool>(StorageKeys.isLoggedIn) ?? false;
  }

  String? getUserName() {
    return _storage.read<String>(StorageKeys.userName);
  }

  Future<bool> login(String email, String password) async {
    // dummy auth - accept any non-empty credentials
    await Future.delayed(const Duration(seconds: 1));

    if (email.isNotEmpty && password.isNotEmpty) {
      await _storage.write(StorageKeys.isLoggedIn, true);
      await _storage.write(StorageKeys.userName, email.split('@').first);
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    await _storage.write(StorageKeys.isLoggedIn, false);
    await _storage.remove(StorageKeys.userName);
  }
}
