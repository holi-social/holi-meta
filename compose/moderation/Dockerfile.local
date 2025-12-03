FROM europe-north1-docker.pkg.dev/holi-shared/docker-hub-remote/node:22-slim

WORKDIR /app
ARG NODE_ENV=development
ENV NODE_ENV=${NODE_ENV}

COPY package.json yarn.lock .yarnrc.yml ./
COPY .yarn/ .yarn/
COPY --chown=node:node . ./

RUN corepack enable && \
  yarn install --immutable --check-cache && \
  yarn cache clean

USER node
EXPOSE 3001
