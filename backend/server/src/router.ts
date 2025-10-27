import { Request, Response, Router } from "express";
import { Datastore } from "./datastore";

export function router(datastore: Datastore): Router {
  const router = Router();

  router.get("/", async (req: Request, res: Response) => {
    const results = await datastore.search("kyle");
    return res.json({ result: "success", results: results });
  });

  return router;
}
