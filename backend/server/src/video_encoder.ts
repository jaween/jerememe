import { spawn } from "child_process";
import { Frame } from "./datastore";
import axios from "axios";
import * as fs from "fs";
import * as os from "os";
import path from "path";
import shortUUID from "short-uuid";

export class VideoEncoder {
  public async encode(
    frames: Frame[],
    frameRate: number,
    text: string,
    fontSize: number
  ): Promise<EncodingResult> {
    if (frames.length === 0) {
      throw new Error("No frames provided.");
    }

    const tempUuid = shortUUID.generate();
    const inputFiles = await Promise.all(
      frames.map(async (f, index) => {
        const res = await axios.get<ArrayBuffer>(f.thumbnail.url, {
          responseType: "arraybuffer",
        });
        const webpBuffer = Buffer.from(res.data);
        const tempFilePath = path.join(
          os.tmpdir(),
          `${tempUuid}_${index}.webp`
        );
        fs.writeFileSync(tempFilePath, webpBuffer, { flush: true });
        return tempFilePath;
      })
    );
    console.info("[VideoEncoder] Images fetched");

    const subsPath = path.join(os.tmpdir(), `${tempUuid}.srt`);
    fs.writeFileSync(subsPath, this.textToSrt(text), { flush: true });

    const isSingleFrame = inputFiles.length === 1;
    const outputFilePath = path.join(os.tmpdir(), `${tempUuid}.webp`);
    const ffmpegArgs = [
      "-hide_banner",
      "-loglevel",
      "error",
      ...inputFiles.flatMap((file) => ["-i", file]),
      "-fps_mode",
      "passthrough",
      "-filter_complex",
      `concat=n=${inputFiles.length}:v=1:a=0[v]; \
      [v]settb=AVTB,setpts=N/${frameRate}/TB,fps=${frameRate}[v2]; \
      [v2]subtitles=${subsPath}:fontsdir=/srv:force_style='FontName=Lithos,FontSize=${fontSize},MarginL=0,MarginR=0,Alignment=2,PrimaryColour=&HFFFFFF&,OutlineColour=&H000000&,BorderStyle=1,Outline=2'[out]`,
      "-map",
      "[out]",
      "-c:v",
      "libwebp",
      "-loop",
      "0",
      "-lossless",
      "0",
      "-q:v",
      "30",
      "-an",
      outputFilePath,
    ];

    const ffmpeg = spawn("ffmpeg", ffmpegArgs);
    ffmpeg.stderr.on("data", (data) => {
      console.error(`stderr: ${data}`);
    });

    return new Promise<EncodingResult>((resolve, reject) => {
      ffmpeg.on("error", reject);
      ffmpeg.on("close", (code) => {
        if (code !== 0) {
          return reject(new Error(`ffmpeg exited with ${code}`));
        }
        const result = fs.readFileSync(outputFilePath);

        resolve({
          data: result,
          mimeType: "image/webp",
          isVideo: !isSingleFrame,
        });
      });
    });
  }

  private textToSrt(text: String) {
    return `1\n00:00:00,000 --> 00:00:20,000\n${text}\n`;
  }
}

export interface EncodingResult {
  data: Buffer;
  mimeType: string;
  isVideo: boolean;
}
