#!/bin/sh
# Propagate package.json version to the plugin manifests. Run by `npm version`.
set -eu

cd "$(dirname "$0")/.."
v=$(node -p "require('./package.json').version")

for f in .claude-plugin/plugin.json .codex-plugin/plugin.json; do
  perl -pi -e "s/\"version\": \"[^\"]*\"/\"version\": \"$v\"/" "$f"
  grep -q "\"version\": \"$v\"" "$f" || { echo "sync failed: $f" >&2; exit 1; }
  git add "$f"
done

echo "version $v"
