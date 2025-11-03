import sqlite3 from "sqlite3";
import { S3Storage } from "./storage.js";

export interface SearchResult {
  mediaId: string;
  startTime: number;
  startFrame: number;
  text: string;
  image: string;
}

export interface FrameQueryResult {
  url: string;
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
    frameIndex: number
  ): Promise<FrameQueryResult[]> {
    const key = this.storage.generateS3FrameKey(mediaId, frameIndex);
    const url = this.storage.urlFromKey(key);
    return [
      {
        url: url,
      },
    ];
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
