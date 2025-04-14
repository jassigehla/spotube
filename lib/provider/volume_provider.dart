import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:spotube/services/audio_player/audio_player.dart';
import 'package:spotube/services/kv_store/kv_store.dart';

class VolumeProvider extends Notifier<double> {
  final SpotubeAudioPlayer _audioPlayer;

  VolumeProvider({
    required SpotubeAudioPlayer audioPlayer,
  }) : _audioPlayer = audioPlayer;

  @override
  build() {
    _audioPlayer.setVolume(KVStoreService().volume);
    return KVStoreService().volume;
  }

  Future<void> setVolume(double volume) async {
    state = volume;
    await _audioPlayer.setVolume(volume);
    KVStoreService().setVolume(volume);
  }
}

final volumeProvider = NotifierProvider<VolumeProvider, double>(() {
  return VolumeProvider(audioPlayer: audioPlayer);
});
