import 'package:extractor/media.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:extractor/subtitles.dart';

class Database {
  final sqlite3.Database _db;

  Database._(this._db);

  static Future<Database> connect(String path) async {
    final db = sqlite3.sqlite3.open(path);

    db.execute('''
      CREATE TABLE IF NOT EXISTS media (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        duration_seconds INTEGER NOT NULL,
        duration_frames INTEGER NOT NULL,
        resolution_width INTEGER NOT NULL,
        resolution_height INTEGER NOT NULL
      );
    ''');

    db.execute('''
      CREATE TABLE IF NOT EXISTS subtitles (
        media_id TEXT NOT NULL,
        line_number INTEGER NOT NULL,
        start_time INTEGER NOT NULL,
        end_time INTEGER NOT NULL,
        start_frame INTEGER NOT NULL,
        end_frame INTEGER NOT NULL,
        text TEXT NOT NULL,
        PRIMARY KEY (media_id, line_number),
        FOREIGN KEY(media_id) REFERENCES media(id) ON DELETE CASCADE
      );
    ''');

    db.execute('''
      CREATE VIRTUAL TABLE IF NOT EXISTS subtitles_fts
      USING fts5(media_id, line_number, text, content='subtitles', content_rowid='rowid');
    ''');

    db.execute('''
      CREATE TRIGGER IF NOT EXISTS subtitles_ai AFTER INSERT ON subtitles BEGIN
        INSERT INTO subtitles_fts(rowid, media_id, line_number, text)
        VALUES (new.rowid, new.media_id, new.line_number, new.text);
      END;
    ''');

    db.execute('''
      CREATE TRIGGER IF NOT EXISTS subtitles_ad AFTER DELETE ON subtitles BEGIN
        DELETE FROM subtitles_fts WHERE rowid = old.rowid;
      END;
    ''');

    db.execute('''
      CREATE TRIGGER IF NOT EXISTS subtitles_au AFTER UPDATE ON subtitles BEGIN
        UPDATE subtitles_fts SET media_id = new.media_id, line_number = new.line_number, text = new.text
        WHERE rowid = old.rowid;
      END;
    ''');

    return Database._(db);
  }

  void close() {
    _db.dispose();
  }

  Future<void> addMedia(Media media) async {
    _db.execute(
      '''
      INSERT INTO media (id, title, duration_seconds, duration_frames, resolution_width, resolution_height)
      VALUES (?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        title = excluded.title,
        duration_seconds = excluded.duration_seconds,
        duration_frames = excluded.duration_frames;
      ''',
      [
        media.id,
        media.title,
        media.duration.inSeconds,
        media.durationFrames,
        media.resolution.width,
        media.resolution.height,
      ],
    );
  }

  Future<void> addLines({
    required String mediaId,
    required List<SubtitleLine> lines,
  }) async {
    final stmt = _db.prepare('''
      INSERT INTO subtitles (
        media_id, line_number, start_time, end_time, start_frame, end_frame, text
      ) VALUES (?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(media_id, line_number) DO UPDATE SET
        start_time = excluded.start_time,
        end_time = excluded.end_time,
        start_frame = excluded.start_frame,
        end_frame = excluded.end_frame,
        text = excluded.text;
    ''');

    _db.execute('BEGIN TRANSACTION;');
    try {
      for (final line in lines) {
        stmt.execute([
          mediaId,
          line.index,
          line.start.time.inMilliseconds,
          line.end.time.inMilliseconds,
          line.start.frame,
          line.end.frame,
          line.text,
        ]);
      }
      _db.execute('COMMIT;');
    } catch (e) {
      _db.execute('ROLLBACK;');
      rethrow;
    } finally {
      stmt.dispose();
    }
  }

  List<Map<String, Object?>> search(String query) {
    final result = _db.select(
      '''
      SELECT s.media_id, s.line_number, s.text, s.start_time, s.end_time
      FROM subtitles_fts f
      JOIN subtitles s ON s.rowid = f.rowid
      WHERE subtitles_fts MATCH ?
      ORDER BY s.media_id, s.line_number;
    ''',
      [query],
    );

    return result;
  }
}
