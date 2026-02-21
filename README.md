# DigitalOcean doctl Installer Action

This action installs the [doctl](https://docs.digitalocean.com/reference/doctl/)
CLI and optionally authenticates with DigitalOcean. It can be used as a
drop-in replacement for
[`digitalocean/action-doctl`](https://github.com/digitalocean/action-doctl).

## Features

- Install any version of doctl or default to the latest release
- Cross-platform support (Linux, macOS, Windows)
- Optional authentication with a DigitalOcean API token
- Lightweight composite action (no Node.js runtime required)

## Inputs

### `version`

Version of doctl to install (e.g. `1.98.1`). Defaults to `latest`.

- Default: `"latest"`
- Optional

### `token`

DigitalOcean API token for authentication.

- Optional

### `no_auth`

If set to `true`, skip authentication even if a token is provided.

- Default: `"false"`
- Optional

## Usage Examples

### Basic Usage

```yaml
- name: Install doctl
  uses: raisedadead/action-doctl-installer@v1
  with:
    token: ${{ secrets.DIGITALOCEAN_ACCESS_TOKEN }}
```

Once installed, `doctl` is available for all subsequent steps in the job.

### Install a Specific Version

```yaml
- name: Install doctl
  uses: raisedadead/action-doctl-installer@v1
  with:
    token: ${{ secrets.DIGITALOCEAN_ACCESS_TOKEN }}
    version: "1.98.1"
```

### Skip Authentication

```yaml
- name: Install doctl
  uses: raisedadead/action-doctl-installer@v1
  with:
    no_auth: "true"
```

### Full Workflow Example

```yaml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Install doctl
        uses: raisedadead/action-doctl-installer@v1
        with:
          token: ${{ secrets.DIGITALOCEAN_ACCESS_TOKEN }}

      - name: Log in to DigitalOcean Container Registry
        run: doctl registry login --expiry-seconds 1200

      - name: Deploy to Kubernetes
        run: |
          doctl kubernetes cluster kubeconfig save my-cluster
          kubectl apply -f k8s/
```

## Manual Usage

You can also run the entrypoint script directly:

```bash
# Install latest and authenticate
./entrypoint.sh -v latest -t do_xxxx

# Install a specific version without authentication
./entrypoint.sh -v 1.98.1 --no-auth

# View help
./entrypoint.sh -h
```

## License

Licensed under the [ISC](LICENSE) License. Feel free to extend, reuse, and
share.
