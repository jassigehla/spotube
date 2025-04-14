import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:spotube/provider/volume_provider.dart';
import 'package:spotube/services/audio_player/audio_player.dart';
import 'package:spotube/services/kv_store/kv_store.dart';

void main() {
  late ProviderContainer container;
  late VolumeProvider volumeProvider;

  setUp(() {
    container = ProviderContainer();
    volumeProvider = container.read(volumeProvider.notifier);
  });

  tearDown(() {
    container.dispose();
  });

  test('initial volume is set from KVStore', () {
    expect(container.read(volumeProvider), KVStoreService().volume);
  });

  test('setVolume updates state and KVStore', () async {
    const testVolume = 0.75;
    await volumeProvider.setVolume(testVolume);

    expect(container.read(volumeProvider), testVolume);
    expect(KVStoreService().volume, testVolume);
  });

  test('setVolume updates audio player', () async {
    const testVolume = 0.5;
    await volumeProvider.setVolume(testVolume);

    // Verify that the audio player's volume was set
    // Note: This assumes audioPlayer.setVolume is properly mocked or can be verified
    expect(audioPlayer.volume, testVolume);
  });
}
