import sqlite3 from "sqlite3";
import { S3Storage } from "./storage.js";

export interface SearchResult {
  mediaId: string;
  startTime: number;
  startFrame: number;
  text: string;
  image: string;
}

export interface Frame {
  index: number;
  image: string;
}

export class Datastore {
  private db: sqlite3.Database;
  private storage: S3Storage;

  constructor(path: string, storage: S3Storage) {
    this.db = new sqlite3.Database(path, (error) => {
      if (error) {
        throw error;
      }
    });
    this.storage = storage;

    this.db.get(
      "SELECT * FROM sqlite_master WHERE type='table' AND name='subtitles_fts'",
      (error, row) => {
        if (error) {
          console.error(error);
        }
      }
    );
  }

  public async searchText(query: string): Promise<SearchResult[]> {
    return new Promise((resolve, reject) => {
      const sql = `
        SELECT s.media_id, s.start_time, s.start_frame, s.text
        FROM subtitles_fts f
        JOIN subtitles s ON s.rowid = f.rowid
        WHERE subtitles_fts MATCH ?
        ORDER BY s.media_id, s.line_number;
      `;
      this.db.all(sql, [query], (error, rows) => {
        if (error) {
          return reject(error);
        }
        const mapped = rows.map<SearchResult>((r: any) => ({
          mediaId: r.media_id,
          startTime: r.start_time,
          startFrame: r.start_frame,
          text: r.text,
          image: this.storage.urlFromKey(
            this.storage.generateS3FrameKey(r.media_id, r.start_frame)
          ),
        }));
        resolve(mapped);
      });
    });
  }

  public async fetchFrames(
    mediaId: string,
    index: number,
    direction?: "before" | "after",
    count: number = 10
  ): Promise<Frame[]> {
    const maxFrames = await this.durationFramesOfMedia(mediaId);
    let start: number;
    let end: number;

    if (index < 0 || index >= maxFrames) {
      return [];
    }

    if (direction === "before") {
      start = Math.max(index - count, 0);
      end = index - 1;
    } else if (direction === "after") {
      start = Math.min(index + 1, maxFrames);
      end = index + count;
    } else {
      start = Math.max(index - 10, 0);
      end = Math.min(index + 10, maxFrames);
    }

    const results: Frame[] = [];
    for (let i = start; i <= end; i++) {
      const key = this.storage.generateS3FrameKey(mediaId, i);
      const url = this.storage.urlFromKey(key);
      results.push({ index: i, image: url });
    }

    return results;
  }

  public async durationFramesOfMedia(mediaId: string): Promise<number> {
    return new Promise((resolve, reject) => {
      const sql = `SELECT duration_frames FROM media WHERE id=?`;
      this.db.all(sql, [mediaId], (error, rows) => {
        if (error) {
          return reject(error);
        }
        const row: any = rows[0];
        resolve(row.duration_frames);
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
