#!/bin/sh
set -eu

cd "$(dirname "$0")/.."
exec npx --yes tokenx@latest skills/*/SKILL.md
