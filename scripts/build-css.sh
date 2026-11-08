#!/usr/bin/env bash
# Rebuild the Tailwind stylesheet into static/css/main.<hash>.css.
# Run after adding Tailwind classes to layouts/ or content/ that don't show up on the page.
# Uses the build tools installed in the theme (run `npm install` in themes/tailbliss once).
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
theme="$root/themes/tailbliss"
tmp="$(mktemp)"
(cd "$theme" && npx postcss "$root/assets/css/site.css" -o "$tmp" --config "$theme" --env production --no-map)
# Guard against a silent no-op build (e.g. PostCSS config not found) before replacing the live stylesheet
if ! grep -q -- "--color-primary-600" "$tmp"; then
  echo "Build output doesn't look like Tailwind CSS; leaving static/css unchanged." >&2
  rm -f "$tmp"; exit 1
fi
hash="$(sha1sum "$tmp" | cut -c1-8)"
rm -f "$root"/static/css/main.*.css
mv "$tmp" "$root/static/css/main.$hash.css"
chmod 644 "$root/static/css/main.$hash.css"
echo "Wrote static/css/main.$hash.css"
