import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart' as crypto;
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
      mediaFile: videoFile,
    );

    final lines = await parseSrtFile(subtitlePath);
    if (lines == null) {
      print('Failed to extract subtitles');
      return;
    }
    print('  Inserting ${lines.length} subtitle lines into database');
    await database.addLines(mediaId: metadata.id, lines: lines);
  }
}

Future<void> _extract({
  required S3Storage s3,
  required Database database,
  required MediaMetadata metadata,
  required File mediaFile,
}) async {
  print('Processing ${metadata.id}');
  final resolution = await getVideoResolution(mediaFile.path);
  final videoDuration = await getVideoDuration(mediaFile.path);
  int frameCount = 0;
  final roundedUpTotalMinutes = (videoDuration.inSeconds / 60).ceil();
  print('  Extracting frames ($roundedUpTotalMinutes minute video)');
  final frames = await extractFrames(
    mediaId: metadata.id,
    videoPath: mediaFile.path,
  );

  print('  Uploading frames');
  await _uploadFrames(
    s3: s3,
    frames: frames,
    frameCount: frameCount,
    mediaId: metadata.id,
  );
  frameCount += frames.length;

  print('  Inserting media info into database');
  await database.addMedia(
    Media(
      metadata: metadata,
      duration: Duration(seconds: metadata.durationSeconds),
      durationFrames: metadata.durationFrames,
      resolution: resolution,
    ),
  );
}

Future<void> _uploadFrames({
  required S3Storage s3,
  required List<Uint8List> frames,
  required int frameCount,
  required String mediaId,
}) async {
  const uploadBatchSize = 48;
  final start = DateTime.now();
  for (int f = 0; f < frames.length; f += uploadBatchSize) {
    if (f % 1008 == 0) {
      final now = DateTime.now();
      print(
        '  Uploading $mediaId: $f frames uploaded (${(100 * f / (frames.length - 1)).toStringAsFixed(1)}%), ${(now.difference(start)).inMinutes} minutes elapsed',
      );
    }
    final batch = frames.skip(f).take(uploadBatchSize).toList();
    final batchStartFrameIndex = frameCount + f;
    await Future.wait([
      for (final (batchOffset, frame) in batch.indexed)
        s3.upload(
          key: _generateS3FrameKey(
            mediaId: mediaId,
            frameIndex: batchStartFrameIndex + batchOffset,
          ),
          data: frame,
          contentType: 'image/webp',
        ),
    ]);
  }
}

String _generateS3FrameKey({required String mediaId, required int frameIndex}) {
  final base = '$mediaId/frames/$frameIndex';
  final bytes = utf8.encode(base);
  final digest = crypto.sha256.convert(bytes);
  return 'public/$mediaId/frames/${digest.toString().substring(0, 8)}/$frameIndex.webp';
}
