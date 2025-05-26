#!/bin/bash

# 动态调整 bluezuser 的 UID 和 GID
if [ -n "$USER_UID" ] && [ -n "$USER_GID" ]; then
  groupmod -g $USER_GID bluezgroup || groupadd -g $USER_GID bluezgroup
  usermod -u $USER_UID -g $USER_GID bluezuser || useradd -m -u $USER_UID -g $USER_GID -s /bin/bash bluezuser
  echo "bluezuser ALL=(ALL) NOPASSWD: /usr/libexec/bluetooth/bluetoothd" > /etc/sudoers.d/bluezuser
fi

# 检查 hciconfig 是否存在
if ! command -v hciconfig > /dev/null 2>&1; then
  echo "Error: hciconfig not found in container. Ensure 'bluez' is installed in the Dockerfile."
  exit 1
fi

# 检查蓝牙适配器是否存在
if ! hciconfig hci0 > /dev/null 2>&1; then
  echo "Error: Bluetooth adapter (hci0) not found or not supported"
  echo "Attempting to initialize adapter..."
  if ! sudo hciconfig hci0 up > /dev/null 2>&1; then
    echo "Failed to initialize hci0. Possible causes:"
    echo "- Host Bluetooth adapter is disabled or missing (run 'sudo hciconfig hci0 up' on host)"
    echo "- Host lacks 'bluez' package (run 'sudo apt-get install bluez' on host)"
    echo "- Container lacks NET_ADMIN capability or host network mode"
    echo "- /dev/hci0 not mounted (check docker-compose.yml)"
    echo "Run 'hciconfig' and 'sudo systemctl status bluetooth' on the host to verify."
    exit 1
  fi
fi

# 检查 bluetoothd 是否存在
BLUETOOTH_DAEMON="/usr/libexec/bluetooth/bluetoothd"
if [ ! -f "$BLUETOOTH_DAEMON" ]; then
  echo "Error: bluetoothd not found at $BLUETOOTH_DAEMON"
  exit 1
fi

# 重置蓝牙适配器
sudo hciconfig hci0 down
sudo hciconfig hci0 up

# 启动 BlueZ 服务
sudo $BLUETOOTH_DAEMON &

# 等待 BlueZ 服务启动
sleep 2

# 以 bluezuser 用户运行 Flask 应用
exec su bluezuser -c "python3 /app/app.py"