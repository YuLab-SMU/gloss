#!/bin/sh
# Run a command inside the pinned bench container, from the repository root:
#   bench/docker/run.sh Rscript bench/R/harvest.R
# The repository is mounted read-only except bench/figures and bench/runs;
# sources, the container's package library and work directories live in the
# cache (~/.cache/gloss-bench, override with GLOSS_BENCH_CACHE).
set -eu
IMAGE=${GLOSS_BENCH_IMAGE:-$(cat "$(dirname "$0")/image")}
REPO=$(cd "$(dirname "$0")/../.." && pwd)
CACHE=${GLOSS_BENCH_CACHE:-$HOME/.cache/gloss-bench}
# CRAN snapshot of the day the image was built (2025-12-09), so packages added
# to the bench library match those already in the image
CRAN=${GLOSS_BENCH_CRAN:-https://p3m.dev/cran/__linux__/noble/2025-12-09}
mkdir -p "$CACHE" "$REPO/bench/figures" "$REPO/bench/runs"
# Forward the host's HTTP(S) proxy, if any: a direct route from the container
# failed 2 of 5 requests here (one hung, one timed out), the proxied route 0 of 12 (2026-11-09)
PROXY=""
for v in http_proxy https_proxy no_proxy; do
  val=$(printenv "$v" || true)
  [ -n "$val" ] || continue
  val=$(printf '%s' "$val" | sed -e 's#127\.0\.0\.1#host.docker.internal#g' -e 's#//localhost#//host.docker.internal#g')
  PROXY="$PROXY -e $v=$val"
done
# shellcheck disable=SC2086
exec docker run --rm $PROXY \
  -v "$REPO":/gloss:ro \
  -v "$REPO/bench/figures":/gloss/bench/figures \
  -v "$REPO/bench/runs":/gloss/bench/runs \
  -v "$CACHE":/cache \
  -e GLOSS_BENCH_CACHE=/cache \
  -e GLOSS_BENCH_CRAN="$CRAN" \
  -e GLOSS_BENCH_THIRD_PARTY="${GLOSS_BENCH_THIRD_PARTY:-}" \
  -e GLOSS_BENCH_IMAGE_DIGEST="$IMAGE" \
  -w /gloss \
  "$IMAGE" "$@"
