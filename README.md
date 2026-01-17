# LoRa Basic Station - Raspberry Pi 5 + TTN CUPS Fork

This is a fork of [lorabasics/basicstation](https://github.com/lorabasics/basicstation) with added support for:

- **Raspberry Pi 5** GPIO compatibility
- **Automated setup** for The Things Network (TTN) using CUPS protocol
- **Automatic Gateway EUI detection** from SX1302/SX1303 chip
- **Systemd service** configuration

For general Basic Station documentation, building instructions, and protocol details, please refer to the [original repository](https://github.com/lorabasics/basicstation) and [official documentation](https://doc.sm.tc/station).

---

## Quick Start

```bash
git clone https://github.com/cnbhl/basicstation.git
cd basicstation
./setup-gateway.sh
```

The setup script guides you through a complete gateway configuration:

| Step | Description |
|------|-------------|
| 1 | Build the station binary |
| 2 | Select TTN region (EU1, NAM1, AU1) |
| 3 | Auto-detect Gateway EUI from SX1302 chip |
| 4 | Enter CUPS API Key from TTN Console |
| 5 | Download TTN trust certificate |
| 6 | Select log file location |
| 7 | Create credential files |
| 8 | Generate station.conf |
| 9 | Set file permissions |
| 10 | Configure systemd service (optional) |

---

## Features Added in This Fork

### Automated Setup Script

`setup-gateway.sh` provides a guided setup process for configuring Basic Station with TTN CUPS. It handles:

- Building the station binary
- Gateway EUI detection
- Credential file generation
- Certificate downloads
- Systemd service installation

### Gateway EUI Auto-Detection

The `chip_id` tool reads the unique EUI directly from the SX1302/SX1303 concentrator chip, eliminating manual entry:

```
Step 3: Detecting Gateway EUI from SX1302 chip...

Detected EUI from SX1302 chip: AABBCCDDEEFF0011

Use this EUI? (Y/n):
```

### Raspberry Pi 5 GPIO Support

The included reset scripts automatically detect the GPIO base offset for different Raspberry Pi models:

| Model | GPIO Base |
|-------|-----------|
| Raspberry Pi 5 | 571 |
| Raspberry Pi 4/3 | 512 |
| Older models | 0 |

### Systemd Service

Optional automatic service setup for running the gateway at boot:

```bash
sudo systemctl status basicstation.service   # Check status
sudo systemctl stop basicstation.service     # Stop service
sudo systemctl restart basicstation.service  # Restart service
sudo journalctl -u basicstation.service -f   # View live logs
```

### Manual Start

If you chose not to set up a service:

```bash
cd examples/corecell
./start-station.sh -l ./cups-ttn
```

---

## Repository Structure (Added Files)

```
basicstation/
├── setup-gateway.sh                      # Automated setup script
├── tools/
│   ├── README.md
│   └── chip_id/                          # EUI detection tool
│       ├── chip_id                       # Pre-built binary
│       ├── chip_id.c                     # Source code
│       ├── reset_lgw.sh                  # Pi 5 compatible reset
│       ├── LICENSE                       # Semtech BSD 3-Clause
│       └── README.md
└── examples/
    └── corecell/
        └── cups-ttn/                     # TTN CUPS configuration
            ├── station.conf.template
            ├── cups.uri.example
            ├── reset_lgw.sh              # Pi 5 compatible reset
            ├── start-station.sh
            ├── rinit.sh
            └── README.md
```

---

## Prerequisites

- Raspberry Pi 3/4/5 with SPI enabled
- SX1302 or SX1303 LoRa concentrator (e.g., WM1302, RAK2287)
- Gateway registered on [The Things Network](https://console.cloud.thethings.network/)
- CUPS API Key from TTN Console

---

## Third-Party Components

| Component | Source | License |
|-----------|--------|---------|
| chip_id | [Semtech sx1302_hal](https://github.com/Lora-net/sx1302_hal) | BSD 3-Clause |

---

## Upstream

This fork is based on [lorabasics/basicstation](https://github.com/lorabasics/basicstation) Release 2.0.6.

For complete documentation on Basic Station features, protocols (LNS, CUPS), configuration options, and supported platforms, see:

- **Repository:** https://github.com/lorabasics/basicstation
- **Documentation:** https://doc.sm.tc/station

---

## License

Basic Station is licensed under the BSD 3-Clause License. See [LICENSE](LICENSE) for details.

The `chip_id` tool is derived from Semtech sx1302_hal and is licensed under the Semtech BSD 3-Clause License. See [tools/chip_id/LICENSE](tools/chip_id/LICENSE).
