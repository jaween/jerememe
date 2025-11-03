import express from "express";
import logger from "./log.js";
import { router } from "./router.js";
import cors from "cors";
import { Datastore } from "./datastore.js";
import { S3Storage } from "./storage.js";
import { VideoEncoder } from "./video_encoder.js";

function getS3Storage() {
  const awsAccessKeyId = process.env.AWS_ACCESS_KEY_ID;
  const awsSecretAccessKey = process.env.AWS_SECRET_ACCESS_KEY;
  const s3Region = process.env.S3_REGION;
  const s3BucketName = process.env.S3_BUCKET_NAME;
  const cdnPrefix = process.env.CDN_PREFIX;
  if (
    !(
      awsAccessKeyId &&
      awsSecretAccessKey &&
      s3Region &&
      s3BucketName &&
      cdnPrefix
    )
  ) {
    throw "Missing AWS environment variable";
  }
  return new S3Storage({
    accessKeyId: awsAccessKeyId,
    secretAccessKey: awsSecretAccessKey,
    region: s3Region,
    bucketName: s3BucketName,
    cdnPrefix: cdnPrefix,
  });
}

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

  const storage = getS3Storage();
  const datastore = new Datastore("./data.db", storage);
  const videoEncoder = new VideoEncoder();

  const apiRouter = router(datastore, videoEncoder, storage);

  expressApp.use("/v1", apiRouter);

  const port = process.env.PORT || 8080;
  expressApp.listen(port, () => {
    logger.info(`Web server started on port ${port}`);
  });
}

init();
