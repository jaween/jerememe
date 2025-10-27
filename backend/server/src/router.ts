import { Request, Response, Router } from "express";

export function router(): Router {
  const router = Router();

  router.get("/", async (req: Request, res: Response) => {
    return res.json({ result: "success" });
  });

  return router;
}
