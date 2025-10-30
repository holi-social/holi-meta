FROM europe-north1-docker.pkg.dev/holi-shared/docker-hub-remote/denoland/deno:2.5.6

# The port that your application listens to.
EXPOSE 8015

# Prefer not to run as root.
USER deno

WORKDIR /app
COPY deno.lock .
COPY deno.json .
COPY . /app

RUN deno cache --allow-import src/index.ts

CMD ["sh", "-c", "deno run db:migrate && deno run serve:dev"]
