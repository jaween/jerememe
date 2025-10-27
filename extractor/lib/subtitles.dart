class SubtitleLine {
  final int index;
  final Timestamp start;
  final Timestamp end;
  final String text;

  SubtitleLine({
    required this.index,
    required this.start,
    required this.end,
    required this.text,
  });

  @override
  String toString() =>
      '$index) ${start.time.inSeconds}s (${start.frame}) -> ${end.time.inSeconds}s (${end.frame}): $text';
}

class Timestamp {
  final Duration time;
  final int frame;

  Timestamp({required this.time, required this.frame});
}
