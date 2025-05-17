import 'package:drift/drift.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart' as paths;
import 'package:shadcn_flutter/shadcn_flutter.dart' hide join;
import 'package:spotify/spotify.dart';
import 'package:spotube/collections/vars.dart';
import 'package:spotube/models/database/database.dart';
import 'package:spotube/modules/settings/color_scheme_picker_dialog.dart';
import 'package:spotube/provider/user_preferences/default_download_dir_provider.dart';
import 'package:spotube/services/audio_player/audio_player.dart';
import 'package:spotube/services/logger/logger.dart';
import 'package:spotube/services/sourced_track/enums.dart';
import 'package:spotube/utils/platform.dart';
import 'package:window_manager/window_manager.dart';
import 'package:open_file/open_file.dart';

typedef UserPreferences = PreferencesTableData;

class UserPreferencesNotifier extends Notifier<PreferencesTableData> {
  AppDatabase get db => getIt.get<AppDatabase>();

  @override
  build() {
    (db.select(db.preferencesTable)..where((tbl) => tbl.id.equals(0)))
        .getSingleOrNull()
        .then((result) async {
      if (result == null) {
        await db.into(db.preferencesTable).insert(
              PreferencesTableCompanion.insert(
                id: const Value(0),
                downloadLocation: Value(
                  await ref.read(defaultDownloadDirectoryProvider.future),
                ),
              ),
            );
      }

      state = await (db.select(db.preferencesTable)
            ..where((tbl) => tbl.id.equals(0)))
          .getSingle();

      final subscription = (db.select(db.preferencesTable)
            ..where((tbl) => tbl.id.equals(0)))
          .watchSingle()
          .listen((event) async {
        try {
          state = event;

          if (kIsDesktop) {
            await getIt.get<WindowManager>().setTitleBarStyle(
                  state.systemTitleBar
                      ? TitleBarStyle.normal
                      : TitleBarStyle.hidden,
                );
          }

          await audioPlayer.setAudioNormalization(state.normalizeAudio);
        } catch (e, stack) {
          AppLogger.reportError(e, stack);
        }
      });

      ref.onDispose(() {
        subscription.cancel();
      });
    });

    return PreferencesTable.defaults();
  }

  // Future<String> _getDefaultDownloadDirectory() async {
  //   if (kIsAndroid) return "/storage/emulated/0/Download/Spotube";

  //   if (kIsMacOS) {
  //     return join((await paths.getLibraryDirectory()).path, "Caches");
  //   }

  //   return paths.getDownloadsDirectory().then((dir) {
  //     return join(dir!.path, "Spotube");
  //   });
  // }

  Future<void> setData(PreferencesTableCompanion data) async {
    final query = db.update(db.preferencesTable)..where((t) => t.id.equals(0));

    await query.write(data);
  }

  Future<void> reset() async {
    final query = db.update(db.preferencesTable);

    await query.replace(PreferencesTableCompanion.insert(id: const Value(0)));
  }

  static Future<String> getMusicCacheDir() async {
    if (kIsAndroid) {
      final dir =
          await paths.getExternalCacheDirectories().then((dirs) => dirs!.first);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return join(dir.path, 'Cached Tracks');
    }

    final dir = await paths.getApplicationCacheDirectory();
    return join(dir.path, 'cached_tracks');
  }

  Future<void> openCacheFolder() async {
    try {
      final filePath = await getMusicCacheDir();

      await OpenFile.open(filePath);
    } catch (e, stack) {
      AppLogger.reportError(e, stack);
    }
  }

  void setStreamMusicCodec(SourceCodecs codec) {
    setData(PreferencesTableCompanion(streamMusicCodec: Value(codec)));
  }

  Future<void> setDownloadMusicCodec(SourceCodecs codec) async {
    await setData(PreferencesTableCompanion(downloadMusicCodec: Value(codec)));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await setData(PreferencesTableCompanion(themeMode: Value(mode)));
  }

  Future<void> setRecommendationMarket(Market country) async {
    await setData(PreferencesTableCompanion(market: Value(country)));
  }

  Future<void> setAccentColorScheme(SpotubeColor color) async {
    await setData(PreferencesTableCompanion(accentColorScheme: Value(color)));
  }

