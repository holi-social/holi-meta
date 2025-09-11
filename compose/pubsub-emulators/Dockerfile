# Stage 1: install Google Cloud SDK
FROM europe-north1-docker.pkg.dev/holi-shared/docker-hub-remote/debian:bookworm-slim AS builder

RUN apt-get update \
 && apt-get install --no-install-recommends -y \
    apt-transport-https \
    ca-certificates \
    gnupg \
    curl \
 && rm -rf /var/lib/apt/lists/*

RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
    > /etc/apt/sources.list.d/google-cloud-sdk.list \
 && curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
    | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg

RUN apt-get update \
 && apt-get install --no-install-recommends -y \
    google-cloud-cli \
    google-cloud-cli-pubsub-emulator \
 && rm -rf /var/lib/apt/lists/*

# Stage 2: minimal runtime with a Bookworm JRE
FROM europe-north1-docker.pkg.dev/holi-shared/docker-hub-remote/debian:bookworm-slim

RUN apt-get update \
 && apt-get install --no-install-recommends -y \
    ca-certificates \
     # gcloud cli depends on python3 to run
     python3 \
     # pubsub emulator depends on JRE to run
     default-jre-headless \
 && rm -rf /var/lib/apt/lists/*

# Copy over just the SDK and gcloud wrapper
COPY --from=builder /usr/lib/google-cloud-sdk /usr/lib/google-cloud-sdk
COPY --from=builder /usr/bin/gcloud           /usr/bin/gcloud

ENV PATH=/usr/lib/google-cloud-sdk/bin:$PATH
ENV PUBSUB_PROJECT_ID=test-project

EXPOSE 8085

ENTRYPOINT ["sh", "-c", "exec gcloud beta emulators pubsub start --host-port=0.0.0.0:8085 --project=${PUBSUB_PROJECT_ID}"]


