import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:islamy/generated/l10n/l10n.dart';
import 'package:islamy/quran/models/enums_values.dart';
part 'enums.g.dart';

@HiveType(typeId: 2)
enum QuranContentType {
  @HiveField(0)
  tafsir,
  @HiveField(1)
  translation,
  @HiveField(2)
  transliteration,
  @HiveField(3)
  quran,
  @HiveField(4)
  versebyverse,
}

final EnumValues typeValues = EnumValues(
  <String, QuranContentType>{
    'quran': QuranContentType.quran,
    'tafsir': QuranContentType.tafsir,
    'translation': QuranContentType.translation,
    'transliteration': QuranContentType.transliteration,
    'versebyverse': QuranContentType.versebyverse
  },
);

@HiveType(typeId: 3)
enum Format {
  @HiveField(0)
  text,
  @HiveField(1)
  audio,
}

final EnumValues formatValues = EnumValues(
  <String, Format>{
    'audio': Format.audio,
    'text': Format.text,
  },
);

@HiveType(typeId: 4)
enum Direction {
  @HiveField(0)
  rtl,
  @HiveField(1)
  ltr,
}

extension DirectionParser on Direction {
  TextDirection get direction =>
      this == Direction.ltr ? TextDirection.ltr : TextDirection.rtl;
}

final EnumValues directionValues = EnumValues(
  <String, Direction>{
    'ltr': Direction.ltr,
    'rtl': Direction.rtl,
  },
);

@HiveType(typeId: 9)
enum RevelationType {
  @HiveField(0)
  meccan,
  @HiveField(1)
  medinan,
}

extension Stringfier on RevelationType {
  String get name {
    return this == RevelationType.meccan ? S.current.meccan : S.current.medinan;
  }
}

final EnumValues revelationTypeValues = EnumValues(<String, RevelationType>{
  'Meccan': RevelationType.meccan,
  'Medinan': RevelationType.medinan
});
