import 'package:extractor/database.dart';
import 'package:extractor/extractor.dart';

void main(List<String> arguments) async {
  const videoPath = 'web_series/s01e01.mkv';
  final lines = await extractLines(videoPath);
  if (lines == null) {
    print('Failed to extract');
    return;
  }

  final database = await Database.connect('./data.db');
  print('Connected to DB');
  await database.addLines(sourceId: 'WEBS01E01', lines: lines);
  print('Inserted');
  final results = database.search('kyle');
  for (final result in results) {
    print(result);
  }
}
