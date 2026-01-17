# Tools

This directory contains utility tools for the LoRa Basic Station gateway.

## Contents

### [chip_id/](chip_id/)

Gateway EUI detection tool that reads the unique identifier directly from the SX1302/SX1303 concentrator chip.

- **Source:** [Semtech sx1302_hal](https://github.com/Lora-net/sx1302_hal)
- **License:** BSD 3-Clause (Semtech)
- **Usage:** Used by `setup-gateway.sh` for automatic EUI detection

```bash
cd chip_id
sudo ./chip_id -d /dev/spidev0.0
```

## Adding New Tools

When adding third-party tools to this directory:

1. Create a subdirectory for the tool
2. Include the original LICENSE file
3. Add a README.md with source attribution
4. Document any modifications made
