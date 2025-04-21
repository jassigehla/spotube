import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:spotify/spotify.dart';
import 'package:spotube/collections/fake.dart';
import 'package:spotube/collections/vars.dart';
import 'package:spotube/models/current_playlist.dart';
import 'package:spotube/models/database/database.dart';
import 'package:spotube/provider/blacklist/blacklist_provider.dart';

import '../create_container.dart';

void main() {
  group('BlacklistProvider', () {
    late ProviderContainer container;

    setUp(() {
      getIt.registerLazySingleton<AppDatabase>(() {
        final database = AppDatabase(NativeDatabase.memory());

        addTearDown(() {
          database.close();
        });

        return database;
      });

      container = createContainer();
    });

    tearDown(() {
      getIt.reset();
    });

    test('initially should return empty list', () async {
      final blackList = container.read(blacklistProvider.future);

      await expectLater(blackList, completion(isEmpty));
    });

    test('add should add item to blacklist', () async {
      final blacklistRef =
          container.listen(blacklistProvider.future, (_, __) {});

      await expectLater(blacklistRef.read(), completion(isEmpty));

      final item = BlacklistTableCompanion.insert(
        id: const Value(20),
        name: 'Test',
        elementId: 'test',
        elementType: BlacklistedType.track,
      );

      final res = container.read(blacklistProvider.notifier).add(item);

      await expectLater(res, completes);

      await Future.delayed(const Duration(milliseconds: 100));

      await expectLater(blacklistRef.read(), completion(isNotEmpty));

      await expectLater(
        blacklistRef.read(),
        completion(
          contains(
            predicate<BlacklistTableData>(
              (e) =>
                  e.name == 'Test' &&
                  e.elementId == 'test' &&
                  e.elementType == BlacklistedType.track,
            ),
          ),
        ),
      );
    });

    test('remove should remove item from blacklist', () async {
      final blacklistRef =
          container.listen(blacklistProvider.future, (_, __) {});

      await expectLater(blacklistRef.read(), completion(isEmpty));

      final item = BlacklistTableCompanion.insert(
        id: const Value(20),
        name: 'Test',
        elementId: 'test',
        elementType: BlacklistedType.track,
      );

      final res = container.read(blacklistProvider.notifier).add(item);

      await expectLater(res, completes);

      await Future.delayed(const Duration(milliseconds: 100));

      await expectLater(blacklistRef.read(), completion(isNotEmpty));

      final removeRes = container
          .read(blacklistProvider.notifier)
          .remove(item.elementId.value);

      await expectLater(removeRes, completes);

      await Future.delayed(const Duration(milliseconds: 100));

      await expectLater(blacklistRef.read(), completion(isEmpty));
    });

    group('contains', () {
      test('should be true if track exists', () async {
        final item = BlacklistTableCompanion.insert(
          id: const Value(20),
          name: 'Test',
          elementId: FakeData.track.id!,
          elementType: BlacklistedType.track,
        );

        final res = container.read(blacklistProvider.notifier).add(item);

        await expectLater(res, completes);
        await Future.delayed(const Duration(milliseconds: 100));

        final track = FakeData.track as TrackSimple;

        final contains =
            container.read(blacklistProvider.notifier).contains(track);

        expect(contains, isTrue);
      });

      test('should be true if track does not exist but artist of track exists',
          () async {
        final item = BlacklistTableCompanion.insert(
          id: const Value(20),
          name: 'Test',
          elementId: FakeData.track.artists!.first.id!,
          elementType: BlacklistedType.artist,
        );

        final res = container.read(blacklistProvider.notifier).add(item);

        await expectLater(res, completes);
        await Future.delayed(const Duration(milliseconds: 100));

        final contains =
            container.read(blacklistProvider.notifier).contains(FakeData.track);

        expect(contains, isTrue);
      });
    });

    group('containsArtist', () {
      test('should be true for artist that exists', () async {
        final item = BlacklistTableCompanion.insert(
          id: const Value(20),
          name: 'Test',
          elementId: FakeData.artist.id!,
          elementType: BlacklistedType.artist,
        );

        final res = container.read(blacklistProvider.notifier).add(item);

        await expectLater(res, completes);

        await Future.delayed(const Duration(milliseconds: 100));

        expect(
            container
                .read(blacklistProvider.notifier)
                .containsArtist(FakeData.artist),
            isTrue);
      });

      test('should be false for artist that is not blacklisted', () async {
        await expectLater(container.read(blacklistProvider.future), completes);

        expect(
          container
              .read(blacklistProvider.notifier)
              .containsArtist(FakeData.artist),
          isFalse,
        );
      });
    });

    group('filter', () {
      test('should return non-blacklisted tracks only', () async {
        final tracks = List.generate(
          10,
          (e) => Track.fromJson({
            ...FakeData.track.toJson(),
            'id': 'test-$e',
          }),
        );

        final blacklist = container.read(blacklistProvider.future);

        await expectLater(blacklist, completion(isEmpty));

        final item = BlacklistTableCompanion.insert(
          id: const Value(20),
          name: 'Test',
          elementId: tracks.first.id!,
          elementType: BlacklistedType.track,
        );
        final res = container.read(blacklistProvider.notifier).add(item);
        await expectLater(res, completes);

        await Future.delayed(const Duration(milliseconds: 100));

        final filteredTracks =
            container.read(blacklistProvider.notifier).filter(tracks);

        expect(filteredTracks, isNotEmpty);
        expect(filteredTracks.length, 9);
        expect(
          filteredTracks,
          isNot(contains(
            predicate<Track>(
              (e) => e.id == tracks.first.id,
            ),
          )),
        );
      });
    });

    test('filterPlaylist should not modify anything but tracks', () async {
      final playlist = CurrentPlaylist(
        id: "lol",
        name: "name",
        thumbnail: "thumbnail",
        tracks: [],
      );

      final blacklist = container.read(blacklistProvider.future);

      await Future.delayed(const Duration(milliseconds: 100));

      await expectLater(blacklist, completion(isEmpty));

      final res =
          container.read(blacklistProvider.notifier).filterPlaylist(playlist);

      expect(res.id, playlist.id);
      expect(res.name, playlist.name);
      expect(res.thumbnail, playlist.thumbnail);
    });
  });
}
