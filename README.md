# holi-meta

The meta repository which helps you check out the other repositories and run a development environment locally.

<!-- TOC -->
- [holi-meta](#holi-meta)
  - [Getting started](#getting-started)
    - [Requirements](#requirements)
      - [direnv \&\& nodenv/nvm](#direnv--nodenvnvm)
      - [Yarn](#yarn)
      - [Ory](#ory)
      - [Emulator](#emulator)
      - [Google Pub/Sub Emulator](#google-pubsub-emulator)
      - [OwnCloud Infinite Storage (OCIS)](#owncloud-infinite-storage-ocis)
      - [Jitsi Meet](#jitsi-meet)
      - [Docker-Compose](#docker-compose)
      - [Deno](#deno)
      - [brew](#brew)
    - [Initialization](#initialization)
    - [IDE setup](#ide-setup)
  - [Running dev environments via mprocs](#running-dev-environments-via-mprocs)
    - [Local backend on Android](#local-backend-on-android)
  - [Helper scripts](#helper-scripts)
    - [forall-git](#forall-git)
  - [Port registry](#port-registry)
  - [Terraform authentication (optional)](#terraform-authentication-optional)
<!-- /TOC -->

## Getting started

### Requirements

#### brew

Some tools are installed via [brew](https://docs.brew.sh/Installation). Please follow the instructions for installing it
(on MacOS AND also on Linux (using the installation script, no local installation) in order to keep cross-platform complexity low).

Make sure to integrate the brew shell-hook before nodenv,nvm and pyenv to avoid brew installed versions to take precedence.

#### direnv && nodenv/nvm

Before we can get started building, please ensure that
both [`direnv`](https://github.com/direnv/direnv/blob/master/docs/installation.md) and one of the following node version
managers are installed and properly set up on your system (if in doubt, use nodenv):

- [`nodenv`](https://github.com/nodenv/nodenv) or
- [`nvm`](https://github.com/nvm-sh/nvm)

Follow the instructions in the corresponding READMEs for setup.

`.node-version` (used by `nodenv`) ensures that all developers are using the same `node`/`npm` versions.
It is kept in sync with `.nvmrc` (used by `nvm`) by a symbolic link, so please make sure to use a format that is
understood by both tools (e.g. a fixed version).

Once you installed these tools, please leave and re-enter the project directory. direnv will ask you for permission to execute:

```
direnv: error /home/exampleuser/holi-meta/.envrc is blocked. Run `direnv allow` to approve its content
```

Run `direnv allow` to load the environment for the `holi-meta` project. This will install your first node environment.
Afterwards, `which npm` should point to a node environment managed by either `nodenv` or `nvm`.

#### Yarn

Install yarn using `npm install --global yarn` and add yarn commands to your path by commenting out the line
`export PATH="$PATH:$(yarn global bin)"` in your .envrc.local for being able to run `mprocs` later.

#### pyenv

Some components (e.g. holi-okuna and pubsub) require Python. They are using [pyenv](https://github.com/pyenv/pyenv) in order to install the specific versions of Python they need into virtualenvs. You can [install](https://github.com/pyenv/pyenv#installation) it via
brew.

#### Ory

We're using Ory for authentication. For local development, we need a proxy. You can install the proxy
via <https://www.ory.sh/docs/guides/cli/installation>.

#### Emulator

For installing the Android Emulator needed for running the mobile dev environment, please read
the [`readme`](https://gitlab.holi.team/app/holi-frontends/-/blob/main/README.md) in `holi-frontends`.

#### Google Pub/Sub Emulator

To develop and test our event-driven applications locally, we use the [Google Pub/Sub emulator](https://cloud.google.com/pubsub/docs/emulator), which provides local emulation of the Google Cloud Pub/Sub production service.

Please make sure you installed and are authenticated with [`gcloud` CLI](https://cloud.google.com/sdk/docs/install?hl=de). Later steps will then ensure correct installation of the emulator.

Please note that all topics, subscriptions, and messages published to the emulator are only maintained for the lifetime of the emulator session.

Currently, `okuna` stands as the sole `publisher` of Google Pub/Sub. Similarly, `holi-ocis-integration`, which is referred to as `ocis-subscriber` in `mprocs-local-backend.yaml`, is the only `subscriber` of this service. This means that `okuna` is responsible for pushing messages to the Pub/Sub topic, and `ocis-subscriber` is the only client that receives and consumes those messages.

To obtain further information on the `holi-ocis-integration` project, please refer to the accompanying [`README.md`](https://gitlab.holi.team/app/holi-ocis-integration/-/blob/a876e59b1985685827f937243f9d0b286060efc9/README.md).

#### OwnCloud Infinite Storage (OCIS)

To run OCIS locally there are additional steps required, please read the [`readme`](https://gitlab.holi.team/app/holi-ocis/-/blob/main/README.md) in `holi-ocis`.

#### Jitsi Meet

To run jitsi locally there are additional steps required, please read the [`readme`](https://gitlab.holi.team/app/holi-meet/-/blob/main/README.md) in `holi-meet`.

#### Docker-Compose

Some projects (e.g. okuna) are using Docker or Docker-Compose to run their dev environment.
Please [`install Docker-Compose`](https://docs.docker.com/compose/install/).

#### Deno

Some projects are using deno. [`Install it`](https://deno.land/manual@v1.36.0/getting_started/installation) and follow
the instructions to add it to your environment.

### Initialization

Once you have installed all prerequisites (or after anything changed in the setup), you can execute

`direnv allow`
`./init.sh`

and the script will set up everything for you. At the end, it will display a big `DONE` banner. If it does not,
then either it ran into an error, giving a message, or stopped due to a bug. Either fix the error or re-run the script.

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

## Running dev environments via mprocs

In this repository, there are `mprocs*.yaml` files. Each one creates a unique dev environment by starting multiple cli
processes. The default one, `mprocs.yaml`, can be started by just executing `mprocs`. It starts up everything you need
for frontend development, connecting to APIs in the cloud based staging environments. When `mprocs` is running, you can
simply switch panes using `Ctrl+a`.

If you need to work on APIs as well, you can execute different mprocs configurations. For example, in order to work on
the okuna backend, run `mprocs -c mprocs-local-backend.yaml` instead, which will spin up Oathkeeper, the unified API and
Okuna locally next to the frontends. This is currently not possible for Open Source contributors, see [TODO for Open Source contributions](#todo-for-open-source-contributions)

### Local backend on Android

For Android you have to explicitly forward the port for the locally running backend, e.g. using

```sh
adb reverse tcp:4455 tcp:4455
```

## TODO for Open Source contributions

The following issues currently do not allow Open Source contributors to have a full development environment including backends:

* running a completely local emulator without a dependency on an existing gcloud project
* not depending on an ory cloud account for local identity management



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
| okuna                           | 8000 |
| donations                       | 8001 |
| goodnews                        | 8002 |
| geo                             | 8003 |
| volunteering                    | 8004 |
| pubsub-emulator                 | 8085 |
| ocis-subscriber                 | 8086 |
| ocis-postgres                   | 8087 |
| ocis                            | 9200 |
| onlyoffice                      | 9201 |
| wopiserver                      | 8880 |
| meet                            | 9300 |
| meet (ssl)                      | 9343 |
| meet (auth)                     | 9301 |

## Terraform authentication (optional)

All projects checked out below holi-meta are set up to authenticate to terraform/google via a keyfile that is expected to be found in holi-meta/.holi-terraform.key. If you need to run terraform locally, please ask any oldie to provide you with the necessary key file.
