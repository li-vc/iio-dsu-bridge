# iio-dsu-bridge

IIO Bridge to generate motion sensor data for a DSU server, enabling gyro/motion controls in Yuzu/Ryujinx/Cemu via CemuHook protocol.

## Supported Devices

- **ROG Ally** - Combined IMU device (works out of the box)
- **Legion Go S** - Separate accelerometer and gyroscope IIO devices (requires config file)

## Quick Install (SteamOS Desktop Mode)

1. Download `install-iio-dsu-bridge.desktop` from the latest Release
2. In Dolphin, right-click it and click **Allow Launching**
3. Double-click it to run the installer

**View logs:** `journalctl --user -u iio-dsu-bridge -f`

## Legion Go S Setup

The Legion Go S requires a configuration file to correct sensor axis orientation:

```bash
# Copy the example config
mkdir -p ~/.config
cp examples/legion-go-s.yaml ~/.config/iio-dsu-bridge.yaml

# Restart the service
systemctl --user restart iio-dsu-bridge
```

Or create the config manually:

```bash
cat > ~/.config/iio-dsu-bridge.yaml << 'EOF'
accel_matrix:
  x: [1, 0, 0]
  y: [0, 1, 0]
  z: [0, 0, -1]

gyro_matrix:
  x: [1, 0, 0]
  y: [0, 1, 0]
  z: [0, 0, 1]
EOF
```

## Manual Installation

```bash
# Build
go build -o iio-dsu-bridge .

# Copy binary
mkdir -p ~/.local/bin
cp iio-dsu-bridge ~/.local/bin/
chmod +x ~/.local/bin/iio-dsu-bridge

# Create systemd service
mkdir -p ~/.config/systemd/user
cat > ~/.config/systemd/user/iio-dsu-bridge.service << 'EOF'
[Unit]
Description=IIO to DSU Bridge for Gyro/Motion Controls
After=default.target

[Service]
Type=simple
ExecStart=%h/.local/bin/iio-dsu-bridge --log-every=0
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF

# Enable and start
systemctl --user daemon-reload
systemctl --user enable --now iio-dsu-bridge.service

# Enable linger for auto-start without login
sudo loginctl enable-linger $USER
```

## Usage

```bash
# List detected IIO devices
./iio-dsu-bridge --list-iio

# Run with logging
./iio-dsu-bridge --log-every=25

# Debug mode (show raw and DSU values)
./iio-dsu-bridge --debug-raw --debug-dsu --log-every=10
```

## Command Line Options

| Flag | Default | Description |
|------|---------|-------------|
| `--list-iio` | false | List detected IIO devices and exit |
| `--name` | "" | IIO device name (empty = auto-detect) |
| `--iio-path` | "" | Explicit IIO device path (overrides --name) |
| `--addr` | 127.0.0.1:26760 | DSU server address |
| `--rate` | 250 | Output rate in Hz |
| `--log-every` | 25 | Print IMU data every N samples (0 = off) |
| `--set-scales` | true | Auto-set sensor scales if zero |
| `--set-rate` | true | Auto-set sampling frequency |
| `--debug-raw` | false | Show raw sensor values before transformation |
| `--debug-dsu` | false | Show final DSU packet values |

## Configuration File

Place configuration at `~/.config/iio-dsu-bridge.yaml`

### Separate Matrices (Legion Go S)

When accelerometer and gyroscope have different orientations:

```yaml
accel_matrix:
  x: [1, 0, 0]
  y: [0, 1, 0]
  z: [0, 0, -1]

gyro_matrix:
  x: [1, 0, 0]
  y: [0, 1, 0]
  z: [0, 0, 1]
```

### Single Matrix (ROG Ally)

When both sensors share the same orientation:

```yaml
mount_matrix:
  x: [1, 0, 0]
  y: [0, -1, 0]
  z: [0, 0, -1]
```

## Emulator Setup

### Cemu
1. Options → Input Settings → Select controller
2. Motion section → Set source to "DSU Client"
3. Server: `127.0.0.1`, Port: `26760`

### Yuzu/Citron
1. Emulation → Configure → Controls
2. Motion provider: `cemuhook/DSU`
3. Server: `127.0.0.1:26760`

### Ryujinx
1. Options → Settings → Input
2. Motion: `CemuHook compatible motion server`
3. Server: `127.0.0.1:26760`

## Troubleshooting

### No IIO devices found
```bash
ls -la /sys/bus/iio/devices/
lsmod | grep -i "iio\|hid_sensor"
```

### Permission denied
```bash
# Check device permissions
ls -la /sys/bus/iio/devices/iio:device*/in_*_raw

# Run with sudo to test
sudo ./iio-dsu-bridge --list-iio
```

### Gyro not responding
```bash
# Check if scales are set
./iio-dsu-bridge --list-iio

# Run with debug output
./iio-dsu-bridge --debug-raw --log-every=1
```

### Motion feels wrong (pulling back, jittery)
The mount matrix likely needs adjustment. Use `--debug-raw --debug-dsu` to diagnose, then adjust the matrix in the config file.

## Uninstall

```bash
systemctl --user disable --now iio-dsu-bridge.service
rm ~/.config/systemd/user/iio-dsu-bridge.service
rm ~/.local/bin/iio-dsu-bridge
rm ~/.config/iio-dsu-bridge.yaml
systemctl --user daemon-reload
```

Or download and double-click `uninstall-iio-dsu-bridge.desktop`.
