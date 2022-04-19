part of quran;

class SurahMediaItem extends MediaItem {
  SurahMediaItem({
    required this.quran,
    required this.surah,
    required Duration? duration,
  }) : super(
          id: idOd(quran, surah),
          title: surah.localizedName,
          album: quran.edition.localizedName,
          artist: S.current.app_name,
          playable: true,
          rating: const Rating.newHeartRating(true),
          genre: S.current.the_holly_quran,
          artUri: QuranManager.artWork.absolute.uri,
          duration: duration,
          extras: <String, dynamic>{
            S.current.number_in_quran: surah.number,
            S.current.juz: QuranStore.settings.juzData
                .firstWhere(
                  (Juz element) => element.containsSurah(surah.number),
                )
                .index,
          },
        );

  factory SurahMediaItem.fromMedia(MediaItem item) {
    if (item is SurahMediaItem) {
      return item;
    }
    final String identifier = item.id.split('#')[0];
    final int surahNumber = int.parse(item.id.split('#')[1]);
    final TheHolyQuran quran = QuranStore._getQuran(
      QuranStore._listEditions()
          .singleWhere((Edition element) => element.identifier == identifier),
    )!;

    return SurahMediaItem(
      quran: quran,
      surah: quran.surahs
          .singleWhere((Surah element) => element.number == surahNumber),
      duration: item.duration,
    );
  }
  final TheHolyQuran quran;
  final Surah surah;

  static String idOd(
    TheHolyQuran quran,
    Surah surah,
  ) =>
      '${quran.edition.identifier}#${surah.number}';

  static TheHolyQuran quranFromID(String id) =>
      QuranManager.getQuranByID(id.split('#').first);
  static Surah surahFromID(String id) => quranFromID(id).surahs.singleWhere(
        (Surah element) => element.number == int.parse(id.split('#')[1]),
      );
}
