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
  Resolution(this.width, this.height);
}

class MediaMetadata {
  final String id;
  final String title;

  const MediaMetadata({required this.id, required this.title});
}

const mediaMetadata = [
  MediaMetadata(id: 'web00', title: 'Teaser'),
  MediaMetadata(id: 'web01', title: 'The Life of a Pro Gamer'),
  MediaMetadata(id: 'web02', title: 'Girls'),
  MediaMetadata(id: 'web03', title: 'FPS Doug'),
  MediaMetadata(id: 'web04', title: 'Pwn or Be Pwned'),
  MediaMetadata(id: 'web05', title: 'M8s'),
  MediaMetadata(id: 'web06', title: 'Imapwnu of Azeroth'),
  MediaMetadata(id: 'web07', title: 'MMO Grrl'),
  MediaMetadata(id: 'web08', title: 'Lanageddon'),
  MediaMetadata(id: 'web09', title: 'The Story of Dave'),
  MediaMetadata(id: 'web10', title: 'Teh Best Day Ever'),
  MediaMetadata(id: 'web11', title: 'i heart u in rl'),
  MediaMetadata(id: 'web12', title: 'Game Over'),
  MediaMetadata(id: 'web13', title: 'Old Habits'),
  MediaMetadata(id: 'web14', title: 'Lifestyles'),
  MediaMetadata(id: 'web15', title: 'T-Bag'),
  MediaMetadata(id: 'web16', title: 'Duty Calls'),
  MediaMetadata(id: 'web17', title: 'Just The Guys, Part 1'),
  MediaMetadata(id: 'web18', title: 'Just The Guys, Part 2'),
  MediaMetadata(id: 'tv01', title: 'The Life of a Pro Gamer'),
  MediaMetadata(id: 'tv02', title: 'Jobs'),
  MediaMetadata(id: 'tv03', title: 'Girls'),
  MediaMetadata(id: 'tv04', title: 'Rock On'),
  MediaMetadata(id: 'tv05', title: 'Who\'s Afraid of the Big Bad Doug?'),
  MediaMetadata(id: 'tv06', title: 'The Day the LAN Centre Stood Still'),
  MediaMetadata(id: 'tv07', title: 'Losing to a n00b'),
  MediaMetadata(id: 'tv08', title: 'Pwnageddon'),
  MediaMetadata(id: 'movie', title: 'Teh Movie'),
];
