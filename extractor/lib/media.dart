class Media {
  final MediaMetadata metadata;
  final Duration duration;
  final int durationFrames;
  final Resolution resolution;

  Media({
    required this.metadata,
    required this.duration,
    required this.durationFrames,
    required this.resolution,
  });

  String get id => metadata.id;

  String get title => metadata.title;
}

class Resolution {
  final int width;
  final int height;
  const Resolution(this.width, this.height);
}

class MediaMetadata {
  final String id;
  final String title;
  final int durationSeconds;
  final int durationFrames;
  final Resolution resolution;

  const MediaMetadata({
    required this.id,
    required this.title,
    required this.durationSeconds,
    required this.durationFrames,
    required this.resolution,
  });
}

const mediaMetadata = [
  MediaMetadata(
    id: 'web00',
    title: 'Teaser',
    durationSeconds: 0,
    durationFrames: 0,
    resolution: Resolution(0, 0),
  ),
  MediaMetadata(
    id: 'web01',
    title: 'The Life of a Pro Gamer',
    durationSeconds: 696,
    durationFrames: 16713,
    resolution: Resolution(480, 360),
  ),
  MediaMetadata(
    id: 'web02',
    title: 'Girls',
    durationSeconds: 968,
    durationFrames: 23216,
    resolution: Resolution(480, 360),
  ),
  MediaMetadata(
    id: 'web03',
    title: 'FPS Doug',
    durationSeconds: 720,
    durationFrames: 17230,
    resolution: Resolution(480, 360),
  ),
  MediaMetadata(
    id: 'web04',
    title: 'Pwn or Be Pwned',
    durationSeconds: 1257,
    durationFrames: 30003,
    resolution: Resolution(480, 360),
  ),
  MediaMetadata(
    id: 'web05',
    title: 'M8s',
    durationSeconds: 895,
    durationFrames: 21407,
    resolution: Resolution(480, 360),
  ),
  MediaMetadata(
    id: 'web06',
    title: 'Imapwnu of Azeroth',
    durationSeconds: 1224,
    durationFrames: 29265,
    resolution: Resolution(480, 360),
  ),
  MediaMetadata(
    id: 'web07',
    title: 'MMO Grrl',
    durationSeconds: 932,
    durationFrames: 22205,
    resolution: Resolution(480, 360),
  ),
  MediaMetadata(
    id: 'web08',
    title: 'Lanageddon',
    durationSeconds: 1353,
    durationFrames: 32240,
    resolution: Resolution(480, 360),
  ),
  MediaMetadata(
    id: 'web09',
    title: 'The Story of Dave',
    durationSeconds: 1547,
    durationFrames: 36944,
    resolution: Resolution(480, 360),
  ),
  MediaMetadata(
    id: 'web10',
    title: 'Teh Best Day Ever',
    durationSeconds: 1646,
    durationFrames: 39324,
    resolution: Resolution(480, 360),
  ),
  MediaMetadata(
    id: 'web11',
    title: 'i heart u in rl',
    durationSeconds: 1296,
    durationFrames: 30928,
    resolution: Resolution(480, 360),
  ),
  MediaMetadata(
    id: 'web12',
    title: 'Game Over',
    durationSeconds: 2903,
    durationFrames: 69314,
    resolution: Resolution(480, 360),
  ),
  MediaMetadata(
    id: 'web13',
    title: 'Old Habits',
    durationSeconds: 1921,
    durationFrames: 45895,
    resolution: Resolution(480, 360),
  ),
  MediaMetadata(
    id: 'web14',
    title: 'Lifestyles',
    durationSeconds: 1461,
    durationFrames: 34940,
    resolution: Resolution(480, 360),
  ),
  MediaMetadata(
    id: 'web15',
    title: 'T-Bag',
    durationSeconds: 1525,
    durationFrames: 36414,
    resolution: Resolution(480, 360),
  ),
  MediaMetadata(
    id: 'web16',
    title: 'Duty Calls',
    durationSeconds: 1667,
    durationFrames: 39813,
    resolution: Resolution(480, 360),
  ),
  MediaMetadata(
    id: 'web17',
    title: 'Just The Guys, Part 1',
    durationSeconds: 1417,
    durationFrames: 33800,
    resolution: Resolution(480, 360),
  ),
  MediaMetadata(
    id: 'web18',
    title: 'Just The Guys, Part 2',
    durationSeconds: 1472,
    durationFrames: 35138,
    resolution: Resolution(480, 360),
  ),
  MediaMetadata(
    id: 'tv01',
    title: 'The Life of a Pro Gamer',
    durationSeconds: 0,
    durationFrames: 0,
    resolution: Resolution(0, 0),
  ),
  MediaMetadata(
    id: 'tv02',
    title: 'Jobs',
    durationSeconds: 0,
    durationFrames: 0,
    resolution: Resolution(0, 0),
  ),
  MediaMetadata(
    id: 'tv03',
    title: 'Girls',
    durationSeconds: 0,
    durationFrames: 0,
    resolution: Resolution(0, 0),
  ),
  MediaMetadata(
    id: 'tv04',
    title: 'Rock On',
    durationSeconds: 0,
    durationFrames: 0,
    resolution: Resolution(0, 0),
  ),
  MediaMetadata(
    id: 'tv05',
    title: 'Who\'s Afraid of the Big Bad Doug?',
    durationSeconds: 0,
    durationFrames: 0,
    resolution: Resolution(0, 0),
  ),
  MediaMetadata(
    id: 'tv06',
    title: 'The Day the LAN Centre Stood Still',
    durationSeconds: 0,
    durationFrames: 0,
    resolution: Resolution(0, 0),
  ),
  MediaMetadata(
    id: 'tv07',
    title: 'Losing to a n00b',
    durationSeconds: 0,
    durationFrames: 0,
    resolution: Resolution(0, 0),
  ),
  MediaMetadata(
    id: 'tv08',
    title: 'Pwnageddon',
    durationSeconds: 0,
    durationFrames: 0,
    resolution: Resolution(0, 0),
  ),
  MediaMetadata(
    id: 'movie',
    title: 'Teh Movie',
    durationSeconds: 0,
    durationFrames: 0,
    resolution: Resolution(0, 0),
  ),
];
