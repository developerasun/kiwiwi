#!/bin/sh
set -e

FLAG="$1"
FILENAME="$2"

listAvailableFlags() {
  echo "❌ Unknown FLAG: $FLAG"
  echo "Supported flags:"
  echo "  ./dev.run.sh         # build and run whole application"
  echo "  ./dev.run.sh --build-one [FILENAME]  # build and run one target file"
  echo "  ./dev.run.sh --test   # run test suites"
  echo "  ./dev.run.sh --cli [ARGS...]   # interact kiwiwi as a cli"
}

echo "▶ Kiwiwi app start"

if [ -z "$FLAG" ]; then
  echo "✔ App running only (no apply)"
  zig build run
  exit 0
fi

case "$FLAG" in
  --test)
    echo "▶ Running test cases"
    zig build test --verbose
    ;;
  --build-one)
    echo "▶ Build and run one target file"
    zig run $FILENAME
    ;;
  --cli)
    shift # discard the flag
    echo "▶ Build and run with forwarded arguments"
    zig build run -- "$@"
    ;;
  *)
    listAvailableFlags
    exit 1
    ;;
esac

echo "✔ Done"
