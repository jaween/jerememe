import { Request, Response, Router } from "express";
import { Datastore } from "./datastore";
import { VideoEncoder } from "./video_encoder";
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
    let body: PostMemeBody;
    try {
      body = postMemeBodySchema.parse(req.body);
    } catch (e) {
      return res.sendStatus(400);
    }
    const frames = await datastore.fetchFrameRange(
      body.mediaId,
      body.startFrame,
      body.endFrame
    );

    let video: Buffer;
    try {
      video = await videoEncoder.encode(frames, 24, body.text);
    } catch (e) {
      console.error(e);
      return res.sendStatus(500);
    }

    const videoKey = storage.generateMemeKey(shortUUID.generate());
    try {
      await storage.upload(videoKey, video, "video/webm");
    } catch (e) {
      return res.sendStatus(500);
    }

    const url = storage.urlForKey(videoKey);
    return res.json({ data: { url: url } });
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
