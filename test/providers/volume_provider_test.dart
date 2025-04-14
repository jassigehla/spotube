import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spotube/collections/vars.dart';
import 'package:spotube/provider/volume_provider.dart';
import 'package:spotube/services/audio_player/audio_player.dart';
import 'package:spotube/services/kv_store/kv_store.dart';

class MockSpotubeAudioPlayer extends Mock implements SpotubeAudioPlayer {}

class MockKVStoreService extends Mock implements KVStoreService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late SpotubeAudioPlayer audioPlayer;
  late KVStoreService kvStoreService;

  setUp(() {
    kvStoreService =
        getIt.registerSingleton<KVStoreService>(MockKVStoreService());
    audioPlayer =
        getIt.registerSingleton<SpotubeAudioPlayer>(MockSpotubeAudioPlayer());
    container = ProviderContainer();

    when(() => kvStoreService.volume).thenAnswer((_) => 1.0);
    when(() => kvStoreService.setVolume(any())).thenAnswer((_) async {});
    when(() => audioPlayer.setVolume(any())).thenAnswer((_) async {});
  });

  tearDown(() {
    getIt.reset();
    container.dispose();
  });

  group("VolumeProvider", () {
    test("initial volume should be 1", () {
      final volume = container.read(volumeProvider);

      expect(volume, 1.0);
    });

    group("setVolume", () {
      test("should set volume to specified value", () async {
        await container.read(volumeProvider.notifier).setVolume(0.5);

        final volume = container.read(volumeProvider);
        expect(volume, 0.5);
      });
      test("should update audioPlayer volume", () {
        container.read(volumeProvider.notifier).setVolume(0.5);

        verify(() => audioPlayer.setVolume(0.5)).called(1);
      });
      test("should persist the volume", () async {
        await container.read(volumeProvider.notifier).setVolume(0.5);

        verify(() => kvStoreService.setVolume(0.5)).called(1);
      });
    });
  });
}
