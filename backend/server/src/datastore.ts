import sqlite3 from "sqlite3";

export interface SubtitleRow {
  source_id: string;
  line_number: number;
  text: string;
  start_time: number;
  end_time: number;
}

export class Datastore {
  private db: sqlite3.Database;

  constructor(path: string) {
    this.db = new sqlite3.Database(path, (error) => {
      if (error) {
        throw error;
      }
    });

    this.db.get(
      "SELECT * FROM sqlite_master WHERE type='table' AND name='subtitles_fts'",
      (error, row) => {
        if (error) {
          console.error(error);
        }
      }
    );
  }

  public async search(query: string): Promise<SubtitleRow[]> {
    return new Promise((resolve, reject) => {
      const sql = `
        SELECT s.source_id, s.line_number, s.text, s.start_time, s.end_time
        FROM subtitles_fts f
        JOIN subtitles s ON s.rowid = f.rowid
        WHERE subtitles_fts MATCH ?
        ORDER BY s.source_id, s.line_number;
      `;
      this.db.all(sql, [query], (error, rows) => {
        if (error) {
          return reject(error);
        }
        resolve(rows as SubtitleRow[]);
      });
    });
  }

  public close(): Promise<void> {
    return new Promise((resolve, reject) => {
      this.db.close((error) => {
        if (error) {
          return reject(error);
        }
        resolve();
      });
    });
  }
}
