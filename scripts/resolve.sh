#!/usr/bin/env bash
set -euo pipefail
image="ghcr.io/${GITHUB_REPOSITORY,,}"
digest=$(docker buildx imagetools inspect jellyfin/jellyfin:latest --format '{{json .Manifest}}' | jq -er '.digest')
[[ "$digest" =~ ^sha256:[a-f0-9]{64}$ ]]
base="jellyfin/jellyfin@$digest"
# Include every tracked file that controls the build, but exclude documentation.
definition=$(git ls-files -z Dockerfile .dockerignore scripts .github/workflows | sort -z | xargs -0 sha256sum | sha256sum | cut -d' ' -f1)
key=$(printf '%s\n%s\nlinux/amd64\n' "$digest" "$definition" | sha256sum | cut -d' ' -f1)
{
  echo "image=$image"
  echo "base=$base"
  echo "digest=$digest"
  echo "key=$key"
} >> "$GITHUB_OUTPUT"
