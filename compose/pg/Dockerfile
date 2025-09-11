FROM europe-north1-docker.pkg.dev/holi-shared/docker-hub-remote/postgres:17

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      postgis postgresql-17-postgis-3 \
 && rm -rf /var/lib/apt/lists/*
