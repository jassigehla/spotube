import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spotube/collections/vars.dart';
import 'package:spotube/models/database/database.dart';
import 'package:spotube/provider/audio_player/audio_player_streams.dart';
import 'package:spotube/provider/user_preferences/default_download_dir_provider.dart';
import 'package:spotube/provider/user_preferences/user_preferences_provider.dart';
import 'package:spotube/services/audio_player/audio_player.dart';
import 'package:spotube/services/kv_store/kv_store.dart';
import 'package:spotube/services/logger/logger.dart';
import 'package:window_manager/window_manager.dart';

import '../create_container.dart';
import '../mocks/mocks.dart';

void main() {
  group('UserPreferences', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    late ProviderContainer container;
    late MockWindowManager mockWindowManager;

    setUpAll(() {
      registerFallbackValue(TitleBarStyle.normal);
      AppLogger.initialize(false);
    });

    setUp(() {
      mockWindowManager = MockWindowManager();

      getIt.registerSingleton<SpotubeAudioPlayer>(MockSpotubeAudioPlayer());
      getIt.registerSingleton<KVStoreService>(MockKVStoreService());
      getIt.registerSingleton<WindowManager>(mockWindowManager);
      getIt.registerLazySingleton(
        () {
          final database = AppDatabase(NativeDatabase.memory());

          addTearDown(() {
            database.close();
          });

          return database;
        },
      );

      container = createContainer(
        overrides: [
          audioPlayerStreamListenersProvider.overrideWith(
            (ref) {
              final streamListeners = MockAudioPlayerStreamListeners();

              return streamListeners;
            },
          ),
          defaultDownloadDirectoryProvider.overrideWith(
            (ref) {
              return Future.value("/storage/emulated/0/Download/Spotube");
            },
          ),
        ],
      );

      when(() => mockWindowManager.setTitleBarStyle(any()))
          .thenAnswer((_) async {});
    });

    tearDown(() {
      getIt.reset();
    });

    test('Initial value should be equal the default values', () {
      final preferences = container.read(userPreferencesProvider);
      final defaultPreferences = PreferencesTable.defaults();

      expect(preferences, defaultPreferences);
    });

    test('setSystemTitleBar should update UI titlebar', () async {
      when(() => audioPlayer.setAudioNormalization(any()))
          .thenAnswer((_) async {});

      final preferences = container.read(userPreferencesProvider);
      final preferencesNotifier =
          container.read(userPreferencesProvider.notifier);

      expect(preferences.systemTitleBar, false);

      preferencesNotifier.setSystemTitleBar(true);

      await Future.delayed(const Duration(milliseconds: 500));

      verify(() => mockWindowManager.setTitleBarStyle(TitleBarStyle.hidden))
          .called(1);
    });
  });
}
