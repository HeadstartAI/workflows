#!/usr/bin/env bash
#
# Publish a new version of the shared reusable workflows in this repo.
#
# Creates an immutable semver tag (vX.Y.Z) at HEAD, moves the major
# alias tag (vX) to point at it, and pushes both — mirroring the
# convention used by actions like actions/checkout@v6.
#
# Usage:
#   scripts/release.sh 1.2.3
#   scripts/release.sh v1.2.3
#
set -euo pipefail

DEFAULT_BRANCH="main"

if [ $# -ne 1 ]; then
  echo "Usage: $0 <version>  (e.g. 1.2.3 or v1.2.3)" >&2
  exit 1
fi

raw_version="$1"
version="${raw_version#v}"

if ! [[ "$version" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
  echo "Error: '$raw_version' is not a valid plain SemVer version (expected X.Y.Z)." >&2
  exit 1
fi

major="${BASH_REMATCH[1]}"
release_tag="v${version}"
alias_tag="v${major}"

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

current_branch="$(git rev-parse --abbrev-ref HEAD)"
if [ "$current_branch" != "$DEFAULT_BRANCH" ]; then
  echo "Error: must be on '$DEFAULT_BRANCH' to release (currently on '$current_branch')." >&2
  exit 1
fi

if [ -n "$(git status --porcelain)" ]; then
  echo "Error: working tree is not clean. Commit or stash changes first." >&2
  exit 1
fi

echo "Fetching tags from origin..."
git fetch origin --tags --quiet

if git rev-parse -q --verify "refs/tags/${release_tag}" >/dev/null \
  || git ls-remote --tags origin "refs/tags/${release_tag}" | grep -q .; then
  echo "Error: tag '${release_tag}' already exists locally or on origin. Immutable tags cannot be reused." >&2
  exit 1
fi

local_head_behind_remote="$(git rev-list --left-right --count "origin/${DEFAULT_BRANCH}...HEAD" 2>/dev/null | awk '{print $1}')"
if [ -n "${local_head_behind_remote:-}" ] && [ "$local_head_behind_remote" != "0" ]; then
  echo "Error: local '${DEFAULT_BRANCH}' is behind 'origin/${DEFAULT_BRANCH}'. Pull first." >&2
  exit 1
fi

commit_sha="$(git rev-parse HEAD)"
echo "Releasing ${release_tag} (alias ${alias_tag}) at ${commit_sha} on ${DEFAULT_BRANCH}."
read -r -p "Force-update moving alias tag '${alias_tag}' to this release? [y/N] " confirm_alias

echo "Creating annotated tag ${release_tag}..."
git tag -a "$release_tag" -m "Release ${release_tag}"

echo "Pushing immutable tag ${release_tag}..."
git push origin "refs/tags/${release_tag}"

if [[ "$confirm_alias" =~ ^[Yy]$ ]]; then
  echo "Moving alias tag ${alias_tag} -> ${release_tag}..."
  git tag -f "$alias_tag" "$release_tag"
  echo "Force-pushing alias tag ${alias_tag}..."
  git push --force origin "refs/tags/${alias_tag}"
else
  echo "Skipped updating alias tag '${alias_tag}'. Consumers pinned to '${alias_tag}' will not see this release."
fi

echo "Done. Published ${release_tag}."
