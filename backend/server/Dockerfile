FROM node:24-alpine3.21

ENV NODE_ENV $NODE_ENV
ENV BASE_URL $BASE_URL

RUN apk add --no-cache ffmpeg

# Source code
WORKDIR /srv/
COPY package.json .
COPY package-lock.json .
RUN npm install

COPY . .

RUN npm run build

USER node
EXPOSE 8080
CMD [ "npm", "start" ]
