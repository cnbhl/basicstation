#!/bin/bash
#
# Start script for LoRa Basic Station with TTN CUPS
# This script is self-contained in the cups-ttn folder
#

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# Basic station root is 3 levels up
STATION_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Default to std variant
VARIANT=std

show_help() {
    echo -e "${GREEN}Usage: $0 [-d]${NC}"
    echo "  -d    Use debug variant of station"
    echo ""
    echo "Example:"
    echo "  ./start-station.sh        # Run with std variant"
    echo "  ./start-station.sh -d     # Run with debug variant"
}

while getopts "hd" opt; do
    case "$opt" in
        h) show_help; exit 0 ;;
        d) VARIANT=debug ;;
        *) show_help; exit 1 ;;
    esac
done

STATION_BIN="$STATION_ROOT/build-corecell-$VARIANT/bin/station"

# Check if binary exists
if [ ! -f "$STATION_BIN" ]; then
    echo -e "${RED}[ERROR] Station binary not found: $STATION_BIN${NC}"
    echo ""
    echo "Build it first with:"
    echo -e "  ${YELLOW}cd $STATION_ROOT && make platform=corecell variant=$VARIANT${NC}"
    exit 1
fi

# Check if credentials exist
if [ ! -f "$SCRIPT_DIR/cups.key" ]; then
    echo -e "${RED}[ERROR] Credentials not found!${NC}"
    echo ""
    echo "Run the setup script first:"
    echo -e "  ${YELLOW}$STATION_ROOT/setup-gateway.sh${NC}"
    exit 1
fi

# Check if station.conf exists
if [ ! -f "$SCRIPT_DIR/station.conf" ]; then
    echo -e "${RED}[ERROR] station.conf not found!${NC}"
    echo ""
    echo "Run the setup script first:"
    echo -e "  ${YELLOW}$STATION_ROOT/setup-gateway.sh${NC}"
    exit 1
fi

echo -e "${GREEN}Starting LoRa Basic Station...${NC}"
echo "  Variant:    $VARIANT"
echo "  Config dir: $SCRIPT_DIR"
echo "  Binary:     $STATION_BIN"
echo ""

# Start the station with this directory as home
exec "$STATION_BIN" -h "$SCRIPT_DIR"
