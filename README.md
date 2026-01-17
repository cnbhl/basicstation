[![regr-tests](https://github.com/lorabasics/basicstation/actions/workflows/regr-tests.yml/badge.svg?branch=master)](https://github.com/lorabasics/basicstation/actions/workflows/regr-tests.yml?query=branch%3Amaster)

# LoRa Basics™ Station

[Basic Station](https://doc.sm.tc/station) is a LoRaWAN Gateway implementation, including features like

*  **Ready for LoRaWAN Classes A, B, and C**
*  **Unified Radio Abstraction Layer supporting Concentrator Reference Designs [v1.5](https://doc.sm.tc/station/gw_v1.5.html), [v2](https://doc.sm.tc/station/gw_v2.html) and [Corecell](https://doc.sm.tc/station/gw_corecell.html)**

*  **Powerful Backend Protocols** (read [here](https://doc.sm.tc/station/tcproto.html) and [here](https://doc.sm.tc/station/cupsproto.html))
    -  Centralized update and configuration management
    -  Centralized channel-plan management
    -  Centralized time synchronization and transfer
    -  Various authentication schemes (client certificate, auth tokens)
    -  Remote interactive shell

*  **Lean Design**
    -  No external software dependencies (except mbedTLS and libloragw/-v2)
    -  Portable C code, no C++, dependent only on GNU libc
    -  Easily portable to Linux-based gateways and embedded systems
    -  No dependency on local time keeping
    -  No need for incoming connections

## Documentation

The full documentation is available at [https://doc.sm.tc/station](https://doc.sm.tc/station).

### High Level Architecture

![High Level Station Architecture](https://doc.sm.tc/station/_images/architecture.png)

## Prerequisites

Building the Station binary from source, requires

* gcc (C11 with GNU extensions)
* GNU make
* git
* bash

## First Steps

The following is a three-step quick start guide on how to build and run Station. It uses a Raspberry Pi as host platform and assumes a Concentrator Reference Design 1.5 compatible radio board connected via SPI, and assumes that SPI port is enabled using the [raspi-config](https://www.raspberrypi.org/documentation/configuration/raspi-config.md) tool. In this example the build process is done on the target platform itself (the make environment also supports cross compilation in which case the toolchain is expected in `~/toolchain-$platform` - see [setup.gmk](setup.gmk)).

#### Step 1: Cloning the Station Repository

``` sourceCode
git clone https://github.com/lorabasics/basicstation.git
```

#### Step 2: Compiling the Station Binary

``` sourceCode
cd basicstation
make platform=rpi variant=std
```

The build process consists of the following steps:

*  Fetch and build dependencies, namely [mbedTLS](https://github.com/ARMmbed/mbedtls) and [libloragw](https://github.com/Lora-net/lora_gateway)
*  Setup build environment within subdirectory `build-$platform-$variant/`
*  Compile station source files into executable `build-$platform-$variant/bin/station`

#### Step 3: Running the Example Configuration on a Raspberry Pi

``` sourceCode
cd examples/live-s2.sm.tc
RADIODEV=/dev/spidev0.0 ../../build-rpi-std/bin/station
```

**Note:** The SPI device for the radio MAY be passed as an environment variable using `RADIODEV`.

The example configuration connects to a public test server [s2.sm.tc](wss://s2.sm.tc) through which Station fetches all required credentials and a channel plan matching the region as determined from the IP address of the gateway. Provided there are active LoRa devices in proximity, received LoRa frames are printed in the log output on `stderr`.

## Instruction for Supported Platfroms

#### Corecell Platform (Raspberry Pi as HOST + [SX1302CxxxxGW Concentrator](https://www.semtech.com/products/wireless-rf/lora-gateways/sx1302cxxxgw1))

##### Compile and Running the Example

``` sourceCode
cd basicstation
make platform=corecell variant=std
cd examples/corecell
./start-station.sh -l ./lns-ttn
```

This example configuration for Corecell connects to [The Things Network](https://www.thethingsnetwork.org/) public LNS. The example [station.conf](station.conf) file holds the required radio configurations and station fetches the channel plan from the configured LNS url ([tc.uri](tc.uri)).

Note: SPI port requires to be activated on Raspberry Pi thanks to [raspi-config](https://www.raspberrypi.org/documentation/configuration/raspi-config.md) tool.

#### Raspberry Pi 5 + SX1302/WM1302 with TTN CUPS (Automated Setup)

This repository includes an automated setup script for configuring a LoRaWAN gateway on Raspberry Pi 5 with The Things Network using CUPS protocol.

##### Features

* **Automatic EUI Detection** - Reads the Gateway EUI directly from the SX1302 chip using the included `chip_id` tool
* **Raspberry Pi 5 GPIO Support** - Includes reset scripts with automatic GPIO base offset detection for Pi 5 compatibility
* **TTN CUPS Integration** - Configures credentials for The Things Network CUPS protocol
* **Systemd Service** - Optional automatic service setup for running the gateway at boot

##### Quick Start

``` sourceCode
cd basicstation
./setup-gateway.sh
```

The setup script guides you through 10 steps:

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

##### Gateway EUI Auto-Detection

The setup script automatically detects the Gateway EUI from your SX1302 concentrator chip using the `chip_id` tool located in `tools/chip_id/`. This eliminates the need to manually look up or calculate the EUI.

``` sourceCode
Step 3: Detecting Gateway EUI from SX1302 chip...

Detected EUI from SX1302 chip: AABBCCDDEEFF0011

Use this EUI? (Y/n):
```

##### Running as a Service

If you choose to set up a systemd service, the gateway will:
* Start automatically on boot
* Restart on failure
* Log to the systemd journal

Useful service commands:
``` sourceCode
sudo systemctl status basicstation.service   # Check status
sudo systemctl stop basicstation.service     # Stop service
sudo systemctl restart basicstation.service  # Restart service
sudo journalctl -u basicstation.service -f   # View live logs
```

##### Manual Start

If you chose not to set up a service, start the gateway manually:
``` sourceCode
cd examples/corecell
./start-station.sh -l ./cups-ttn
```

##### Repository Structure

```
basicstation/
├── setup-gateway.sh              # Automated setup script
├── tools/
│   ├── README.md                 # Tools overview
│   └── chip_id/
│       ├── chip_id               # EUI detection binary
│       ├── chip_id.c             # Source code
│       ├── reset_lgw.sh          # Pi 5 compatible reset script
│       ├── LICENSE               # Semtech BSD 3-Clause License
│       └── README.md             # Tool documentation
└── examples/
    └── corecell/
        └── cups-ttn/             # TTN CUPS configuration directory
            ├── station.conf
            ├── cups.uri
            ├── cups.key
            └── cups.trust
```

##### Third-Party Components

The `chip_id` tool is derived from the [Semtech sx1302_hal](https://github.com/Lora-net/sx1302_hal) repository and is licensed under the BSD 3-Clause License. See [tools/chip_id/LICENSE](tools/chip_id/LICENSE) for details.

#### PicoCell Gateway (Linux OS as HOST + [SX1308 USB Reference design](https://www.semtech.com/products/wireless-rf/lora-gateways/sx1308p868gw))


##### Compile and Running the Example

``` sourceCode
cd basicstation
make platform=linuxpico variant=std
cd examples/live-s2.sm.tc
RADIODEV=/dev/ttyACM0 ../../build-linuxpico-std/bin/station
```

**Note:** The serial device for the PicoCell MAY be passed as an environment variable using `RADIODEV`.

## Next Steps

Next,

*  consult the help menu of Station via `station --help`,
*  inspect the `station.conf` and `cups-boot.*` [example configuration files](/examples/live-s2.sm.tc),
*  tune your local [configuration](https://doc.sm.tc/station/conf.html),
*  learn how to [compile Station](https://doc.sm.tc/station/compile.html) for your target platform.

Check out the other examples:

*  [Simulation Example](/examples/simulation) - An introduction to the simulation environment.
*  [CUPS Example](/examples/cups) - Demonstration of the CUPS protocol within the simulation environment.
*  [Station to Pkfwd Protocol Bridge Example](/examples/station2pkfwd) - Connect Basic Station to LNS supporting the legacy protocol.

## Usage

The Station binary accepts the following command-line options:

```
Usage: station [OPTION...]

  -d, --daemon               First check if another process is still alive. If
                             so do nothing and exit. Otherwise fork a worker
                             process to operate the radios and network
                             protocols. If the subprocess died respawn it with
                             an appropriate back off.
  -f, --force                If a station process is already running, kill it
                             before continuing with requested operation mode.
  -h, --home=DIR             Home directory for configuration files. Default is
                             the current working directory. Overrides
                             environment STATION_DIR.
  -i, --radio-init=cmd       Program/script to run before reinitializing radio
                             hardware. By default nothing is being executed.
                             Overrides environment STATION_RADIOINIT.
  -k, --kill                 Kill a currently running station process.
  -l, --log-level=LVL|0..7   Set a log level LVL=#loglvls# or use a numeric
                             value. Overrides environment STATION_LOGLEVEL.
  -L, --log-file=FILE[,SIZE[,ROT]]
                             Write log entries to FILE. If FILE is '-' then
                             write to stderr. Optionally followed by a max file
                             SIZE and a number of rotation files. If ROT is 0
                             then keep only FILE. If ROT is 1 then keep one
                             more old log file around. Overrides environment
                             STATION_LOGFILE.
  -N, --no-tc                Do not connect to a LNS. Only run CUPS
                             functionality.
  -p, --params               Print current parameter settings.
  -t, --temp=DIR             Temp directory for frequently written files.
                             Default is /tmp. Overrides environment
                             STATION_TEMPDIR.
  -x, --eui-prefix=id6       Turn MAC address into EUI by adding this prefix.
                             If the argument has value ff:fe00:0 then the EUI
                             is formed by inserting FFFE in the middle. If
                             absent use MAC or routerid as is. Overrides
                             environment STATION_EUIPREFIX.
  -?, --help                 Give this help list
      --usage                Give a short usage message
  -v, --version              Print station version.

Mandatory or optional arguments to long options are also mandatory or optional
for any corresponding short options.
```
