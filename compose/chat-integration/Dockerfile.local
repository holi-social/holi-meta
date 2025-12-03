FROM europe-north1-docker.pkg.dev/holi-shared/docker-hub-remote/node:22-slim

WORKDIR /app
ENV NODE_ENV=development

COPY tsconfig.json package.json yarn.lock .yarnrc.yml ./
COPY src/ ./src/

RUN corepack enable && \
  yarn install --immutable --check-cache && \
  yarn cache clean && \
  yarn build 

USER node
EXPOSE 4000

CMD ["yarn", "run", "start:dev"]