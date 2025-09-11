FROM europe-north1-docker.pkg.dev/holi-shared/docker-hub-remote/node:22-slim
WORKDIR /app

ARG NODE_ENV=development
ENV NODE_ENV=${NODE_ENV}

# Copy the package manager files and configuration files first
# This allows Docker to cache the layer with dependencies, speeding up builds
COPY package.json yarn.lock .yarnrc.yml \
  .eslintignore .eslintrc.js babel.config.cjs biome.json codegen.ts global.d.ts localazy.json turbo.json tsconfig.json \
  jest.config.cjs jest.setup-after-env.ts jest.setup.chat.ts jest.setup.ts jest.styleMock.cjs jestFileTransformer.cjs \
  ./
COPY .yarn/ .yarn/
# Copy all source files
COPY apps/ apps/
COPY core/ core/
COPY holi-apps/ holi-apps/
COPY e2e/ e2e/
COPY holi-bricks/ holi-bricks/
COPY packages/ packages/

# Dependencies must be installed after copying the source files
# to make sure that all dependencies are included
RUN corepack enable && \
  yarn install --check-cache && \
  yarn cache clean

# Next.js collects completely anonymous telemetry data about general usage.
# Learn more here: https://nextjs.org/telemetry
# Uncomment the following line in case you want to disable telemetry.
ENV NEXT_TELEMETRY_DISABLED=1

CMD ["yarn", "web:dev"]