  Future<void> setAlbumColorSync(bool sync) async {
    await setData(PreferencesTableCompanion(albumColorSync: Value(sync)));

    // if (!sync) {
    //   ref.read(paletteProvider.notifier).state = null;
    // } else {
    //   ref.read(audioPlayerStreamListenersProvider).updatePalette();
    // }
  }

  Future<void> setCheckUpdate(bool check) async {
    await setData(PreferencesTableCompanion(checkUpdate: Value(check)));
  }

  Future<void> setAudioQuality(SourceQualities quality) async {
    await setData(PreferencesTableCompanion(audioQuality: Value(quality)));
  }

  Future<void> setDownloadLocation(String downloadDir) async {
    if (downloadDir.isEmpty) return;
    await setData(
        PreferencesTableCompanion(downloadLocation: Value(downloadDir)));
  }

  Future<void> setLocalLibraryLocation(List<String> localLibraryDirs) async {
    await setData(
      PreferencesTableCompanion(
        localLibraryLocation: Value(localLibraryDirs),
      ),
    );
  }

  Future<void> setLayoutMode(LayoutMode mode) async {
    await setData(PreferencesTableCompanion(layoutMode: Value(mode)));
  }

  Future<void> setCloseBehavior(CloseBehavior behavior) async {
    await setData(PreferencesTableCompanion(closeBehavior: Value(behavior)));
  }

  Future<void> setShowSystemTrayIcon(bool show) async {
    await setData(PreferencesTableCompanion(showSystemTrayIcon: Value(show)));
  }

  Future<void> setLocale(Locale locale) async {
    await setData(PreferencesTableCompanion(locale: Value(locale)));
  }

  Future<void> setPipedInstance(String instance) async {
    await setData(PreferencesTableCompanion(pipedInstance: Value(instance)));
  }

  void setInvidiousInstance(String instance) {
    setData(PreferencesTableCompanion(invidiousInstance: Value(instance)));
  }

  void setSearchMode(SearchMode mode) {
    setData(PreferencesTableCompanion(searchMode: Value(mode)));
  }

  Future<void> setSkipNonMusic(bool skip) async {
    await setData(PreferencesTableCompanion(skipNonMusic: Value(skip)));
  }

  Future<void> setAudioSource(AudioSource type) async {
    await setData(PreferencesTableCompanion(audioSource: Value(type)));
  }

  void setYoutubeClientEngine(YoutubeClientEngine engine) {
    setData(PreferencesTableCompanion(youtubeClientEngine: Value(engine)));
  }

  void setSystemTitleBar(bool isSystemTitleBar) {
    setData(
      PreferencesTableCompanion(
        systemTitleBar: Value(isSystemTitleBar),
      ),
    );
  }

  Future<void> setDiscordPresence(bool discordPresence) async {
    await setData(
        PreferencesTableCompanion(discordPresence: Value(discordPresence)));
  }

  Future<void> setAmoledDarkTheme(bool isAmoled) async {
    await setData(PreferencesTableCompanion(amoledDarkTheme: Value(isAmoled)));
  }

  Future<void> setNormalizeAudio(bool normalize) async {
    await setData(PreferencesTableCompanion(normalizeAudio: Value(normalize)));
    audioPlayer.setAudioNormalization(normalize);
  }

  Future<void> setEndlessPlayback(bool endless) async {
    await setData(PreferencesTableCompanion(endlessPlayback: Value(endless)));
  }

  void setEnableConnect(bool enable) {
    setData(PreferencesTableCompanion(enableConnect: Value(enable)));
  }

  void setConnectPort(int port) {
    assert(
      port >= -1 && port <= 65535,
      "Port must be between -1 and 65535, got $port",
    );
    setData(PreferencesTableCompanion(connectPort: Value(port)));
  }

  void setCacheMusic(bool cache) {
    setData(PreferencesTableCompanion(cacheMusic: Value(cache)));
  }
}

final userPreferencesProvider =
    NotifierProvider<UserPreferencesNotifier, PreferencesTableData>(
  () => UserPreferencesNotifier(),
);
