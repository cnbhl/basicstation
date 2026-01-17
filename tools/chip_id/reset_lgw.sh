#!/bin/sh
# Reset script for SX1302 CoreCell / WM1302 on Raspberry Pi
# Auto-detects GPIO chip offset for different Raspberry Pi models

# =============================================================================
# WM1302 Physical GPIO Pin Definitions (active on WM1302 SPI HAT)
# See: https://wiki.seeedstudio.com/WM1302_module/
# =============================================================================
WM1302_RESET_GPIO=17      # SX1302 reset (physical pin 11)
WM1302_POWER_EN_GPIO=18   # SX1302 power enable (physical pin 12)
WM1302_SX1261_GPIO=5      # SX1261 reset (physical pin 29)

# WM1302 normally does NOT need AD5338R. Leave empty to disable.
WM1302_AD5338R_GPIO=""

# =============================================================================
# Auto-detect GPIO chip base offset for different Raspberry Pi models
# =============================================================================
detect_gpio_base() {
    GPIO_BASE=0

    # Method 1: Parse /sys/kernel/debug/gpio (requires root)
    if [ -r /sys/kernel/debug/gpio ]; then
        # Extract base from lines like "gpiochip0: GPIOs 512-569" or "GPIOs 571-624"
        GPIO_BASE=$(grep -m1 'gpiochip0:' /sys/kernel/debug/gpio 2>/dev/null | \
                    sed -n 's/.*GPIOs \([0-9]*\)-.*/\1/p')
    fi

    # Method 2: Check /sys/class/gpio/gpiochip*/base
    if [ -z "$GPIO_BASE" ] || [ "$GPIO_BASE" = "0" ]; then
        for chip in /sys/class/gpio/gpiochip*; do
            [ -f "$chip/base" ] || continue
            [ -f "$chip/label" ] || continue
            label=$(cat "$chip/label" 2>/dev/null)
            # Look for the main GPIO controller (pinctrl-bcm* or similar)
            case "$label" in
                *pinctrl*|*bcm*|*gpio*)
                    GPIO_BASE=$(cat "$chip/base" 2>/dev/null)
                    break
                    ;;
            esac
        done
    fi

    # Method 3: Fallback - detect by Raspberry Pi model
    if [ -z "$GPIO_BASE" ] || [ "$GPIO_BASE" = "0" ]; then
        if [ -f /proc/device-tree/model ]; then
            model=$(cat /proc/device-tree/model 2>/dev/null)
            case "$model" in
                *"Raspberry Pi 5"*)
                    GPIO_BASE=571
                    ;;
                *"Raspberry Pi 4"*|*"Raspberry Pi 3"*|*"Raspberry Pi Compute Module"*)
                    GPIO_BASE=512
                    ;;
                *"Raspberry Pi"*)
                    # Older models (Pi 1, Pi 2, Pi Zero)
                    GPIO_BASE=0
                    ;;
            esac
        fi
    fi

    # Final fallback
    [ -z "$GPIO_BASE" ] && GPIO_BASE=0

    echo "$GPIO_BASE"
}

# =============================================================================
# Calculate actual sysfs GPIO numbers
# =============================================================================
GPIO_BASE=$(detect_gpio_base)

SX1302_RESET_PIN=$((GPIO_BASE + WM1302_RESET_GPIO))
SX1302_POWER_EN_PIN=$((GPIO_BASE + WM1302_POWER_EN_GPIO))
SX1261_RESET_PIN=$((GPIO_BASE + WM1302_SX1261_GPIO))

if [ -n "$WM1302_AD5338R_GPIO" ]; then
    AD5338R_RESET_PIN=$((GPIO_BASE + WM1302_AD5338R_GPIO))
else
    AD5338R_RESET_PIN=""
fi

echo "Detected GPIO base offset: $GPIO_BASE"
echo "  SX1302 Reset:    GPIO $WM1302_RESET_GPIO -> sysfs $SX1302_RESET_PIN"
echo "  SX1302 Power EN: GPIO $WM1302_POWER_EN_GPIO -> sysfs $SX1302_POWER_EN_PIN"
echo "  SX1261 Reset:    GPIO $WM1302_SX1261_GPIO -> sysfs $SX1261_RESET_PIN"

WAIT_GPIO() { sleep 0.1; }

export_gpio() {
  pin="$1"
  [ -z "$pin" ] && return 0
  [ -d "/sys/class/gpio/gpio$pin" ] && return 0
  echo "$pin" > /sys/class/gpio/export 2>/dev/null || {
    echo "WARN: cannot export GPIO$pin (check numbering/offset)"
    return 0
  }
  WAIT_GPIO
}

set_dir() {
  pin="$1"; dir="$2"
  [ -z "$pin" ] && return 0
  echo "$dir" > "/sys/class/gpio/gpio$pin/direction" 2>/dev/null || true
  WAIT_GPIO
}

set_val() {
  pin="$1"; val="$2"
  [ -z "$pin" ] && return 0
  echo "$val" > "/sys/class/gpio/gpio$pin/value" 2>/dev/null || true
  WAIT_GPIO
}

unexport_gpio() {
  pin="$1"
  [ -z "$pin" ] && return 0
  [ -d "/sys/class/gpio/gpio$pin" ] || return 0
  echo "$pin" > /sys/class/gpio/unexport 2>/dev/null || true
  WAIT_GPIO
}

init() {
  export_gpio "$SX1302_RESET_PIN"
  export_gpio "$SX1261_RESET_PIN"
  export_gpio "$SX1302_POWER_EN_PIN"
  export_gpio "$AD5338R_RESET_PIN"

  set_dir "$SX1302_RESET_PIN" "out"
  set_dir "$SX1261_RESET_PIN" "out"
  set_dir "$SX1302_POWER_EN_PIN" "out"
  set_dir "$AD5338R_RESET_PIN" "out"
}

reset() {
  echo "CoreCell reset through GPIO$SX1302_RESET_PIN..."
  echo "SX1261 reset through GPIO$SX1261_RESET_PIN..."
  echo "CoreCell power enable through GPIO$SX1302_POWER_EN_PIN..."
  [ -n "$AD5338R_RESET_PIN" ] && echo "CoreCell ADC reset through GPIO$AD5338R_RESET_PIN..."

  set_val "$SX1302_POWER_EN_PIN" 1

  set_val "$SX1302_RESET_PIN" 1
  set_val "$SX1302_RESET_PIN" 0

  # optional SX1261
  set_val "$SX1261_RESET_PIN" 0
  set_val "$SX1261_RESET_PIN" 1

  # optional AD5338R
  if [ -n "$AD5338R_RESET_PIN" ]; then
    set_val "$AD5338R_RESET_PIN" 0
    set_val "$AD5338R_RESET_PIN" 1
  fi
}

term() {
  unexport_gpio "$SX1302_RESET_PIN"
  unexport_gpio "$SX1261_RESET_PIN"
  unexport_gpio "$SX1302_POWER_EN_PIN"
  unexport_gpio "$AD5338R_RESET_PIN"
}

case "$1" in
  start) term; init; reset ;;
  stop)  reset; term ;;
  *) echo "Usage: $0 {start|stop}"; exit 1 ;;
esac

exit 0
