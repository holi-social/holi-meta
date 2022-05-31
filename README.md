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

For installing the Android Emulator needed for running the mobile dev environment, please read the [`readme`](holi-frontends/README.md) in `holi-frontends`.

