import { Request, Response, Router } from "express";
import { Datastore } from "./datastore";
import z from "zod";

export function router(datastore: Datastore): Router {
  const router = Router();

  router.get("/search", async (req: Request, res: Response) => {
    let query: SearchQueryParams;
    try {
      query = searchQuerySchema.parse(req.query);
    } catch (e) {
      return res.sendStatus(400);
    }
    const results = await datastore.searchText(query.q);
    return res.json({ data: results });
  });

  router.get("/media", async (req: Request, res: Response) => {
    let query: FramesQueryParams;
    try {
      query = framesQuerySchema.parse(req.query);
    } catch (e) {
      console.log(e);
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

  return router;
}

const searchQuerySchema = z.object({
  q: z.string(),
});

type SearchQueryParams = z.infer<typeof searchQuerySchema>;

const framesQuerySchema = z.object({
  media_id: z.string(),
  index: z.coerce.number().int(),
  direction: z.enum(["before", "after"]).optional(),
  count: z.coerce.number().int().optional(),
});

type FramesQueryParams = z.infer<typeof framesQuerySchema>;
