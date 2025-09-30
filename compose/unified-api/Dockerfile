FROM europe-north1-docker.pkg.dev/holi-shared/docker-hub-remote/node:22-slim

WORKDIR /app
ARG NODE_ENV=development
ENV NODE_ENV=${NODE_ENV}

COPY tsconfig.json package.json yarn.lock .meshrc.yml .yarnrc.yml logger.ts url.ts instrument.ts server.ts ./
COPY handlers ./handlers

# RUN chown -R node:node /app && corepack enable
RUN corepack enable && \
  yarn install --immutable --check-cache && \
  yarn cache clean

USER node
EXPOSE 4000

CMD ["yarn", "run", "dev"]