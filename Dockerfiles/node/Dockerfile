FROM node:18-alpine

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