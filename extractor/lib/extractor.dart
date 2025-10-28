import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:extractor/subtitles.dart';

Future<List<SubtitleLine>?> extractSubtitleLines(String videoPath) async {
  final text = await _extractSubtitlesFromVideoFile(videoPath);
  if (text == null) {
    return null;
  }
  return _parseSrt(text);
}

Future<List<Uint8List>> extractFrames({
  required String mediaId,
  required String videoPath,
  required Duration skip,
  required Duration duration,
}) async {
  final output = <Uint8List>[];
  final process = await Process.start('ffmpeg', [
    '-hide_banner',
    '-loglevel',
    'error',
    '-v',
    'debug',
    '-ss',
    _formatFfmpegTime(skip),
    '-i',
    videoPath,
    '-t',
    _formatFfmpegTime(duration),
    '-r',
    '24',
    '-f',
    'image2pipe',
    '-',
  ], mode: ProcessStartMode.normal);
  process.stderr.transform(const Utf8Decoder()).listen((_) {});

  int frame = 0;
  await for (var chunk in process.stdout) {
    frame++;
    if (frame % 240 == 0) {
      print('  Processed ${(frame / 24).toStringAsFixed(2)}s');
    }
    output.add(Uint8List.fromList(chunk));
  }
  await process.exitCode;
  return output;
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

String _formatFfmpegTime(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;
  final seconds = duration.inSeconds % 60;
  return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

Future<String?> _extractSubtitlesFromVideoFile(String videoPath) async {
  try {
    final result = await Process.run('ffmpeg', [
      '-hide_banner',
      '-loglevel',
      'error',
      '-i',
      videoPath,
      '-map',
      '0:s:0',
      '-f',
      'srt',
      '-',
    ]);
    return result.stdout;
  } catch (e) {
    return null;
  }
}

List<SubtitleLine> _parseSrt(String srt) {
  final regex = RegExp(
    r'(\d+)\s+(\d{2}:\d{2}:\d{2},\d{3}) --> (\d{2}:\d{2}:\d{2},\d{3})\s+([\s\S]*?)(?=\n{2,}|\s*$)',
  );

  final matches = regex.allMatches(srt);

  final lines = <SubtitleLine>[];
  for (final match in matches) {
    final index = int.parse(match.group(1)!);
    final start = _parseSrtTime(match.group(2)!);
    final end = _parseSrtTime(match.group(3)!);
    var text = match.group(4)!.replaceAll('\n', ' ').trim();
    if (text.startsWith('- ')) {
      text = text.substring(2);
    }

    const frameInterval = Duration(microseconds: 41667);
    int startFrame = (start.inMicroseconds / frameInterval.inMicroseconds)
        .floor();
    int endFrame = (end.inMicroseconds / frameInterval.inMicroseconds).ceil();
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
