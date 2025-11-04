import { Request, Response, Router } from "express";
import { Datastore } from "./datastore";
import { EncodingResult, VideoEncoder } from "./video_encoder";
import { S3Storage } from "./storage";
import shortUUID from "short-uuid";
import z from "zod";

export function router(
  datastore: Datastore,
  videoEncoder: VideoEncoder,
  storage: S3Storage
): Router {
  const router = Router();

  router.get("/search", async (req: Request, res: Response) => {
    let query: SearchQueryParams;
    try {
      query = searchQuerySchema.parse(req.query);
    } catch (e) {
      return res.sendStatus(400);
    }
    const { results, totalResults } = await datastore.searchText(
      query.q,
      query.offset
    );
    return res.json({ data: results, meta: { totalResults: totalResults } });
  });

  router.get("/media", async (req: Request, res: Response) => {
    let query: FramesQueryParams;
    try {
      query = framesQuerySchema.parse(req.query);
    } catch (e) {
      return res.sendStatus(400);
    }
    const results = await datastore.fetchFrames(
      query.media_id,
      query.index,
      query.direction,
      query.count
    );
    return res.json({
      data: results,
      meta: { maxIndex: await datastore.durationFramesOfMedia(query.media_id) },
    });
  });

  router.post("/meme", async (req: Request, res: Response) => {
    res.setHeader("Content-Type", "text/event-stream");
    res.setHeader("Cache-Control", "no-cache");
    res.setHeader("Connection", "keep-alive");
    res.flushHeaders();

    function send(data: any) {
      res.write(`data: ${JSON.stringify(data)}\n\n`);
    }

    let body;
    try {
      body = postMemeBodySchema.parse(req.body);
    } catch {
      send({ type: "error", message: "Invalid request body" });
      return res.end();
    }

    send({ type: "progress", progress: 0.05 });
    const frames = await datastore.fetchFrameRange(
      body.mediaId,
      body.startFrame,
      body.endFrame
    );

    send({ type: "progress", progress: 0.25 });
    let encodingResult: EncodingResult;
    try {
      encodingResult = await videoEncoder.encode(frames, 24, body.text);
    } catch (e) {
      console.error(e);
      send({ type: "error", message: "Encoding failed" });
      return res.end();
    }

    send({ type: "progress", progress: 0.8 });
    const key = storage.generateMemeKey(shortUUID.generate());
    try {
      await storage.upload(key, encodingResult.data, encodingResult.mimeType);
    } catch {
      send({ type: "error", message: "Upload failed" });
      return res.end();
    }

    send({ type: "progress", progress: 1.0 });
    const url = storage.urlForKey(key);
    send({
      type: "complete",
      data: { url: url, isVideo: encodingResult.isVideo },
    });
    res.end();
  });

  return router;
}

const searchQuerySchema = z.object({
  q: z.string(),
  offset: z.coerce.number().optional(),
});

type SearchQueryParams = z.infer<typeof searchQuerySchema>;

const framesQuerySchema = z.object({
  media_id: z.string(),
  index: z.coerce.number().int(),
  direction: z.enum(["before", "after"]).optional(),
  count: z.coerce.number().int().optional(),
});

type FramesQueryParams = z.infer<typeof framesQuerySchema>;

const postMemeBodySchema = z.object({
  mediaId: z.string(),
  startFrame: z.coerce.number().int(),
  endFrame: z.coerce.number().int(),
  text: z.string(),
});

type PostMemeBody = z.infer<typeof postMemeBodySchema>;
