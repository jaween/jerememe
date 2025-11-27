import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dotenv/dotenv.dart';
import 'package:extractor/database.dart';
import 'package:extractor/extractor.dart';
import 'package:extractor/media.dart';
import 'package:extractor/s3.dart';
import 'package:path/path.dart' as path;

void main(List<String> arguments) async {
  final directoryPath = arguments.firstOrNull;
  if (directoryPath == null) {
    print('Usage: ./extractor <MEDIA DIRECTORY NAME>');
    exit(1);
  }
  final mediaFiles =
      Directory(directoryPath).listSync().whereType<File>().where(
        (e) => path.extension(e.path) != '.srt',
      )..toList();
  final dotEnv = DotEnv()..load();
  final s3 = S3Storage(
    accessKey: dotEnv.getOrElse('AWS_ACCESS_KEY', () => ''),
    secretKey: dotEnv.getOrElse('AWS_SECRET_KEY', () => ''),
    region: dotEnv.getOrElse('AWS_S3_REGION', () => ''),
    bucket: dotEnv.getOrElse('AWS_S3_BUCKET', () => ''),
  );

  final database = await Database.connect('./data.db');
  final fileMetadataPairs = <(File, MediaMetadata)>[];
  for (final metadata in mediaMetadata) {
    final file = mediaFiles.firstWhereOrNull(
      (e) => path.basenameWithoutExtension(e.path) == metadata.id,
    );
    if (file == null) {
      print('${metadata.id}: Not found');
      continue;
    }
    if (file.existsSync()) {
      print('${metadata.id}: Found');
      fileMetadataPairs.add((file, metadata));
    }
  }

  for (final pair in fileMetadataPairs) {
    final videoFile = pair.$1;
    final metadata = pair.$2;
    final subtitlePath = path.join(
      path.dirname(videoFile.path),
      '${path.basenameWithoutExtension(videoFile.path)}.srt',
    );
    await _extract(
      s3: s3,
      database: database,
      metadata: metadata,
      subtitlePath: subtitlePath,
      videoFile: videoFile,
    );
  }
  print('Done');
}

Future<void> _extract({
  required S3Storage s3,
  required Database database,
  required MediaMetadata metadata,
  required String subtitlePath,
  required File videoFile,
}) async {
  print('Processing ${metadata.id}');
  final videoDuration = await getVideoDuration(videoFile.path);
  final roundedUpTotalMinutes = (videoDuration.inSeconds / 60).ceil();

  // print('  Extracting frames ($roundedUpTotalMinutes minute video)');
  // final frames = await extractFrames(
  //   mediaId: metadata.id,
  //   videoPath: videoFile.path,
  // );

  // print('  Uploading frames');
  // await uploadFrames(s3: s3, frames: frames, mediaId: metadata.id);

  final lines = await parseSrtFile(subtitlePath);
  if (lines == null) {
    print('Failed to extract subtitles');
    return;
  }
  print('  Inserting ${lines.length} subtitle lines into database');
  await database.addLines(mediaId: metadata.id, lines: lines);

  print('  Inserting media info into database');
  await database.addMedia(
    Media(
      metadata: metadata,
      duration: Duration(seconds: metadata.durationSeconds),
      durationFrames: metadata.durationFrames,
      resolution: metadata.resolution,
    ),
  );
}
