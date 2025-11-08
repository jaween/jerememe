import sqlite3 from "sqlite3";
import { S3Storage } from "./storage.js";

export interface Thumbnail {
  url: string;
  width: number;
  height: number;
}

export interface SearchResult {
  mediaId: string;
  startTime: number;
  startFrame: number;
  text: string;
  thumbnail: Thumbnail;
}

export interface Subtitle {
  lineNumber: number;
  text: string;
}

export interface Frame {
  index: number;
  subtitle: Subtitle | null;
  thumbnail: Thumbnail;
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

  public async searchText(
    query: string,
    offset = 0,
    limit = 20
  ): Promise<{ results: SearchResult[]; totalResults: number }> {
    const safeQuery = this.escapeFtsQuery(query);
    const totalResults = await this.countResults(safeQuery);
    return new Promise((resolve, reject) => {
      const sql = `
      SELECT s.media_id, s.start_time, s.start_frame, s.text
      FROM subtitles_fts f
      JOIN subtitles s ON s.rowid = f.rowid
      WHERE subtitles_fts MATCH ?
      ORDER BY s.media_id, s.line_number
      LIMIT ? OFFSET ?;
    `;
      this.db.all(sql, [safeQuery, limit, offset], (error, rows) => {
        if (error) return reject(error);
        const mapped = rows.map<SearchResult>((r: any) => ({
          mediaId: r.media_id,
          startTime: r.start_time,
          startFrame: r.start_frame,
          text: r.text,
          thumbnail: {
            url: this.storage.urlForKey(
              this.storage.generateS3FrameKey(r.media_id, r.start_frame)
            ),
            width: 480,
            height: 360,
          },
        }));
        resolve({ results: mapped, totalResults: totalResults });
      });
    });
  }

  private escapeFtsQuery(query: string): string {
    const escaped = query.replace(/"/g, '""').trim();
    return `"${escaped}"`;
  }

  public async fetchFrames(
    mediaId: string,
    index: number,
    direction?: "before" | "after",
    count: number = 64
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
      start = Math.max(index - count, 0);
      end = Math.min(index + count, maxFrames);
    }

    const results: Frame[] = [];
    for (let i = start; i <= end; i++) {
      const key = this.storage.generateS3FrameKey(mediaId, i);
      const url = this.storage.urlForKey(key);
      const subtitle = await this.fetchSubtitleByFrame(mediaId, i);
      results.push({
        index: i,
        subtitle: subtitle,
        thumbnail: { url: url, width: 480, height: 360 },
      });
    }

    return results;
  }

  public async fetchFrameRange(
    mediaId: string,
    startFrame: number,
    endFrame: number
  ): Promise<Frame[]> {
    const maxFrame = await this.durationFramesOfMedia(mediaId);
    if (startFrame > endFrame || startFrame < 0 || endFrame >= maxFrame) {
      throw "Invaid frame indexes";
    }

    const count = endFrame - startFrame;
    if (count > 720) {
      throw "Frame range too large";
    }

    const results: Frame[] = [];
    for (let i = startFrame; i <= endFrame; i++) {
      const key = this.storage.generateS3FrameKey(mediaId, i);
      const url = this.storage.urlForKey(key);
      const subtitle = await this.fetchSubtitleByFrame(mediaId, i);
      results.push({
        index: i,
        subtitle: subtitle,
        thumbnail: { url: url, width: 480, height: 360 },
      });
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

  public async countResults(query: string): Promise<number> {
    return new Promise((resolve, reject) => {
      const sql = `
      SELECT COUNT(*) as total
      FROM subtitles_fts
      WHERE subtitles_fts MATCH ?;
    `;
      this.db.get(sql, [query], (error, row) => {
        if (error) {
          return reject(error);
        }
        resolve((row as any)?.total ?? 0);
      });
    });
  }

  public async fetchSubtitleByFrame(
    mediaId: string,
    frameIndex: number
  ): Promise<Subtitle | null> {
    return new Promise((resolve, reject) => {
      const sql = `
      SELECT line_number, text
      FROM subtitles
      WHERE media_id = ? 
        AND start_frame <= ? 
        AND end_frame >= ?
      LIMIT 1;
    `;
      this.db.get(sql, [mediaId, frameIndex, frameIndex], (error, row: any) => {
        if (error) {
          return reject(error);
        }
        if (row as any) {
          resolve({
            lineNumber: row.line_number,
            text: row.text,
          });
        } else {
          resolve(null);
        }
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
