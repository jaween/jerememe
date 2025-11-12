import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:extractor/media.dart';
import 'package:extractor/subtitles.dart';

Future<List<SubtitleLine>?> parseSrtFile(String srtPath) async {
  final text = await File(srtPath).readAsString();
  return _parseSrt(text);
}

Future<List<Uint8List>> extractFrames({
  required String mediaId,
  required String videoPath,
}) async {
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
    'fps=24,scale=-1:360',
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
  print('  Extracted $frame frames');
  return output;
}

Future<Resolution> getVideoResolution(String videoPath) async {
  final result = await Process.run('ffprobe', [
    '-v',
    'error',
    '-select_streams',
    'v:0',
    '-show_entries',
    'stream=width,height',
    '-of',
    'default=noprint_wrappers=1:nokey=1',
    videoPath,
  ]);

  if (result.exitCode != 0) {
    throw Exception(
      'Failed to get video resolution. FFprobe exit code: ${result.exitCode}',
    );
  }

  final output = result.stdout.trim().split('\n');

  if (output.length < 2) {
    throw Exception(
      'Failed to parse video resolution from ffprobe output: ${result.stdout}',
    );
  }

  final width = int.tryParse(output[0].trim());
  final height = int.tryParse(output[1].trim());

  if (width == null || height == null) {
    throw Exception(
      'Invalid resolution values received: Width=${output[0]}, Height=${output[1]}',
    );
  }

  return Resolution(width, height);
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
