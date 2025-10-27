import 'package:extractor/extractor.dart';

void main(List<String> arguments) async {
  const videoPath =
      '/mnt/extra/Media/Pure Pwnage/Web Series/Episode 1 - The Life of a Pro.mkv';
  final lines = await extractLines(videoPath);
  if (lines == null) {
    print('Failed to extract');
    return;
  }
  print(lines);
}
