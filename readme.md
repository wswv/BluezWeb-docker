Bluetooth Manager Docker for Raspberry Pi
This project provides a Dockerized solution for managing Bluetooth devices on a Raspberry Pi using BlueZ (Linux Bluetooth protocol stack) and a Flask-based web interface. The web interface allows users to discover, pair, connect, disconnect, and browse GATT services of Bluetooth devices.
Features

Bluetooth Management: Discover, pair, connect, and disconnect Bluetooth devices via BlueZ.
Web Interface: A user-friendly interface built with Flask and styled with Tailwind CSS.
GATT Service Browsing: View GATT services of paired devices.
Logging: Integrated logging with support for Loki (optional) for debugging and monitoring.
Custom UID/GID: Support for custom user and group IDs at runtime to match host system permissions.
Secure D-Bus Configuration: Fine-grained D-Bus permissions for non-root user bluezuser.
Dockerized: Runs in a lightweight container, optimized for Raspberry Pi (ARM architecture).

Prerequisites

Raspberry Pi with a Bluetooth adapter (e.g., Raspberry Pi 4).
Docker and Docker Compose installed on the Raspberry Pi.
BlueZ installed on the host (sudo apt-get install bluez).
Access to the internet for pulling the pre-built Docker image.

Installation
1. Install Docker and Docker Compose
Run the following commands to install Docker and Docker Compose:
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker pi
sudo apt-get update && sudo apt-get install -y docker-compose
sudo reboot

2. Install BlueZ on Host
Ensure the BlueZ package is installed to manage the Bluetooth adapter:
sudo apt-get update
sudo apt-get install -y bluez
sudo hciconfig hci0 up
sudo systemctl enable bluetooth
sudo systemctl start bluetooth

3. Clone or Create Project Directory
Create a project directory and save the docker-compose.yml file:
mkdir bluetooth-manager
cd bluetooth-manager

Required file:

docker-compose.yml

If you need to modify or rebuild the application, include these files:

Dockerfile
requirements.txt
bluezuser.conf
entrypoint.sh
app.py
templates/index.html

Directory structure (for pre-built image, only docker-compose.yml is needed):
bluetooth-manager/
└── docker-compose.yml

4. Configure Docker Compose

image: docker.io/wswv/bluezweb-docker:latest

For GitHub Container Registry, use:
image: ghcr.io/wswv/bluezweb-docker:latest

5. (Optional) Configure Custom UID/GID
To match the Raspberry Pi's user (e.g., pi with UID=1000, GID=1000), create a .env file:
echo "USER_UID=1000" >> .env
echo "USER_GID=1000" >> .env

Check your UID/GID with id pi. If not specified, defaults to USER_UID=1000 and USER_GID=1000.
6. Run with Docker Compose
Pull and start the services:
docker-compose up -d

Alternatively, specify UID/GID directly:
USER_UID=1001 USER_GID=1001 docker-compose up -d

To enable Loki logging, uncomment the loki service and volumes in docker-compose.yml before running.
7. (Optional) Build Locally
If you need to build the image locally (e.g., for modifications), include all project files and run:
docker-compose build

Or build with Docker directly:
docker build -t bluetooth-manager .
docker run --net=host --cap-add=NET_ADMIN -v /var/run/dbus:/var/run/dbus -v /dev:/dev -p 5000:5000 -e USER_UID=1000 -e USER_GID=1000 -t bluetooth-manager

Usage

Access the Web Interface:Open a browser and navigate to http://<Raspberry-Pi-IP>:5000.

Click "Scan for Devices" to discover nearby Bluetooth devices.
Use the "Pair", "Connect", "Disconnect", or "View Services" buttons to manage devices.
GATT services for paired devices are displayed below the device list.


API Endpoints:

