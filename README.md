# holi-meta

The meta repository which helps you check out the other repositories and run a development environment locally.

## Getting started

### Requirements

#### direnv && nodenv/nvm

Before we can get started building, please ensure that both [`direnv`](https://github.com/direnv/direnv/blob/master/docs/installation.md) and one of the following node version managers are installed and properly set up on your system:

- [`nodenv`](https://github.com/nodenv/nodenv) or
- [`nvm`](https://github.com/nvm-sh/nvm)

Follow the instructions in the corresponding READMEs for setup.

`.node-version` (used by `nodenv`) ensures that all developers are using the same `node`/`npm` versions.
It is kept in sync with `.nvmrc` (used by `nvm`) by a symbolic link, so please make sure to use a format that is understood by both tools (e.g. a fixed version).

#### Ory

We're using Ory for authentication. For local development, we need a proxy. You can install the proxy via https://www.ory.sh/docs/guides/cli/installation.

#### Emulator

For installing the Android Emulator needed for running the mobile dev environment, please read the [`readme`](https://gitlab.com/holisticfoundation/holi-frontends/-/blob/main/README.md) in `holi-frontends`.

#### Docker-Compose

Some projects (e.g. okuna) are using Docker or Docker-Compose to run their dev environment. Please [`install Docker-Compose`](https://docs.docker.com/compose/install/).

### Initialization

Once you have installed all prerequisites (or after anything changed in the setup), you can execute

`./init.sh`

and the script will set up everything for you.

### IDE setup

Now you can open the projects in your favourite IDE. It's up to you whether you open the holi-meta folder or the checked out project subfolders.

## running dev environments via mprocs

In this repository, there are `mprocs*.json` files. Each one creates a unique dev environment by starting multiple cli processes. The default one, `mprocs.json`, can be started by just executing `mprocs`. It starts up everything you need for frontend development, connecting to APIs in the cloud based staging environments. When `mprocs` is running, you can simply switch panes using `Ctrl+a`.

If you need to work on APIs as well, you can execute different mprocs configurations. For example, in order to work on the unified api, run `mprocs -c mprocs-unified-api.json` instead, which will spin up the unified API locally next to the frontends.
