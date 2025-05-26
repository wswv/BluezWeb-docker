from flask import Flask, jsonify, render_template
from dasbus.connection import SystemBus
from dasbus.loop import EventLoop
import threading
import time
import logging
import logging_loki

app = Flask(__name__)

# 配置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("BluetoothManager")
handler = logging_loki.LokiHandler(
    url="http://loki:3100/loki/api/v1/push",
    tags={"application": "bluetooth-manager"},
    version="1"
)
logger.addHandler(handler)

# 初始化 D-Bus 连接
bus = SystemBus()
bluez = bus.get_proxy("org.bluez", "/org/bluez/hci0")

# 存储发现的设备
devices = []

def start_discovery():
    """启动蓝牙设备发现"""
    try:
        logger.info("Starting Bluetooth discovery")
        bluez.StartDiscovery()
        time.sleep(10)  # 扫描 10 秒
        bluez.StopDiscovery()
        # 获取设备列表
        obj_manager = bus.get_proxy("org.bluez", "/")
        objects = obj_manager.GetManagedObjects()
        global devices
        devices = []
        for path, interfaces in objects.items():
            if "org.bluez.Device1" in interfaces:
                devices.append({
                    "address": interfaces["org.bluez.Device1"]["Address"],
                    "name": interfaces["org.bluez.Device1"].get("Name", "Unknown"),
                    "paired": interfaces["org.bluez.Device1"]["Paired"],
                    "connected": interfaces["org.bluez.Device1"]["Connected"]
                })
        logger.info(f"Discovered {len(devices)} devices")
    except Exception as e:
        logger.error(f"Discovery failed: {str(e)}")

def get_gatt_services(address):
    """获取设备的 GATT 服务"""
    try:
        device_path = f"/org/bluez/hci0/dev_{address.replace(':', '_')}"
        obj_manager = bus.get_proxy("org.bluez", "/")
        objects = obj_manager.GetManagedObjects()
        services = []
        for path, interfaces in objects.items():
            if path.startswith(device_path) and "org.bluez.GattService1" in interfaces:
                services.append({
                    "uuid": interfaces["org.bluez.GattService1"]["UUID"],
                    "primary": interfaces["org.bluez.GattService1"]["Primary"]
                })
        logger.info(f"Retrieved {len(services)} GATT services for {address}")
        return services
    except Exception as e:
        logger.error(f"Failed to get GATT services for {address}: {str(e)}")
        return []

@app.route('/')
def index():
    """渲染网页界面"""
    return render_template('index.html')

@app.route('/api/scan', methods=['GET'])
def scan():
    """扫描蓝牙设备"""
    threading.Thread(target=start_discovery).start()
    logger.info("Triggered device scan")
    return jsonify({"status": "scanning"})

@app.route('/api/devices', methods=['GET'])
def get_devices():
    """返回发现的设备列表"""
    logger.info("Fetching device list")
    return jsonify(devices)

@app.route('/api/pair/<address>', methods=['POST'])
def pair_device(address):
    """配对指定设备"""
    try:
        device = bus.get_proxy("org.bluez", f"/org/bluez/hci0/dev_{address.replace(':', '_')}")
        device.Pair()
        logger.info(f"Paired with {address}")
        return jsonify({"status": "success", "message": f"Paired with {address}"})
    except Exception as e:
        logger.error(f"Pairing failed for {address}: {str(e)}")
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route('/api/connect/<address>', methods=['POST'])
def connect_device(address):
    """连接指定设备"""
    try:
        device = bus.get_proxy("org.bluez", f"/org/bluez/hci0/dev_{address.replace(':', '_')}")
        device.Connect()
        logger.info(f"Connected to {address}")
        return jsonify({"status": "success", "message": f"Connected to {address}"})
    except Exception as e:
        logger.error(f"Connection failed for {address}: {str(e)}")
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route('/api/disconnect/<address>', methods=['POST'])
def disconnect_device(address):
    """断开指定设备"""
    try:
        device = bus.get_proxy("org.bluez", f"/org/bluez/hci0/dev_{address.replace(':', '_')}")
        device.Disconnect()
        logger.info(f"Disconnected from {address}")
        return jsonify({"status": "success", "message": f"Disconnected from {address}"})
    except Exception as e:
        logger.error(f"Disconnection failed for {address}: {str(e)}")
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route('/api/services/<address>', methods=['GET'])
def get_services(address):
    """获取设备的 GATT 服务"""
    services = get_gatt_services(address)
    return jsonify(services)

if __name__ == '__main__':
    try:
        # 设置蓝牙适配器为可发现和可配对
        bluez.Powered = True
        bluez.Discoverable = True
        bluez.Pairable = True
        logger.info("Bluetooth adapter initialized")
        app.run(host='0.0.0.0', port=5000)
    except Exception as e:
        logger.error(f"Failed to initialize adapter: {str(e)}")