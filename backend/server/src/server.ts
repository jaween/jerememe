import express from "express";
import logger from "./log.js";
import { router } from "./router.js";
import cors from "cors";
import { Datastore } from "./datastore.js";

async function init() {
  const expressApp = express();
  expressApp.use(cors());
  expressApp.use(express.json());

  expressApp.use((req, res, next) => {
    logger.info(
      `Request ${req.method} ${req.originalUrl} BODY: ${JSON.stringify(
        req.body
      )}`
    );
    next();
  });

  const datastore = new Datastore("./data.db");

  const apiRouter = router(datastore);

  expressApp.use("/v1", apiRouter);

  const port = process.env.PORT || 8080;
  expressApp.listen(port, () => {
    logger.info(`Web server started on port ${port}`);
  });
}

init();
