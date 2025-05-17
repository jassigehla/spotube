import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotify/spotify.dart';
import 'package:spotube/collections/vars.dart';
import 'package:spotube/models/current_playlist.dart';
import 'package:spotube/models/database/database.dart';

class BlackListNotifier extends AsyncNotifier<List<BlacklistTableData>> {
  AppDatabase get db => getIt.get<AppDatabase>();

  @override
  build() async {
    final subscription = db
        .select(db.blacklistTable)
        .watch()
        .listen((event) => state = AsyncData(event));

    ref.onDispose(() {
      subscription.cancel();
    });

    return await db.select(db.blacklistTable).get();
  }

  Future<void> add(BlacklistTableCompanion element) async {
    db.into(db.blacklistTable).insert(element);
  }

  Future<void> remove(String elementId) async {
    await (db.delete(db.blacklistTable)
          ..where((tbl) => tbl.elementId.equals(elementId)))
        .go();
  }

  bool contains(TrackSimple track) {
    final containsTrack =
        state.asData?.value.any((element) => element.elementId == track.id) ??
            false;

    final containsTrackArtists = track.artists?.any(
          (artist) =>
              state.asData?.value.any((el) => el.elementId == artist.id) ??
              false,
        ) ??
        false;

    return containsTrack || containsTrackArtists;
  }

  bool containsArtist(ArtistSimple artist) {
    return state.asData?.value
            .any((element) => element.elementId == artist.id) ??
        false;
  }

  /// Filters the non blacklisted tracks from the given [tracks]
  Iterable<TrackSimple> filter(Iterable<TrackSimple> tracks) {
    return tracks.whereNot(contains).toList();
  }

  CurrentPlaylist filterPlaylist(CurrentPlaylist playlist) {
    return CurrentPlaylist(
      id: playlist.id,
      name: playlist.name,
      thumbnail: playlist.thumbnail,
      tracks: playlist.tracks.where((track) => !contains(track)).toList(),
    );
  }
}

final blacklistProvider =
    AsyncNotifierProvider<BlackListNotifier, List<BlacklistTableData>>(
  () => BlackListNotifier(),
);
