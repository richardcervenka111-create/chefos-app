#!/bin/sh
# One-time per clone: point git at the repo's committed hooks.
# (git can't auto-activate committed hooks — this is the standard workaround.)
cd "$(dirname "$0")/.." && git config core.hooksPath .githooks
echo "Hooks activated: $(git config core.hooksPath)"
