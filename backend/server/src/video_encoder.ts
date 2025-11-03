import { spawn } from "child_process";
import { Readable } from "stream";
import { Frame } from "./datastore";
import axios from "axios";

export class VideoEncoder {
  public async encode(frames: Frame[], frameRate: number): Promise<Buffer> {
    if (frames.length === 0) {
      throw new Error("No frames provided.");
    }

    const buffers = await Promise.all(
      frames.map(async (f) => {
        const res = await axios.get<ArrayBuffer>(f.image, {
          responseType: "arraybuffer",
        });
        return Buffer.from(res.data);
      })
    );

    const inputStream = new Readable({
      read() {
        for (const buffer of buffers) {
          this.push(buffer);
        }
        this.push(null);
      },
    });

    const ffmpeg = spawn("ffmpeg", [
      "-hide_banner",
      "-loglevel",
      "error",
      "-f",
      "image2pipe",
      "-vcodec",
      "mjpeg",
      "-r",
      frameRate.toString(),
      "-i",
      "pipe:0",
      "-pix_fmt",
      "yuv420p",
      "-vcodec",
      "libvpx-vp9",
      "-b:v",
      "1M",
      "-f",
      "webm",
      "pipe:1",
    ]);

    inputStream.pipe(ffmpeg.stdin);

    const chunks: Buffer[] = [];
    ffmpeg.stdout.on("data", (chunk) => chunks.push(chunk));

    return new Promise<Buffer>((resolve, reject) => {
      ffmpeg.on("error", reject);
      ffmpeg.on("close", (code) => {
        if (code !== 0) {
          return reject(new Error(`ffmpeg exited with ${code}`));
        }
        resolve(Buffer.concat(chunks));
      });
    });
  }
}
