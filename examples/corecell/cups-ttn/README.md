# TTN CUPS Configuration for LoRa Basic Station

This folder contains everything needed to run a LoRa gateway with The Things Network using CUPS (Configuration and Update Server).

## Quick Start

1. **Build the station binary** (from repository root):
   ```bash
   make platform=corecell variant=std
   ```

2. **Run the setup script** (from repository root):
   ```bash
   ./setup-gateway.sh
   ```
   The script will prompt you for:
   - TTN Region (EU1, NAM1, or AU1)
   - Gateway EUI (16-character hex string)
   - CUPS API Key (from TTN Console)

3. **Start the gateway**:
   ```bash
   cd examples/corecell/cups-ttn
   ./start-station.sh
   ```
   Use `./start-station.sh -d` for debug output.

## Getting TTN Credentials

1. Go to [TTN Console](https://console.cloud.thethings.network/)
2. Select your region cluster
3. Go to **Gateways** and register your gateway (or select existing)
4. Note your **Gateway EUI**
5. Go to **API Keys** > **Add API Key**
6. Select permission: "Link as Gateway to a Gateway Server..."
7. Copy the generated key (shown only once!)

## Files in this Directory

| File | Git Tracked | Description |
|------|-------------|-------------|
| `start-station.sh` | Yes | Launch script for the gateway |
| `reset_lgw.sh` | Yes | GPIO reset script (auto-detects Pi model) |
| `rinit.sh` | Yes | Radio initialization wrapper |
| `station.conf.template` | Yes | Template for station configuration |
| `cups.uri.example` | Yes | Example CUPS server URL |
| `README.md` | Yes | This file |
| `station.conf` | No | Generated station config |
| `cups.uri` | No | CUPS server URL |
| `cups.key` | No | CUPS API key (sensitive!) |
| `cups.trust` | No | CUPS CA certificate |
| `tc.*` | No | Traffic controller files (auto-populated by CUPS) |

## Manual Setup

If you prefer manual setup instead of using `setup-gateway.sh`:

### cups.uri
Create this file with your CUPS server URL:
```
https://eu1.cloud.thethings.network:443
```

### cups.key
Create this file with the authorization header:
```
Authorization: Bearer NNSXS.YOUR_API_KEY_HERE...
```

### cups.trust
Download the CA certificate:
```bash
curl -o cups.trust https://letsencrypt.org/certs/isrgrootx1.pem
```

### station.conf
Copy from `station.conf.template` and replace:
- `{{GATEWAY_EUI}}` with your gateway EUI
- `{{INSTALL_DIR}}` with the basicstation installation path

## Hardware Support

The `reset_lgw.sh` script auto-detects the GPIO base offset for:
- Raspberry Pi 5 (GPIO base 571)
- Raspberry Pi 4/3/CM (GPIO base 512)
- Older Raspberry Pi models (GPIO base 0)

Configured for WM1302 SPI HAT with:
- SX1302 Reset: GPIO 17
- SX1302 Power Enable: GPIO 18
- SX1261 Reset: GPIO 5
