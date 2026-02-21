#!/usr/bin/env bash
set -euo pipefail

# DigitalOcean doctl CLI Installer
# Downloads and installs doctl, optionally authenticating with DigitalOcean.

VERSION="latest"
TOKEN="${DIGITALOCEAN_ACCESS_TOKEN:-}"
NO_AUTH=false

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  -v, --version VERSION   Version of doctl to install (default: latest)
  -t, --token TOKEN       DigitalOcean API token for authentication
  --no-auth               Skip authentication
  -h, --help              Show this help message

Examples:
  $(basename "$0") -v 1.98.1 -t do_xxxx
  $(basename "$0") -v latest --no-auth
EOF
  exit 0
}

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    -v|--version)
      VERSION="$2"
      shift 2
      ;;
    -t|--token)
      TOKEN="$2"
      shift 2
      ;;
    --no-auth)
      NO_AUTH=true
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Unknown option: $1"
      usage
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Detect platform and architecture
# ---------------------------------------------------------------------------
detect_platform() {
  local os arch

  case "$(uname -s)" in
    Linux*)  os="linux" ;;
    Darwin*) os="darwin" ;;
    MINGW*|MSYS*|CYGWIN*) os="windows" ;;
    *)
      echo "::error::Unsupported operating system: $(uname -s)" >&2
      exit 1
      ;;
  esac

  case "$(uname -m)" in
    x86_64|amd64)  arch="amd64" ;;
    aarch64|arm64) arch="arm64" ;;
    *)
      echo "::error::Unsupported architecture: $(uname -m)" >&2
      exit 1
      ;;
  esac

  echo "${os} ${arch}"
}

# ---------------------------------------------------------------------------
# Resolve the latest version from GitHub releases
# ---------------------------------------------------------------------------
resolve_version() {
  local version="$1"

  if [[ "${version}" == "latest" ]]; then
    echo "::group::Resolving latest doctl version" >&2
    version=$(
      curl -sS --fail \
        -H "Accept: application/vnd.github+json" \
        https://api.github.com/repos/digitalocean/doctl/releases/latest \
      | grep '"tag_name"' \
      | sed -E 's/.*"tag_name":\s*"v?([^"]+)".*/\1/'
    )
    if [[ -z "${version}" ]]; then
      echo "::error::Failed to resolve the latest doctl version" >&2
      exit 1
    fi
    echo "Resolved latest version: ${version}" >&2
    echo "::endgroup::" >&2
  fi

  # Strip leading 'v' if present
  version="${version#v}"
  echo "${version}"
}

# ---------------------------------------------------------------------------
# Download and install doctl
# ---------------------------------------------------------------------------
install_doctl() {
  local version="$1"
  local os="$2"
  local arch="$3"
  local ext="tar.gz"
  local install_dir="${HOME}/.local/bin"

  if [[ "${os}" == "windows" ]]; then
    ext="zip"
  fi

  local filename="doctl-${version}-${os}-${arch}.${ext}"
  local url="https://github.com/digitalocean/doctl/releases/download/v${version}/${filename}"

  echo "::group::Installing doctl ${version} (${os}/${arch})"
  echo "Downloading from: ${url}"

  local tmpdir
  tmpdir=$(mktemp -d)
  trap 'rm -rf "${tmpdir}"' EXIT

  if ! curl -sS --fail -L -o "${tmpdir}/${filename}" "${url}"; then
    echo "::error::Failed to download doctl ${version} from ${url}"
    exit 1
  fi

  # Extract the binary
  if [[ "${ext}" == "zip" ]]; then
    unzip -q "${tmpdir}/${filename}" -d "${tmpdir}"
  else
    tar -xzf "${tmpdir}/${filename}" -C "${tmpdir}"
  fi

  # Install the binary
  mkdir -p "${install_dir}"
  mv "${tmpdir}/doctl" "${install_dir}/doctl"
  chmod +x "${install_dir}/doctl"

  # Add to PATH for current and subsequent steps
  echo "${install_dir}" >> "${GITHUB_PATH:-/dev/null}"
  export PATH="${install_dir}:${PATH}"

  echo "doctl ${version} installed to ${install_dir}/doctl"
  echo "::endgroup::"
}

# ---------------------------------------------------------------------------
# Authenticate with DigitalOcean
# ---------------------------------------------------------------------------
authenticate() {
  local token="$1"

  if [[ -z "${token}" ]]; then
    echo "::warning::No token provided, skipping authentication"
    return
  fi

  echo "::group::Authenticating with DigitalOcean"
  doctl auth init --access-token "${token}"
  echo "Authentication successful"
  echo "::endgroup::"
}

# ---------------------------------------------------------------------------
# Verify installation
# ---------------------------------------------------------------------------
verify_installation() {
  echo "::group::Verifying doctl installation"
  if ! command -v doctl &>/dev/null; then
    echo "::error::doctl not found on PATH after installation"
    exit 1
  fi
  doctl version
  echo "::endgroup::"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
  local os arch
  read -r os arch <<< "$(detect_platform)"

  local resolved_version
  resolved_version=$(resolve_version "${VERSION}")

  install_doctl "${resolved_version}" "${os}" "${arch}"
  verify_installation

  if [[ "${NO_AUTH}" != "true" ]]; then
    authenticate "${TOKEN}"
  else
    echo "Skipping authentication (--no-auth)"
  fi
}

main
