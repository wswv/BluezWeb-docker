#!/bin/bash

# 重置蓝牙适配器以避免启动失败
sudo hciconfig hci0 down
sudo hciconfig hci0 up

# 启动 BlueZ 服务
sudo /usr/lib/bluetooth/bluetoothd &

# 等待 BlueZ 服务启动
sleep 2

# 以 bluezuser 用户运行 Flask 应用
exec su bluezuser -c "python3 /app/app.py"