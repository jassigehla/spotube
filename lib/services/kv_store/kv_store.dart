import 'dart:convert';

import 'package:encrypt/encrypt.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spotube/collections/vars.dart';
import 'package:spotube/models/database/database.dart';
import 'package:spotube/services/wm_tools/wm_tools.dart';
import 'package:uuid/uuid.dart';

final class KVStoreService {
  factory KVStoreService() {
    return getIt<KVStoreService>();
  }

  KVStoreService.init();

  SharedPreferences get sharedPreferences => getIt<SharedPreferences>();

  bool get doneGettingStarted =>
      sharedPreferences.getBool('doneGettingStarted') ?? false;
  Future<void> setDoneGettingStarted(bool value) async =>
      await sharedPreferences.setBool('doneGettingStarted', value);

  bool get askedForBatteryOptimization =>
      sharedPreferences.getBool('askedForBatteryOptimization') ?? false;
  Future<void> setAskedForBatteryOptimization(bool value) async =>
      await sharedPreferences.setBool('askedForBatteryOptimization', value);

  List<String> get recentSearches =>
      sharedPreferences.getStringList('recentSearches') ?? [];

  Future<void> setRecentSearches(List<String> value) async =>
      await sharedPreferences.setStringList('recentSearches', value);

  WindowSize? get windowSize {
    final raw = sharedPreferences.getString('windowSize');

    if (raw == null) {
      return null;
    }
    return WindowSize.fromJson(jsonDecode(raw));
  }

  Future<void> setWindowSize(WindowSize value) async =>
      await sharedPreferences.setString(
        'windowSize',
        jsonEncode(
          value.toJson(),
        ),
      );

  String get encryptionKey {
    final value = sharedPreferences.getString('encryption');

    final key = const Uuid().v4();
    if (value == null) {
      setEncryptionKey(key);
      return key;
    }

    return value;
  }

  Future<void> setEncryptionKey(String key) async {
    await sharedPreferences.setString('encryption', key);
  }

  IV get ivKey {
    final iv = sharedPreferences.getString('iv');
    final value = IV.fromSecureRandom(8);

    if (iv == null) {
      setIVKey(value);

      return value;
    }

    return IV.fromBase64(iv);
  }

  Future<void> setIVKey(IV iv) async {
    await sharedPreferences.setString('iv', iv.base64);
  }

  double get volume => sharedPreferences.getDouble('volume') ?? 1.0;
  Future<void> setVolume(double value) async =>
      await sharedPreferences.setDouble('volume', value);

  bool get hasMigratedToDrift =>
      sharedPreferences.getBool('hasMigratedToDrift') ?? false;
  Future<void> setHasMigratedToDrift(bool value) async =>
      await sharedPreferences.setBool('hasMigratedToDrift', value);

  Map<String, dynamic>? get _youtubeEnginePaths {
    final jsonRaw = sharedPreferences.getString('ytDlpPath');

    if (jsonRaw == null) {
      return null;
    }

    return jsonDecode(jsonRaw);
  }

  String? getYoutubeEnginePath(YoutubeClientEngine engine) {
    return _youtubeEnginePaths?[engine.name];
  }

  Future<void> setYoutubeEnginePath(
    YoutubeClientEngine engine,
    String path,
  ) async {
    await sharedPreferences.setString(
      'ytDlpPath',
      jsonEncode({
        ...?_youtubeEnginePaths,
        engine.name: path,
      }),
    );
  }
}
