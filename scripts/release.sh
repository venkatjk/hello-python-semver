#!/usr/bin/env bash
# Works out the next semantic version from git history, checks that CHANGELOG.md
# has a matching entry, then creates and pushes the annotated tag vX.Y.Z.
#
# Usage:
#   bash scripts/release.sh            create and push the tag (run on main in CI)
#   bash scripts/release.sh --dry-run  validate only, create nothing (run on pull requests)
#
# Version rules, applied to the commits since the highest vX.Y.Z tag
# (or since the start of history, from 0.0.0, when no tag exists yet):
#   BREAKING CHANGE: footer or type!: prefix  -> major
#   feat: prefix                              -> minor
#   anything else                             -> patch
set -euo pipefail

CHANGELOG_FILE="${CHANGELOG_FILE:-CHANGELOG.md}"
DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
fi

fail() {
  echo "::error::$*"
  exit 1
}

# 1. Current version: highest vX.Y.Z tag, or 0.0.0 if there are none.
LAST_VERSION=$(git tag -l 'v*' | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | sed 's/^v//' | sort -V | tail -1 || true)
if [[ -z "$LAST_VERSION" ]]; then
  BASE_VERSION="0.0.0"
  RANGE="HEAD"
else
  BASE_VERSION="$LAST_VERSION"
  RANGE="v${LAST_VERSION}..HEAD"
fi
echo "Current version: ${BASE_VERSION} (commit range: ${RANGE})"

# 2. Nothing new since the last tag means nothing to release.
if [[ -z "$(git rev-list "$RANGE")" ]]; then
  echo "No commits since ${BASE_VERSION}; nothing to release."
  exit 0
fi

# 3. Choose the bump level from the commit messages.
MESSAGES=$(git log --format='%B' "$RANGE")
if grep -Eq '^[A-Za-z]+(\([^)]*\))?!:|^BREAKING[ -]CHANGE:' <<< "$MESSAGES"; then
  BUMP="major"
elif grep -Eq '^feat(\([^)]*\))?:' <<< "$MESSAGES"; then
  BUMP="minor"
else
  BUMP="patch"
fi

IFS=. read -r MAJOR MINOR PATCH <<< "$BASE_VERSION"
case "$BUMP" in
  major) MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0 ;;
  minor) MINOR=$((MINOR + 1)); PATCH=0 ;;
  patch) PATCH=$((PATCH + 1)) ;;
esac
NEXT_VERSION="${MAJOR}.${MINOR}.${PATCH}"
TAG="v${NEXT_VERSION}"
echo "Bump type: ${BUMP} -> next version: ${NEXT_VERSION}"

# 4. The tag must not exist yet.
if git rev-parse -q --verify "refs/tags/${TAG}" > /dev/null; then
  fail "Tag ${TAG} already exists. Check the commits and the existing tags."
fi

# 5. CHANGELOG.md must contain a dated heading for exactly this version, with at least one bullet.
[[ -f "$CHANGELOG_FILE" ]] || fail "${CHANGELOG_FILE} not found."

ESCAPED_VERSION=${NEXT_VERSION//./\\.}
HEADING_RE="^## \[${ESCAPED_VERSION}\] - [0-9]{4}-[0-9]{2}-[0-9]{2}\$"
if ! grep -Eq "$HEADING_RE" "$CHANGELOG_FILE"; then
  echo "CHANGELOG mismatch: no entry for ${NEXT_VERSION}."
  echo "Expected a heading such as: ## [${NEXT_VERSION}] - YYYY-MM-DD"
  echo "Latest headings found in ${CHANGELOG_FILE}:"
  grep -E '^## \[' "$CHANGELOG_FILE" | head -3 || true
  fail "${CHANGELOG_FILE} does not match the version ${NEXT_VERSION} that would be tagged. Add the entry, or correct the commit types, then push again."
fi

ENTRY=$(V="$NEXT_VERSION" awk '
  BEGIN { heading = "## [" ENVIRON["V"] "] - " }
  index($0, heading) == 1 { inside = 1; next }
  /^## \[/ { inside = 0 }
  inside
' "$CHANGELOG_FILE")
if ! grep -q '^- ' <<< "$ENTRY"; then
  fail "The [${NEXT_VERSION}] entry in ${CHANGELOG_FILE} has no bullet items."
fi
echo "CHANGELOG entry for ${NEXT_VERSION} found."

# 6. Dry run stops here.
if [[ "$DRY_RUN" == true ]]; then
  echo "Dry run: would create tag ${TAG} on $(git rev-parse --short HEAD)."
  exit 0
fi

# 7. Create the annotated tag on HEAD and push it. -c keeps the identity out of the repo config.
git -c user.name="github-actions[bot]" \
    -c user.email="41898282+github-actions[bot]@users.noreply.github.com" \
    tag -a "$TAG" -m "Release ${TAG}" HEAD
git push origin "refs/tags/${TAG}"
echo "Created and pushed ${TAG}."
