import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:extractor/s3.dart';
import 'package:extractor/subtitles.dart';

Future<List<SubtitleLine>?> parseSrtFile(String srtPath) async {
  final text = await File(srtPath).readAsString();
  return _parseSrt(text);
}

Future<List<Uint8List>> extractFrames({
  required String mediaId,
  required String videoPath,
}) async {
  final start = DateTime.now();
  final output = <Uint8List>[];
  final process = await Process.start('ffmpeg', [
    '-hide_banner',
    '-loglevel',
    'error',
    '-v',
    'debug',
    '-i',
    videoPath,
    '-vf',
    'fps=24,scale=iw*sar:ih,scale=-1:360',
    '-f',
    'image2pipe',
    '-vcodec',
    'libwebp',
    '-qscale',
    '70',
    '-',
  ], mode: ProcessStartMode.normal);
  process.stderr.transform(const Utf8Decoder()).listen((_) {});

  int frame = 0;
  await for (var chunk in process.stdout) {
    frame++;
    output.add(Uint8List.fromList(chunk));
  }
  await process.exitCode;
  print(
    '  Extracted $frame frames in ${(DateTime.now().difference(start)).inMinutes} minutes',
  );
  return output;
}

Future<void> uploadFrames({
  required S3Storage s3,
  required List<Uint8List> frames,
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
    await Future.wait([
      for (final (batchOffset, frame) in batch.indexed)
        s3.upload(
          key: _generateS3FrameKey(
            mediaId: mediaId,
            frameIndex: f + batchOffset,
          ),
          data: frame,
          contentType: 'image/webp',
        ),
    ]);
  }
}

Future<Duration> getVideoDuration(String videoPath) async {
  final result = await Process.run('ffprobe', [
    '-v',
    'error',
    '-show_entries',
    'format=duration',
    '-of',
    'default=noprint_wrappers=1:nokey=1',
    videoPath,
  ]);

  if (result.exitCode != 0) {
    throw Exception('Failed to get video duration');
  }

  return Duration(seconds: double.parse(result.stdout.trim()).toInt());
}

String _generateS3FrameKey({required String mediaId, required int frameIndex}) {
  final base = '$mediaId/frames/$frameIndex';
  final bytes = utf8.encode(base);
  final digest = crypto.sha256.convert(bytes);
  return 'public/$mediaId/frames/${digest.toString().substring(0, 8)}/$frameIndex.webp';
}

List<SubtitleLine> _parseSrt(String srt) {
  srt = srt.replaceFirst('\uFEFF', '');
  srt = srt.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

  final lines = <SubtitleLine>[];
  final blocks = <String>[];

  final allLines = srt.split('\n');
  final currentBlock = StringBuffer();

  for (int i = 0; i < allLines.length; i++) {
    final line = allLines[i];

    if (line.trim().isNotEmpty) {
      currentBlock.writeln(line);
    } else if (currentBlock.isNotEmpty) {
      blocks.add(currentBlock.toString().trim());
      currentBlock.clear();
    }
  }

  if (currentBlock.isNotEmpty) {
    blocks.add(currentBlock.toString().trim());
  }

  for (final block in blocks) {
    if (block.isEmpty) {
      continue;
    }

    final blockLines = block.split('\n');
    if (blockLines.length < 3) {
      continue;
    }

    final index = int.tryParse(blockLines[0].trim());
    if (index == null) {
      continue;
    }

    final timeLine = blockLines[1];
    final timeMatch = RegExp(
      r'(\d{2}:\d{2}:\d{2},\d{3})\s*-->\s*(\d{2}:\d{2}:\d{2},\d{3})',
    ).firstMatch(timeLine);
    if (timeMatch == null) {
      continue;
    }

    final start = _parseSrtTime(timeMatch.group(1)!);
    final end = _parseSrtTime(timeMatch.group(2)!);
    final textLines = blockLines.sublist(2);

    var text = textLines
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .join(' ')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .trim();

    if (text.startsWith('- ')) {
      text = text.substring(2);
    }

    if (text.isEmpty) {
      continue;
    }

    const frameInterval = Duration(microseconds: 41667);
    final startFrame = (start.inMicroseconds / frameInterval.inMicroseconds)
        .floor();
    final endFrame = (end.inMicroseconds / frameInterval.inMicroseconds).ceil();

    lines.add(
      SubtitleLine(
        index: index,
        start: Timestamp(time: start, frame: startFrame),
        end: Timestamp(time: end, frame: endFrame),
        text: text,
      ),
    );
  }

  return lines;
}

Duration _parseSrtTime(String s) {
  final parts = s.split(RegExp('[:.,]'));
  final hours = int.parse(parts[0]);
  final minutes = int.parse(parts[1]);
  final seconds = int.parse(parts[2]);
  final milliseconds = int.parse(parts[3]);
  return Duration(
    hours: hours,
    minutes: minutes,
    seconds: seconds,
    milliseconds: milliseconds,
  );
}
