import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:duration/duration.dart' as duration_formater;
import 'package:duration/locale.dart';
import 'package:ffmpeg_kit_flutter_min/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_min/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_min/return_code.dart';
import 'package:islamy/quran/models/ayah.dart';
import 'package:islamy/quran/models/edition.dart';
import 'package:islamy/quran/models/quran_meta.dart';
import 'package:islamy/quran/models/surah.dart';
import 'package:islamy/quran/models/the_holy_quran.dart';
import 'package:islamy/quran/quran_manager.dart';
import 'package:islamy/quran/quran_player_controller.dart';
import 'package:islamy/quran/store/quran_store.dart';

class CloudQuran {
  const CloudQuran._();
  static late final Dio _dio = Dio();
  static void init() {
    _dio.options.baseUrl = 'https://api.alquran.cloud/v1/';
    _dio.options.headers['Accept'] = 'application/json';
    _dio.options.headers['Content-Type'] = 'application/json';
  }

  static Future<Response> _call({
    required String path,
    Map<String, String> headers = const <String, String>{},
    Map<String, dynamic> query = const <String, dynamic>{},
    Map<String, dynamic> body = const <String, dynamic>{},
    void Function(int, int)? onReceiveProgress,
    String method = 'GET',
  }) {
    return _dio.request(
      path,
      data: body,
      queryParameters: query,
      onReceiveProgress: onReceiveProgress,
      options: Options(
        receiveTimeout: 0,
        sendTimeout: 0,
        headers: headers,
        validateStatus: (_) => true,
        method: method,
      ),
    );
  }

  static Future<List<Edition>> listEditions() async {
    Response response = await _call(path: 'edition');
    return Edition.listFrom(response.data['data']);
  }

  static Future<TheHolyQuran> getQuran({
    required Edition edition,
    void Function(int, int)? onReceiveProgress,
  }) async {
    Response response = await _call(
        path: 'quran/${edition.identifier}',
        onReceiveProgress: onReceiveProgress);
    return TheHolyQuran.fromJson(response.data['data']);
  }

  static Future<QuranMeta> getQuranMeta({
    void Function(int, int)? onReceiveProgress,
  }) async {
    Response response =
        await _call(path: 'meta', onReceiveProgress: onReceiveProgress);
    return QuranMeta.fromJson(response.data['data']);
  }

  static Future<void> downloadAyah(Directory directory, Ayah ayah) async {
    String path = directory.path;
    if (!path.endsWith(Platform.pathSeparator)) path += Platform.pathSeparator;
    path += ayah.numberInSurah.toString() + '.mp3';
    await _dio.downloadUri(
      Uri.parse(ayah.audio!),
      path,
    );
  }

  static String _formatDuration(Duration duration) =>
      duration_formater.prettyDuration(
        duration,
        tersity: duration_formater.DurationTersity.microsecond,
        locale: const EnglishDurationLocale(),
        delimiter: ',',
        abbreviated: true,
        spacer: '',
      );

  /// Downloads surahs ayahs and prepare it's meta for the player
  static Future<void> downloadSurah({
    required Edition edition,
    required Surah surah,
    Function(int index)? onAyahDownloaded,
  }) async {
    // the surah directory
    Directory surahDirectory =
        await QuranStore.getDirectoryForSurah(edition, surah);
    // if there is a fault and this method is called even id the surah is downloaded before for this edition then delete the old one.
    // better safe than sorry.
    for (var file in surahDirectory.listSync()) {
      await file.delete(recursive: true);
    }
    // download each ayah
    for (var i = 0; i < surah.ayahs.length; i++) {
      await CloudQuran.downloadAyah(surahDirectory, surah.ayahs[i]);
      onAyahDownloaded?.call(i);
    }
    final files = surahDirectory.listSync();
    // sort the ayahs files by number
    files.sort((f1, f2) => f1.path.compareTo(f2.path));
    // creating the merged surah file
    final File merged = File(surahDirectory.path +
        Platform.pathSeparator +
        QuranManager.mergedSurahFileName);

    // the duration map to be later a json which will be used in the player
    final Map<String, String> durations = <String, String>{};
    // making a seperate list to use later on the merger
    List<File> ayahsFiles = <File>[];
    // iterating for each file in the directory append it to the merged surah list
    for (var item in files) {
      // item is file && is audio but not the merged file
      if (item is File &&
          item.path.split('.').last == 'mp3' &&
          item.path.split(Platform.pathSeparator).last !=
              QuranManager.mergedSurahFileName) {
        // add the ayah to the merged list
        ayahsFiles.add(item);
        // adding the duration with the file name to the durations map
        durations[item.path
                .split(Platform.pathSeparator)
                .last
                .replaceFirst('.mp3', '')] =
            _formatDuration(await QuranPlayerContoller.lengthOf(item.path));
      }
    }
    // start by calculating if the surah needs basmala
    // add basmala at the start only if the surah is not ٱلْفَاتِحَة cause it's already included at the first
    // neither ٱلتَّوْبَة cause it's starts without it.
    TheHolyQuran quran = QuranStore.getQuran(edition)!;
    bool needsBasmala = surah.number != 1 && surah.number == 9;
    File basmala = await QuranStore.basmalaFileFor(quran);
    if (needsBasmala) {
      ayahsFiles.insert(0, basmala);
    }
    await concatenate(ayahsFiles, merged);
    // the duration json file
    File durationsJson = File(surahDirectory.path +
        Platform.pathSeparator +
        QuranManager.durationJsonFileName);
    // adding the basmala duration if it was added before
    if (needsBasmala) {
      durations['0'] =
          _formatDuration(await QuranPlayerContoller.lengthOf(basmala.path));
    }
    // write the durations map to the json file
    durationsJson.writeAsStringSync(json.encode(durations),
        mode: FileMode.write, flush: true);
    // if the platform supports no media file append it
    if (QuranManager.noMediaPlatforms.contains(Platform.operatingSystem)) {
      File(surahDirectory.path + Platform.pathSeparator + '.nomedia')
          .createSync();
    }
  }

  /// coppied from SO [answer](https://stackoverflow.com/a/66528374/18150607) and modifed to seperated files instead of assets
  static Future<File> concatenate(List<File> ayahs, File output) async {
    final list = File(
      output.path.substring(
              0, output.path.lastIndexOf(Platform.pathSeparator) + 1) +
          'list.txt',
    );
    for (var ayah in ayahs) {
      list.writeAsStringSync('file ' + ayah.path + '\n', mode: FileMode.append);
    }

    final cmd = <String>[
      '-f',
      'concat',
      '-safe',
      '0',
      '-y',
      '-i',
      list.path,
      '-codec',
      "copy",
      output.path
    ];
    FFmpegSession session = await FFmpegKit.executeWithArguments(cmd);
    ReturnCode? code = await session.getReturnCode();
    list.deleteSync();
    if (!(code?.isValueSuccess() ?? false)) throw 'error';
    return output;
  }
}