GET /api/scan: Start a Bluetooth device discovery (runs for 10 seconds).
GET /api/devices: Retrieve the list of discovered devices.
POST /api/pair/<address>: Pair with a device (e.g., POST /api/pair/00:11:22:33:44:55).
POST /api/connect/<address>: Connect to a paired device.
POST /api/disconnect/<address>: Disconnect from a connected device.
GET /api/services/<address>: Retrieve GATT services for a device.


View Logs:

Check container logs:docker-compose logs bluetooth-manager


If Loki is enabled, access logs via a Grafana dashboard connected to http://<Raspberry-Pi-IP>:3100.


Stop and Clean Up:Stop and remove containers:
docker-compose down

To remove Loki data (if enabled):
docker-compose down -v



File Structure

docker-compose.yml: Defines services for bluetooth-manager and optional loki logging.
Dockerfile (optional for local build): Defines the Docker image with BlueZ, PyGObject, pycairo, and Python dependencies.
requirements.txt (optional): Lists Python dependencies (flask, dasbus, pycairo, PyGObject, python-logging-loki).
bluezuser.conf (optional): D-Bus configuration for bluezuser to access BlueZ interfaces, located at /etc/dbus-1/system.d/bluezuser.conf.
entrypoint.sh (optional): Script to initialize the Bluetooth adapter, adjust UID/GID, and start the Flask app.
app.py (optional): Flask application with Bluetooth management logic and logging.
templates/index.html (optional): Web interface styled with Tailwind CSS.

Notes

Pre-built Image: Ensure the image field in docker-compose.yml points to the correct registry (e.g., docker.io/<username>/bluetooth-manager:latest).
Custom UID/GID: Set via .env or environment variables to match the host system (check with id <username>).
Loki Logging: Optional. Remove python-logging-loki from requirements.txt if not using Loki.
ARM Compatibility: Build for linux/arm64 (Raspberry Pi 4 or newer) or linux/arm/v7 (older models like Pi 3).
Security: Avoid running with --privileged. Use NET_ADMIN and D-Bus configuration.
Bluetooth Requirements: Host must have bluez installed and adapter enabled (hciconfig hci0 up).

Troubleshooting

sudo: hciconfig: command not found:

Cause: The bluez package is not installed on the Raspberry Pi host.
Fix:
Install bluez on the host:sudo apt-get update
sudo apt-get install -y bluez


Enable the Bluetooth adapter:sudo hciconfig hci0 up
hciconfig


Ensure the Bluetooth service is running:sudo systemctl enable bluetooth
sudo systemctl start bluetooth


Verify kernel modules:lsmod | grep bluetooth
sudo modprobe bluetooth
sudo modprobe btusb


Check hardware:dmesg | grep bluetooth
lsusb






Error: Bluetooth adapter not found or not supported:

Cause: Bluetooth adapter (hci0) is disabled or inaccessible.
Fix:
Verify host setup (see above).
Ensure docker-compose.yml includes:network_mode: host
cap_add:
  - NET_ADMIN
volumes:
  - /var/run/dbus:/var/run/dbus
  - /dev:/dev


Test in container:docker exec <container_id> hciconfig






ERROR: failed to solve: process "/bin/sh -c pip3 install ..."):

Cause: Missing dependencies for pycairo or PyGObject.
Fix: Verify libcairo2-dev, pycairo in Dockerfile and requirements.txt.


ModuleNotFoundError: No module named 'gi':

Cause: PyGObject is missing.
Fix: Verify PyGObject in requirements.txt and rebuild.


sudo: /usr/lib/bluetooth/bluetoothd: command not found:

Cause: Incorrect bluetoothd path.
Fix: Verify path (/usr/libexec/bluetooth/bluetoothd) in entrypoint.sh.


Other Issues: Check docker-compose.yml, D-Bus permissions, and port 5000.


Future Improvements

Add GATT characteristic read/write support.
Enhance web interface with WebSockets.
Implement authentication for web interface and API.
Optimize scanning duration.

For issues or feature requests, please contact the project maintainer.
