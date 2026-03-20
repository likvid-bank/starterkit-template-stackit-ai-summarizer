#!/usr/bin/env bash
set -euo pipefail

if command -v helm >/dev/null 2>&1; then
	helm version --short
	exit 0
fi

helm_version="v3.16.4"
os="$(uname | tr '[:upper:]' '[:lower:]')"
arch="$(uname -m)"
case "${arch}" in
x86_64) arch="amd64" ;;
aarch64 | arm64) arch="arm64" ;;
*)
	echo "Unsupported architecture: ${arch}" >&2
	exit 1
	;;
esac

curl -fsSL "https://get.helm.sh/helm-${helm_version}-${os}-${arch}.tar.gz" -o /tmp/helm.tar.gz
tar -xzf /tmp/helm.tar.gz -C /tmp
mkdir -p "${HOME}/.local/bin"
install -m 0755 "/tmp/${os}-${arch}/helm" "${HOME}/.local/bin/helm"
echo "${HOME}/.local/bin" >>"${GITHUB_PATH}"
export PATH="${HOME}/.local/bin:${PATH}"
helm version --short
