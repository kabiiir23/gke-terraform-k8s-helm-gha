FROM node:18-alpine

RUN apk add --no-cache libc6-compat

# node-gyp dependencies
RUN apk add --update --no-cache python3
RUN apk add --no-cache build-base \
    g++ \
    libpng \
    libpng-dev \
    jpeg-dev \
    pango-dev \
    cairo-dev \
    giflib-dev

RUN apk --no-cache add openssl git ffmpeg curl \
    && curl -sLO https://github.com/github/git-lfs/releases/download/v2.0.1/git-lfs-linux-amd64-2.0.1.tar.gz \
    && tar zxvf git-lfs-linux-amd64-2.0.1.tar.gz \
    && mv git-lfs-2.0.1/git-lfs /usr/bin/ \
    && rm -rf git-lfs-2.0.1 \
    && rm -rf git-lfs-linux-amd64-2.0.1.tar.gz

RUN git lfs install

ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# verify ffmpeg
RUN ffmpeg -version
RUN ffprobe -version

WORKDIR /app
COPY package.json ./
RUN yarn install

COPY . .

ARG NODE_ENV
ENV NODE_ENV ${NODE_ENV}
ENV PORT 80

RUN yarn build

EXPOSE 80

CMD ["yarn", "start"]