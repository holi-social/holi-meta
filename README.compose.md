
# holi-meta

The meta repository which helps you check out the other repositories and run a development environment locally.

- [holi-meta](#holi-meta)
  - [Preface](#preface)
  - [Getting started](#getting-started)
    - [Requirements](#requirements)
      - [Docker Compose](#docker-compose)
        - [Start Docker Desktop (optional)](#start-docker-desktop-optional)
      - [gcloud](#gcloud)
      - [direnv](#direnv)
        - [Installation](#installation)
        - [Configuration](#configuration)
    - [Initialization](#initialization)
    - [IDE setup](#ide-setup)
    - [Last steps](#last-steps)
  - [Running dev environments via docker compose](#running-dev-environments-via-docker-compose)
    - [Get Started](#get-started)
    - [Commands](#commands)
      - [Start](#start)
      - [Status](#status)
      - [Logs](#logs)
      - [Stop](#stop)
      - [Migrate](#migrate)
        - [Recreate the database](#recreate-the-database)
        - [Migrate the database](#migrate-the-database)
        - [Access the PostgreSQL instance](#access-the-postgresql-instance)
      - [Services](#services)
      - [Attach](#attach)
      - [Compose](#compose)
    - [Troubleshooting](#troubleshooting)
      - [Frontend Image Build Error: Cannot Allocate Memory](#frontend-image-build-error-cannot-allocate-memory)
      - [Deno lockfile version mismatch](#deno-lockfile-version-mismatch)

## Preface

holi is quite complex, consisting of many components, running on a diverse tech stack. Because of this, setting up a development environment is hard to do without help. Even with help, it can go wrong.

We tried and are trying continuously to give our best support for setting up a dev environment. This manual is very detailed, while leaving some degrees of freedom to the developer. In order to succeed in setting up your dev environment, please try to follow this documentation as strict as you can. If you are running into issues during the setup that you can't figure out and where the documentation is lacking, feel free to contact the holi dev team for support.

## Getting started

### Requirements

#### Docker Compose

This project uses Docker Compose to run its development environment.
Please [`install Docker Compose`](https://docs.docker.com/compose/install/) via the plugin, not as standalone. Afterwards, you might need to log out of your console and back in again.

##### Start Docker Desktop (optional)

If you installed Docker Compose via Docker Desktop, you need to start it before development, or else the development environment will not successfully start.

#### gcloud

Please install [`gcloud` CLI](https://cloud.google.com/sdk/docs/install) and authenticate with your Google account using

```sh
gcloud auth login
```

#### direnv

##### Installation

Please install [`direnv`](https://github.com/direnv/direnv/blob/master/docs/installation.md) (can be installed via `brew install direnv`

##### Configuration

Please set up the [shell hook](https://github.com/direnv/direnv/blob/master/docs/hook.md)) for direnv.

### Initialization

Once you have installed all prerequisites (or after anything changed in the setup), you can execute

```sh
./init.sh
```

and the script will set up everything for you. At the end, it will display a big `DONE` banner. If it does not,
then either it ran into an error, giving a message, or stopped due to a bug. Try to fix the error and then re-run the script.

If you also want to work on any optional, private repositories, then please execute

```sh
./init.sh full
```

for doing a full checkout.

### IDE setup

Now you can open the projects in your favourite IDE. It's up to you whether you open the holi-meta folder or the checked
out project subfolders in several IDEs .

### Last steps

1. Run the following command to authorize Docker to access the Google Cloud Artifact registry.

  ```
  gcloud auth configure-docker europe-north1-docker.pkg.dev
  ```

2. Run `./holi-dev.sh init` to create the necessary environment files.
3. Fill the following secrets from passbolt:

- The Unified API uses imagekit.io for media processing. Please set the `IMAGEKIT_PUBLIC_KEY` and `IMAGEKIT_PRIVATE_KEY` available in Passbolt in `./holi-okuna/.docker-compose.env.local`.
- Set `HOLI_CHAT_ORY_CLIENT_ID` and `HOLI_CHAT_ORY_CLIENT_SECRET` in `./holi-chat-server/.envrc.local`.
- Set `APNS_KEY_ID`, `APNS_TEAM_ID`, and `APNS_TOPIC` in `./holi-chat-server/.envrc-push-gateway.local`.
- Fill `./holi-chat-server/data-push-gateway/apns_keyfile_staging.p8` with `APNS_KEYFILE_STAGING` and manually format it so that it looks like a ssh key.
- Fill `./holi-chat-server/data-push-gateway/fcm_keyfile.json` with `FCM Keyfile`
- Set `TYPESENSE_API_KEY` in `./compose/unified-api/.env`.

## Running dev environments via docker compose

You can use the `./holi-dev.sh` in the root of this repository to run the dev environments. This will start the necessary services in your local machine.

### Get Started

To get started with the development environment, you can use the following command:

```sh
./holi-dev.sh start
```

This will try to starts the essential services for local development in the background, and if docker images do not exist, it will build them locally and watch for file changes.

> ℹ️ **Note:** If you are running this command for the first time, please note that it takes a few minutes to build all docker images locally and
> uses system resources heavily. So please be patient and try to close the heavy processes before running this command.
>
> If you are using Docker Desktop, you can also increase the resource allocation settings.

> ℹ️ **Note:** If you stop the process, the services are still running in the background but the file watch doesn't work anymore and your local changes might not synced with the container.
> You can simply run the start command again to start the file watch.

Or, if you want to run a specific profile (a group of services), you can set the `COMPOSE_PROFILES` environment variable once (recommended) or use the `-p` or `--profile` argument on **every command**. Available profiles are:

- `minimal` (default): Only starts the necessary services for backend and frontend development. This includes:
  - `app-donations`
  - `app-goodnews`
  - `geo-api`
  - `app-events`
  - `translation-api`
  - `notifications`
  - `unified-api`
  - `oathkeeper`
  - `okuna`
  - `pubsub-emulators`
  - `chat-server`
  - `chat-push-gateway`
  - `chat-integration`
  - `rewards`
  - `frontend-web`
  - `frontend-mobile`
- `moderation`: Only starts the moderation services. This includes:
  - `moderation-backend`
  - `moderation-frontend`
  - `moderation-federator`
- `all`: This runs all the available services in `holi-meta`. This includes:
  - All the services in `minimal` and `moderation` profiles
  - `libretranslate`
  - `frontend-storybook`
- `frontend-staging`: Only starts the frontend services (`frontend-web` and `frontend-mobile`) against the staging backend. It doesn't run the backend services locally.

The command is as follows:

```sh
export COMPOSE_PROFILES=minimal
./holi-dev.sh start

# or

./holi-dev.sh --profile minimal start
```

You can check the status of the services and their health using `./holi-dev.sh status --all` command.

> *️⃣ **Tips:** If any of services have unhealthy status or they failed to start you can run the start command again to restart them.

To see the logs for a service, you can use `./holi-dev.sh logs --follow <service_name>` command.

### Commands

#### Start

To run the docker compose environment, you can simply use the following command to run the essential services for local development:

```sh
./holi-dev.sh start
```

Or, if you want to run a specific profile (a group of services), you can set the `COMPOSE_PROFILES` environment variable once or use the `-p` or `--profile` argument on every command. The command is as follows:

```sh
export COMPOSE_PROFILES=<profile_name_1>[,<profile_name_2>,...]
./holi-dev.sh start

# or

./holi-dev.sh --profile <profile_name_1>[,<profile_name_2>,...] start
```

**Example 1:** This only runs the frontend services against the staging backend.

```sh
export COMPOSE_PROFILES=frontend-staging
./holi-dev.sh start

# or

./holi-dev.sh --profile frontend-staging
```

**Example 2:** This runs all the available services in `holi-meta`.

```sh
export COMPOSE_PROFILES=all
./holi-dev.sh start

# or

./holi-dev.sh --profile all
```

**Example 3:** This runs the services in `minimal` and `moderation` profiles.

```sh
export COMPOSE_PROFILES=minimal,moderation
./holi-dev.sh start

# or

./holi-dev.sh --profile minimal,moderation
```

> **Advanced Tip**
>
> If you need to run a specific set of services that profiles do not cover, You can use service names argument to start specific services (separate them by space).
>
> ```sh
> ./holi-dev.sh start <service_name1> <service_name2> ...
> ```

#### Status

You can check the status of the services using:

```sh
# Status of all services
./holi-dev.sh status --all

# You can use service names to filter the output (separate them by space)
./holi-dev.sh status <service_name1> <service_name2> ...
```

#### Logs

You can also view the logs of the services using:

```sh
./holi-dev.sh logs --follow

# You can use service names to filter the logs (separate them by space)
./holi-dev.sh logs --follow <service_name1> <service_name2> ...
```

#### Stop

You can stop the services using:

```sh
./holi-dev.sh stop

# You can use service names to stop specific services (separate them by space)
./holi-dev.sh stop <service_name1> <service_name2> ...
```

#### Migrate

By default, the PostgreSQL instance is initialized using `compose/pg/init.sql` script. This script is automatically executed when the PostgreSQL container is started **for the first time** on your machine.
This creates databases, users and grants the necessary permissions.

##### Recreate the database

If you need to recreate the PostgreSQL database from scratch, you can use the `--recreate` flag:

***WARNING:** This will delete all data in your local PostgreSQL instance and recreate it by running the `init.sql` script.*

```sh
./holi-dev.sh migrate recreate
```

##### Migrate the database

To migrate an existing PostgreSQL instance and manage its users, access permissions and databases, you can write your queries in `compose/pg/migration.sql` and simply use the following command to run it:

*The pg service must be running in order to execute migrations.*

```sh
./holi-dev.sh migrate

# or 
./holi-dev.sh migrate path/to/file.sql
```

> **ℹ️ NOTE:** Make sure to add the queries to `compose/pg/init.sql` if you want them to be run for the next initialization of the PostgreSQL instance.

##### Access the PostgreSQL instance

If you need to access the PostgreSQL instance directly, you can use the following command:

```sh
./holi-dev.sh compose exec -i pg psql -U postgres 
```

#### Services

You can list all available services using the following command:

```sh
./holi-dev.sh services
```

#### Attach

Some services like `frontend-mobile` have an interactive terminal and after start you need to open a new terminal session
and attach to that service stdin and stdout to be able to control it. You can use this command to attach to the service:

```sh
./holi-dev.sh attach <service_name>
```

*CTRL+C can be used to detach from the service.*

#### Compose

You can use `docker compose` command as follows:

```sh
./holi-dev.sh compose [<command>] [<options>] [<service_name>]

# Examples:
./holi-dev.sh compose --help
./holi-dev.sh compose restart okuna
./holi-dev.sh compose stats
```

### Troubleshooting

These are some of the known issues and their workarounds.

#### Frontend Image Build Error: Cannot Allocate Memory

You may see the following error message while building the docker images:

```
failed to solve: ResourceExhausted: process "..." did not complete successfully: cannot allocate memory
```

In the logs, look for the last service that it tried to build the image for. Then run `./holi-dev.sh stop` to stop all the services to free up some memory and manually build the image for that service by running:

```sh
./holi-dev.sh compose build <service-name>

# Example:
./holi-dev.sh compose build frontend-web
```

After the build is done you can run the start command again to start all the services.

If it still didn't help and you use Docker Desktop, you can increase the memory limit in the Docker Desktop settings.

#### Deno lockfile version mismatch

If you encounter an error related to the Deno lockfile version, you may see a message similiar to this:

```
error: Failed reading lockfile at 'deno.lock'
Caused by:
    Unsupported lockfile version '5'. Try upgrading Deno or recreating the lockfile
```

This happens because the base docker image for this service uses a Deno version that is not compatible with the Deno.lock file version on your machine.
While we always should make sure these two versions are compatible, sometimes issues can still arise. This is the step-by-step guide to resolve the issue:

- Pull the latest changes from the `holi-meta` repository and the service repository to ensure you have the most up-to-date configurations and Deno.lock.
- Re-build the current image using `./holi-dev.sh compose build <service-name>` command and try to start the services again.
- If the issue persists, the Deno.lock file needs to be recreated to match the docker image Deno version. Note that this may lead to differences in dependencies and should be done cautiously.
