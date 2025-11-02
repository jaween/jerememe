import { createHash } from "crypto";

export class S3Storage {
  private cdnPrefix: string;

  constructor(cdnPrefix: string) {
    this.cdnPrefix = cdnPrefix;
  }

  public generateS3FrameKey(mediaId: string, frameIndex: number): string {
    const base: string = `${mediaId}/frames/${frameIndex}`;
    const digest = createHash("sha256").update(base).digest("hex");
    return `public/${mediaId}/frames/${digest.substring(
      0,
      8
    )}/${frameIndex}.jpg`;
  }

  public urlFromKey(key: string): string {
    return `${this.cdnPrefix}/${key}`;
  }
}
