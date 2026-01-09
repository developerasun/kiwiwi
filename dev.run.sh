#!/bin/sh
set -e

FLAG="$1"
FILENAME="$2"

# 1. always run application
echo "▶ Kiwiwi app start"
zig build run

# 2. 인자 없으면 여기서 종료
if [ -z "$FLAG" ]; then
  echo "✔ App running only (no apply)"
  exit 0
fi

# 3. 환경별 apply
case "$FLAG" in
  --test)
    echo "▶ Running test cases"
    zig build test --verbose
    ;;
  --one)
    echo "▶ Build and run one target file"
    zig run $FILENAME
    ;;
  *)
    echo "❌ Unknown FLAG: $FLAG"
    echo "Usage:"
    echo "  ./dev.run.sh         # build and run whole application"
    echo "  ./dev.run.sh --single [filename]  # build and run one target file"
    echo "  ./dev.run.sh --test   # run test suites"
    exit 1
    ;;
esac

echo "✔ Done"
