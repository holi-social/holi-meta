# holi-meta

The meta repository which helps you check out the other repositories and run a development environment locally.

<!-- TOC -->

- [Preface](#preface)
- [Getting started](#getting-started)
  - [Requirements](#requirements)
    - [brew](#brew)
      - [Installation](#installation)
      - [Configuration](#configuration)
    - [direnv](#direnv)
      - [Installation](#installation)
      - [Configuration](#configuration)
    - [nodenv/nvm](#nodenvnvm)
      - [Installation](#installation)
      - [Allowing direnv](#allowing-direnv)
    - [Yarn](#yarn)
      - [Installation](#installation)
      - [Configuration](#configuration)
    - [pyenv](#pyenv)
      - [Installation](#installation)
      - [Configuration](#configuration)
    - [Ory](#ory)
    - [Google Pub/Sub Emulator](#google-pubsub-emulator)
      - [Install gcloud](#install-gcloud)
      - [Information about Pub/Sub in development](#information-about-pubsub-in-development)
    - [OwnCloud Infinite Storage (OCIS)](#owncloud-infinite-storage-ocis)
    - [Jitsi Meet](#jitsi-meet)
    - [Chat](#chat)
    - [Docker-Compose](#docker-compose)
      - [Start Docker Desktop (optional)](#start-docker-desktop-optional)
    - [Deno](#deno)
      - [Installation](#installation)
      - [Install velociraptor](#install-velociraptor)
  - [Initialization](#initialization)
  - [IDE setup](#ide-setup)
  - [Last steps](#last-steps)
- [Running dev environments via mprocs](#running-dev-environments-via-mprocs)
  - [Local backend on Android Emulator](#local-backend-on-android-emulator)
- [TODO for Open Source contributions](#todo-for-open-source-contributions)
- [Helper scripts](#helper-scripts)
  - [forall-git](#forall-git)
- [Port registry](#port-registry)
- [Terraform authentication (optional)](#terraform-authentication-optional)
<!-- /TOC -->

## Preface

holi is quite complex, consisting of many components, running on a diverse tech stack. Because of this, setting up a development environment is hard to do without help. Even with help, it can go wrong.

We tried and are trying continuously to give our best support for setting up a dev environment. This manual is very detailed, while leaving some degrees of freedom to the developer. In order to succeed in setting up your dev environment, please try to follow this documentation as strict as you can. If you are running into issues during the setup that you can't figure out and where the documentation is lacking, feel free to contact the holi dev team for support.

## Getting started

### Requirements

#### brew

##### Installation

Some tools are installed via [brew](https://docs.brew.sh/Installation). Please follow the instructions for installing it
(on MacOS AND also on Linux (using the default installation script, no "local installation") in order to keep cross-platform complexity low).

##### Configuration

Make sure to integrate the brew shell-hook before direnv, nodenv, nvm and pyenv to allow your environment to find tools
installed via brew and to avoid brew installed versions to take precedence over ones installed via other methods.
You can achieve this by installing the brew shell hook to `.bashrc` (above all other hook we will install) instead
of the recommended `.profile` file.

#### direnv

##### Installation

Please install [`direnv`](https://github.com/direnv/direnv/blob/master/docs/installation.md) (can be installed via `brew install direnv`

##### Configuration

Please set up the [shell hook](https://github.com/direnv/direnv/blob/master/docs/hook.md)) for direnv.

#### nodenv/nvm

##### Installation

Before we can get started building, please ensure that at least one of the following node version managers are installed and properly set up on your system (we mostly use nodenv, so when in doubt, use that):

- [`nodenv`](https://github.com/nodenv/nodenv) (`brew install nodenv` & set up shell hook) or
- [`nvm`](https://github.com/nvm-sh/nvm)

Follow the instructions in the corresponding READMEs for setup.

`.node-version` (used by `nodenv`) ensures that all developers are using the same `node`/`npm` versions.
It is kept in sync with `.nvmrc` (used by `nvm`) by a symbolic link, so please make sure to use a format that is
understood by both tools (e.g. a fixed version).

##### NVM Configuration

By default, the Unified API uses `nodenv` to manage the node version. If you are using `nvm`,
please comment out the `nodenv` line and uncomment the `nvm` lines in your `holi-unified-api/.envrc.local` file,
as shown in the example below:

```sh
# installing correct node version using nodeenv
# nodenv install -s $(cat .node-version)
# alternative using nvm
. ~/.nvm/nvm.sh # load nvm command
nvm use
```

##### Allowing direnv

Once you installed these tools, please leave and re-enter the project directory. direnv will ask you for permission to execute:

```
direnv: error /home/exampleuser/holi-meta/.envrc is blocked. Run `direnv allow` to approve its content
```

Run `direnv allow` to load the environment for the `holi-meta` project. This will install your first node environment.
Afterwards, `which npm` should point to a node environment managed by either `nodenv` or `nvm`.

#### Yarn

##### Installation

Install yarn using `npm install --global yarn`.

##### Configuration

Add yarn commands to your path by commenting out the line `export PATH="$PATH:$(yarn global bin)"` in your .envrc.local for being able to run `mprocs` later. Afterwards, log out of your shell and log back in, switching back to the holi-meta project's directory. You should now be able to run 'yarn --version' successfully.

#### pyenv

##### Installation

Some components (e.g. holi-okuna and pubsub) require Python. They are using [pyenv](https://github.com/pyenv/pyenv) in order to install the specific versions of Python they need into virtualenvs. You can [install](https://github.com/pyenv/pyenv#installation) it via brew.

##### Configuration

For building python versions from source, pyenv needs some build dependencies. Please install them according to [this manual](https://devguide.python.org/getting-started/setup-building/index.html#install-dependencies).

#### Ory

We're using Ory for authentication. For local development, we need a proxy. You can install the proxy
via <https://www.ory.sh/docs/guides/cli/installation> using brew.

#### Google Pub/Sub Emulator

To develop and test our event-driven applications locally, we use the [Google Pub/Sub emulator](https://cloud.google.com/pubsub/docs/emulator), which provides local emulation of the Google Cloud Pub/Sub production service.

##### Install gcloud

Please install [`gcloud` CLI](https://cloud.google.com/sdk/docs/install), as well as a **Java Runtime** (via your preferred method). Later steps will then ensure correct installation of the emulator.

##### Information about Pub/Sub in development

Please note that all topics, subscriptions, and messages published to the emulator are only maintained for the lifetime of the emulator session.

Currently, `okuna` stands as the sole `publisher` of Google Pub/Sub and is responsible for pushing messages to the Pub/Sub topic. There are 2 currently `subscribers` of this service, `holi-ocis-integration` (`ocis-subscriber` in `mprocs-local-backend.yaml`) and `holi-chat-integration` (`chat-subscriber` in `mprocs-local-backend.yaml`), both receive and consume those messages.

To obtain further information on the `holi-ocis-integration` project, please refer to the accompanying [`README.md`](https://gitlab.holi.team/app/holi-ocis-integration/-/blob/a876e59b1985685827f937243f9d0b286060efc9/README.md).

#### OwnCloud Infinite Storage (OCIS)

OCIS is not run locally as a default. To run OCIS locally there are additional steps required, please read the [`readme`](https://gitlab.holi.team/app/holi-ocis/-/blob/main/README.md) in `holi-ocis`.

#### Jitsi Meet

Jitsi Meet is not run locally as a default. To run jitsi locally there are additional steps required, please read the [`readme`](https://gitlab.holi.team/app/holi-meet/-/blob/main/README.md) in `holi-meet`.

#### Chat

Chat is not run locally as a default. To run chat locally there are additional steps required, please read the [`readme`](https://gitlab.holi.team/app/holi-chat-server/-/blob/main/README.md) in `holi-chat-server`.

#### Translation

Translation is not run locally as a default. To run translation locally there are additional steps required, please read the [`readme`](https://gitlab.holi.team/app/holi-libretranslate/-/blob/main/README.md) in `holi-libretranslate`.

#### Docker-Compose

Some projects (e.g. okuna) are using Docker or Docker-Compose to run their dev environment.
Please [`install Docker-Compose`](https://docs.docker.com/compose/install/) via the plugin, not as standalone. Afterwards, you might need to log out of your console and back in again.

##### Start Docker Desktop (optional)

If you installed Docker-Compose via Docker Desktop, you need to start it before development, or else the development environment will not successfully start.

#### Deno

##### Installation

Some projects are using deno. [`Install it`](https://docs.deno.com/runtime/manual/getting_started/installation) (via brew) and follow
the instructions to verify the installation.

##### Install velociraptor

Also, you need to install deno's script runner, [`Velociraptor`](https://velociraptor.run/docs/installation/). Don't forget to include the deno bin folder in your `PATH` (this is not very obvious from the installation manual) via e.g.

```
echo 'export PATH="$HOME/.deno/bin:$PATH"' >> ~/.bashrc
```

### Initialization

Once you have installed all prerequisites (or after anything changed in the setup), you can execute

`./init.sh`

and the script will set up everything for you. At the end, it will display a big `DONE` banner. If it does not,
then either it ran into an error, giving a message, or stopped due to a bug. Try to fix the error and then re-run the script.

If you also want to work on any optional, private repositories, then please execute

`./init.sh full`

for doing a full checkout.

Afterwards, you need to manually go into some directories (the ones using direnv for environment setup). Once you're in those directories, direnv will execute some setup code for the directories. You can determine a list of directories that need to be visited via the command:

`find . -mindepth 2 -maxdepth 2 -name .envrc|xargs dirname`

You can try to do this programmatically, but this is more error prone than visiting the directories manually:

`for path in $(find . -mindepth 2 -maxdepth 2 -name .envrc); do pushd $(dirname $path); bash  ; popd; done`

Every time the above command stops, you can check that the working directory is from the list of directories and that there was no error when running the setup. Afterwards, you can exit the shell and the command will work on the next directory. Do that until you're back in `holi-meta`.

### IDE setup

Now you can open the projects in your favourite IDE. It's up to you whether you open the holi-meta folder or the checked
out project subfolders in several IDEs .

### Last steps

- Run the following command to authorize Docker to access the Google Cloud Artifact registry.
  ```
  gcloud auth configure-docker europe-north1-docker.pkg.dev
  ```
- The Unified API uses imagekit.io for media processing. Please set the `IMAGEKIT_PUBLIC_KEY` and `IMAGEKIT_PRIVATE_KEY` available in Passbolt in `./holi-okuna/.env`.
- The Unified API and Translation API currently uses the same local redis instance as okuna. Therefore, please copy the `redisPassword` environment variable from
  `./holi-okuna/.okuna-cli.json` to `REDIS_PASSWORD` in both `./holi-unified-api/.envrc.local` and `./holi-translation-api/.envrc.local`.
- You will need to initialize okuna a bit. If okuna is not running properly, please follow `holi-okuna/README.md` for manual initialization.

## Running dev environments via mprocs

In this repository, there are `mprocs*.yaml` files. Each one creates a unique dev environment by starting multiple cli
processes. The default one, `mprocs.yaml`, can be started by just executing `mprocs`. It starts up everything you need
for frontend development, connecting to APIs in the cloud based staging environments. When `mprocs` is running, you can
simply switch panes using `Ctrl+a`.

If you need to work on APIs as well, you can execute different mprocs configurations. For example, in order to work on
the okuna backend, run `mprocs -c mprocs-local-backend.yaml` instead, which will spin up Oathkeeper, the unified API and
Okuna locally next to the frontends. This is currently not well tested for Open Source contributors, see [TODO for Open Source contributions](#todo-for-open-source-contributions). When running this, please be aware that initial startup might take minutes. Please carefully inspect all outputs to make sure that all processes (depending on one another) are starting up successfully.

And now, finally, comes the moment: Go to your browser and open `http://localhost:3000` and/or scan the QR code with the Expo Go app in your
mobile phone. You should see your own instance of holi and be able to code away.

### Creating an account

The local dev environment uses a separate identity database, so feel free to create test accounts for any amount of users you want or need for your development needs via the registration workflow on your local machine.

### Local backend on Android Emulator

For using an Android Emulator you have to explicitly forward the port for the locally running backend, e.g. using

```sh
adb reverse tcp:4455 tcp:4455
```

and you have to change the DEV_HOST variable in `./holi-frontends/.env.local` (it's documented and prepared for you).

## TODO for Open Source contributions

The following issues currently make it difficult for Open Source contributors to have a full development environment including backends:

- Some backends need secrets in order to function properly (holi-app-\*, holi-geo-api). Current solution: They provide a fake mode, in which they return dummy data.
- okuna needs a token to call the ory API. Current solution: if no token is set, the API is not called.

## Helper scripts

This repository includes some nice helper scripts to help with working with holi-meta. These are added to the path via direnv.

### forall-git

This script executes git commands in this repository as well as in any git repository that is inside this repository (e.g. holi-frontends, holi-okuna, holi-unified-api etc.). For example, you can pull/update all repositories at once using:

```sh
forall-git git status # inspect if there is any changes left in any repository, and if not
forall-git git checkout main # switch to the main branch in all repositories
forall-git git pull # pull all repositories
```

## Port registry

The following table lists all ports that are used for local execution.

| Application                     | Port |
|---------------------------------|------|
| oathkeeper                      | 4455 |
| unified-api                     | 4000 |
| chat-server (matrix client)     | 8008 |
| chat-server (matrix federation) | 8448 |
| chat-server (traefik proxy)     | 8010 |
| chat-server (traefik proxy)     | 8011 |
| chat-server (sygnal)            | 8050 |
| okuna                           | 8000 |
| donations                       | 8001 |
| goodnews                        | 8002 |
| geo                             | 8003 |
| volunteering                    | 8004 |
| notifications                   | 8005 |
| app-events                      | 8006 |
| pubsub-emulator                 | 8085 |
| ocis-subscriber                 | 8086 |
| ocis-postgres                   | 8087 |
| chat-subscriber                 | 8088 |
| ocis                            | 9200 |
| onlyoffice                      | 9201 |
| wopiserver                      | 8880 |
| meet                            | 9300 |
| meet (ssl)                      | 9343 |
| meet (auth)                     | 9301 |
| translation-api                 | 8089 |
| libretranslate                  | 5000 |
| moderation ui (backoffice)      | 5173 |  
| moderation backend              | 3001 |  
| moderation federator            | 8080 |  
|                                 |      |
| storybook (holi-bricks)         | 6006 |
| storybook (legacy)              | 6007 |

## Terraform Installation (optional)

If you want to run terraform locally, it's better to install it through [tfenv](https://github.com/tfutils/tfenv#tfenv) to avoid version conflicts. You can install it via brew: `brew install tfenv`

## Terraform authentication (optional)

All projects checked out below holi-meta are set up to authenticate to terraform/google via a keyfile that is expected to be found in holi-meta/.holi-terraform.key. If you need to run terraform locally, please ask any oldie to provide you with the necessary key file.
