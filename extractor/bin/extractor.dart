import 'dart:io';

import 'package:collection/collection.dart';
import 'package:extractor/database.dart';
import 'package:extractor/extractor.dart';
import 'package:extractor/metadata.dart';
import 'package:path/path.dart' as path;

void main(List<String> arguments) async {
  final directoryPath = arguments.firstOrNull;
  if (directoryPath == null) {
    print('Usage: ./extractor <MEDIA DIRECTORY NAME>');
    exit(1);
  }
  print('Using media path $directoryPath');
  final files = Directory(directoryPath).listSync().whereType<File>();

  final database = await Database.connect('./data.db');

  for (final metadata in mediaMetadata) {
    final file = files.firstWhereOrNull(
      (e) => path.basenameWithoutExtension(e.path) == metadata.id,
    );
    if (file == null) {
      print('${metadata.id}: Not found');
      continue;
    }
    if (file.existsSync()) {
      print('${metadata.id}: Found');
      final lines = await extractLines(file.path);
      if (lines == null) {
        print('Failed to extract');
        return;
      }

      print('  Inserting ${lines.length} subtitle lines into database');
      await database.addLines(mediaId: metadata.id, lines: lines);
    }
  }
}
