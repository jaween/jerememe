import {
  S3Client,
  PutObjectCommand,
  HeadObjectCommand,
} from "@aws-sdk/client-s3";
import { createHash } from "crypto";

export class S3Storage {
  private cdnPrefix: string;
  private bucketName: string;
  private s3Client: S3Client;

  constructor(options: {
    accessKeyId: string;
    secretAccessKey: string;
    region: string;
    bucketName: string;
    cdnPrefix: string;
  }) {
    this.cdnPrefix = options.cdnPrefix;
    this.bucketName = options.bucketName;
    this.s3Client = new S3Client({
      region: options.region,
      credentials: {
        accessKeyId: options.accessKeyId,
        secretAccessKey: options.secretAccessKey,
      },
    });
  }

  public generateS3FrameKey(mediaId: string, frameIndex: number): string {
    const base: string = `${mediaId}/frames/${frameIndex}`;
    const digest = createHash("sha256").update(base).digest("hex");
    return `public/${mediaId}/frames/${digest.substring(
      0,
      8
    )}/${frameIndex}.webp`;
  }

  public generateMemeKey(id: string): string {
    return `m/${id}`;
  }

  public urlForKey(key: string): string {
    return `${this.cdnPrefix}/${key}`;
  }

  public async upload(
    key: string,
    data: Buffer,
    contentType?: string
  ): Promise<string> {
    try {
      await this.s3Client.send(
        new HeadObjectCommand({
          Bucket: this.bucketName,
          Key: key,
        })
      );
      return this.urlForKey(key);
    } catch (error: any) {
      if (error.name === "NotFound") {
        await this.s3Client.send(
          new PutObjectCommand({
            Bucket: this.bucketName,
            Key: key,
            Body: data,
            ContentType: contentType,
          })
        );
        return this.urlForKey(key);
      } else {
        throw error;
      }
    }
  }
}
