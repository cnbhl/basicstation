#!/bin/bash
DIR="$(cd "$(dirname "$0")" && pwd)"

# Station hängt oft /dev/spidev0.0 als $1 an -> unbekanntes Argument = start
if [ "$1" = "stop" ]; then
  "$DIR/reset_lgw.sh" stop
else
  "$DIR/reset_lgw.sh" start
fi
