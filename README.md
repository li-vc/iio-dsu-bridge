# iio-dsu-bridge

IIO Bridge to generate motion sensor data for a DSU server, enabling gyro/motion controls in Yuzu/Ryujinx/Cemu via CemuHook protocol.

## Supported Devices

- **ROG Ally** - Combined IMU device
- **Legion Go S** - Separate accelerometer and gyroscope IIO devices

## Especial Thanks to
 - [Tobi Demeco](https://github.com/TDemeco) (Legion Go S support + configs and other improvements)
 - [Christopher Lott](https://github.com/christopherl) (Legion Go S support)

## Quick Install (SteamOS Desktop Mode)

### Option 1: Desktop Shortcut
1. Download `install-iio-dsu-bridge.desktop` from the latest Release
2. In Dolphin, right-click it and click **Allow Launching** (or Properties → Permissions → “Is executable”)
3. Double-click it to run the installer
4. Select your device when prompted (ROG Ally or Legion Go S)

### Option 2: Terminal
```bash
bash <(curl -fsSL https://github.com/Sebalvarez97/iio-dsu-bridge/releases/latest/download/install.sh)
```

The installer will:
1. Ask which device you have
2. Download the binary and device-specific config
3. Create and enable a systemd user service
4. Start the bridge automatically

**View logs:** `journalctl --user -u iio-dsu-bridge -f`

## Manual Installation

If you prefer to install manually:

```bash
# 1. Download the binary
mkdir -p ~/.local/bin
curl -fL https://github.com/Sebalvarez97/iio-dsu-bridge/releases/latest/download/iio-dsu-bridge -o ~/.local/bin/iio-dsu-bridge
chmod +x ~/.local/bin/iio-dsu-bridge

# 2. Download the config for your device
mkdir -p ~/.config

# For ROG Ally:
curl -fL https://github.com/Sebalvarez97/iio-dsu-bridge/releases/latest/download/rog-ally.yaml -o ~/.config/iio-dsu-bridge.yaml

# For Legion Go S:
curl -fL https://github.com/Sebalvarez97/iio-dsu-bridge/releases/latest/download/legion-go-s.yaml -o ~/.config/iio-dsu-bridge.yaml

# 3. Create systemd service
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

# 4. Enable and start
systemctl --user daemon-reload
systemctl --user enable --now iio-dsu-bridge.service

# 5. Enable auto-start on boot (optional)
sudo loginctl enable-linger $USER
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

## Configuration

The config file is located at `~/.config/iio-dsu-bridge.yaml`

### ROG Ally Config

```yaml
mount_matrix:
  x: [1, 0, 0]
  y: [0, -1, 0]
  z: [0, 0, -1]
```

### Legion Go S Config

```yaml
accel_matrix:
  x: [1, 0, 0]
  y: [0, 1, 0]
  z: [0, 0, -1]

gyro_matrix:
  x: [1, 0, 0]
  y: [0, 0, 1]
  z: [0, 1, 0]
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

### No config file error
```
ERROR: No mount matrix configured.
```
You need a config file. Download the one for your device:
```bash
# ROG Ally
curl -fL https://github.com/Sebalvarez97/iio-dsu-bridge/releases/latest/download/rog-ally.yaml -o ~/.config/iio-dsu-bridge.yaml

# Legion Go S
curl -fL https://github.com/Sebalvarez97/iio-dsu-bridge/releases/latest/download/legion-go-s.yaml -o ~/.config/iio-dsu-bridge.yaml
```

## Uninstall

### Option 1: Script
```bash
bash <(curl -fsSL https://github.com/Sebalvarez97/iio-dsu-bridge/releases/latest/download/uninstall.sh)
```

### Option 2: Desktop Shortcut
Download and double-click `uninstall-iio-dsu-bridge.desktop`

### Option 3: Manual
```bash
systemctl --user disable --now iio-dsu-bridge.service
rm ~/.config/systemd/user/iio-dsu-bridge.service
rm ~/.local/bin/iio-dsu-bridge
rm ~/.config/iio-dsu-bridge.yaml
systemctl --user daemon-reload
```

## Building from Source

```bash
# Clone the repository
git clone https://github.com/Sebalvarez97/iio-dsu-bridge.git
cd iio-dsu-bridge

# Build
go build -o iio-dsu-bridge .

# Copy config for your device
cp examples/legion-go-s.yaml ~/.config/iio-dsu-bridge.yaml
# or
cp examples/rog-ally.yaml ~/.config/iio-dsu-bridge.yaml

# Run
./iio-dsu-bridge --log-every=25
```


 
