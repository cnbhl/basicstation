#!/bin/bash
#
# LoRa Basic Station Setup Script for Raspberry Pi 5 with TTN
# This script configures the gateway credentials for The Things Network
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CUPS_DIR="$SCRIPT_DIR/examples/corecell/cups-ttn"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN} LoRa Basic Station Setup for TTN${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if credentials already exist
if [ -f "$CUPS_DIR/cups.key" ]; then
    echo -e "${YELLOW}Warning: Credentials already exist in $CUPS_DIR${NC}"
    read -p "Do you want to overwrite them? (y/N): " overwrite
    if [ "$overwrite" != "y" ] && [ "$overwrite" != "Y" ]; then
        echo "Setup cancelled."
        exit 0
    fi
fi

# Step 1: Select TTN Region
echo -e "${GREEN}Step 1: Select your TTN region${NC}"
echo "  1) EU1  - Europe (eu1.cloud.thethings.network)"
echo "  2) NAM1 - North America (nam1.cloud.thethings.network)"
echo "  3) AU1  - Australia (au1.cloud.thethings.network)"
echo ""
read -p "Enter region number [1-3]: " region_choice

case $region_choice in
    1) TTN_REGION="eu1" ;;
    2) TTN_REGION="nam1" ;;
    3) TTN_REGION="au1" ;;
    *)
        echo -e "${RED}Invalid selection. Defaulting to EU1.${NC}"
        TTN_REGION="eu1"
        ;;
esac

CUPS_URI="https://${TTN_REGION}.cloud.thethings.network:443"
echo -e "Selected: ${GREEN}$CUPS_URI${NC}"
echo ""

# Step 2: Gateway EUI
echo -e "${GREEN}Step 2: Enter your Gateway EUI${NC}"
echo "This is a 16-character hex string (e.g., AABBCCDDEEFF0011)"
echo "You can find this in your TTN Console under Gateway settings."
echo ""
read -p "Gateway EUI: " GATEWAY_EUI

# Validate Gateway EUI format
if ! [[ "$GATEWAY_EUI" =~ ^[0-9A-Fa-f]{16}$ ]]; then
    echo -e "${RED}Warning: Gateway EUI should be 16 hex characters.${NC}"
    read -p "Continue anyway? (y/N): " continue_anyway
    if [ "$continue_anyway" != "y" ] && [ "$continue_anyway" != "Y" ]; then
        echo "Setup cancelled."
        exit 1
    fi
fi

# Convert to uppercase
GATEWAY_EUI=$(echo "$GATEWAY_EUI" | tr '[:lower:]' '[:upper:]')
echo -e "Gateway EUI: ${GREEN}$GATEWAY_EUI${NC}"
echo ""

# Step 3: CUPS API Key
echo -e "${GREEN}Step 3: Enter your CUPS API Key${NC}"
echo "Generate this in TTN Console: Gateway > API Keys > Add API Key"
echo "Required rights: 'Link as Gateway to a Gateway Server for traffic exchange, i.e. write uplink and read downlink'"
echo ""
echo "Paste your API key (it will not be displayed):"
read -s CUPS_KEY
echo ""

if [ -z "$CUPS_KEY" ]; then
    echo -e "${RED}Error: API key cannot be empty.${NC}"
    exit 1
fi

echo -e "${GREEN}API key received.${NC}"
echo ""

# Step 4: Download TTN Trust Certificate
echo -e "${GREEN}Step 4: Downloading TTN trust certificate...${NC}"

# TTN uses Let's Encrypt certificates, we need the ISRG Root X1
TRUST_CERT="$CUPS_DIR/cups.trust"
curl -sf https://letsencrypt.org/certs/isrgrootx1.pem -o "$TRUST_CERT"

if [ ! -f "$TRUST_CERT" ] || [ ! -s "$TRUST_CERT" ]; then
    echo -e "${YELLOW}Could not download certificate. Using system CA bundle...${NC}"
    # Fallback to system CA certificates
    if [ -f /etc/ssl/certs/ca-certificates.crt ]; then
        cp /etc/ssl/certs/ca-certificates.crt "$TRUST_CERT"
    else
        echo -e "${RED}Error: Could not obtain trust certificate.${NC}"
        exit 1
    fi
fi
echo -e "${GREEN}Trust certificate saved.${NC}"
echo ""

# Step 5: Create credential files
echo -e "${GREEN}Step 5: Creating credential files...${NC}"

# Create cups.uri
echo "$CUPS_URI" > "$CUPS_DIR/cups.uri"
echo "  Created: cups.uri"

# Create cups.key with proper format
# TTN expects: Authorization: <key>
echo "Authorization: Bearer $CUPS_KEY" > "$CUPS_DIR/cups.key"
echo "  Created: cups.key"

# Create empty tc.* files (will be populated by CUPS)
touch "$CUPS_DIR/tc.uri"
touch "$CUPS_DIR/tc.key"
touch "$CUPS_DIR/tc.trust"
touch "$CUPS_DIR/tc.crt"
echo "  Created: tc.* placeholder files"

# Step 6: Generate station.conf from template
echo -e "${GREEN}Step 6: Generating station.conf...${NC}"

if [ -f "$CUPS_DIR/station.conf.template" ]; then
    sed -e "s|{{GATEWAY_EUI}}|$GATEWAY_EUI|g" \
        -e "s|{{INSTALL_DIR}}|$SCRIPT_DIR|g" \
        "$CUPS_DIR/station.conf.template" > "$CUPS_DIR/station.conf"
    echo "  Created: station.conf"
else
    echo -e "${YELLOW}Warning: station.conf.template not found. Please configure station.conf manually.${NC}"
fi

# Step 7: Set permissions
echo -e "${GREEN}Step 7: Setting file permissions...${NC}"
chmod 600 "$CUPS_DIR/cups.key" 2>/dev/null || true
chmod 600 "$CUPS_DIR/tc.key" 2>/dev/null || true
chmod 644 "$CUPS_DIR/cups.uri" 2>/dev/null || true
chmod 644 "$CUPS_DIR/cups.trust" 2>/dev/null || true
chmod 644 "$CUPS_DIR/station.conf" 2>/dev/null || true
echo "  Permissions set."

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN} Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Your gateway is configured with:"
echo "  Region:      $TTN_REGION"
echo "  Gateway EUI: $GATEWAY_EUI"
echo "  Config dir:  $CUPS_DIR"
echo ""
echo "To build the station binary (if not already done):"
echo -e "  ${YELLOW}make platform=corecell variant=std${NC}"
echo ""
echo "To start the gateway:"
echo -e "  ${YELLOW}cd $SCRIPT_DIR/examples/corecell${NC}"
echo -e "  ${YELLOW}./start-station.sh -l ./cups-ttn${NC}"
echo ""
echo -e "${YELLOW}Note: You may need to run start-station.sh with sudo for GPIO access.${NC}"
