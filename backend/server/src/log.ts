import winston from "winston";
import { LoggingWinston as GoogleCloudLoggingWinston } from "@google-cloud/logging-winston";

const productionEnvironment = process.env.ENVIRONMENT === "production";

const logger = winston.createLogger({
  level: "info",
  transports: [
    ...(productionEnvironment
      ? [new GoogleCloudLoggingWinston()]
      : [new winston.transports.Console()]),
  ],
});

export default logger;
