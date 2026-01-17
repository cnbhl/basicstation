#!/bin/sh
DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
case "$1" in
  stop) exec "$DIR/reset_lgw.sh" stop ;;
  *)    exec "$DIR/reset_lgw.sh" start ;;
esac
