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
Access to the internet for pulling the pre-built Docker image.

Installation
1. Install Docker and Docker Compose
Run the following commands to install Docker and Docker Compose:
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker pi
sudo apt-get update && sudo apt-get install -y docker-compose
sudo reboot

2. Clone or Create Project Directory
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

3. Configure Docker Compose
Edit docker-compose.yml to set the correct image name. Replace <username> with your Docker Hub or GitHub Container Registry username:
image: docker.io/<username>/bluetooth-manager:latest

For GitHub Container Registry, use:
image: ghcr.io/<username>/bluetooth-manager:latest

4. (Optional) Configure Custom UID/GID
To match the Raspberry Pi's user (e.g., pi with UID=1000, GID=1000), create a .env file:
echo "USER_UID=1000" >> .env
echo "USER_GID=1000" >> .env

Check your UID/GID with id pi. If not specified, defaults to USER_UID=1000 and USER_GID=1000.
5. Run with Docker Compose
Pull and start the services:
docker-compose up -d

Alternatively, specify UID/GID directly:
USER_UID=1001 USER_GID=1001 docker-compose up -d

To enable Loki logging, uncomment the loki service and volumes in docker-compose.yml before running.
6. (Optional) Build Locally
If you need to build the image locally (e.g., for modifications), include all project files and run:
docker-compose build

Or build with Docker directly:
docker build -t bluetooth-manager .
docker run --net=host --cap-add=NET_ADMIN -v /var/run/dbus:/var/run/dbus -p 5000:5000 -e USER_UID=1000 -e USER_GID=1000 -t bluetooth-manager

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

Pre-built Image: Ensure the image field in docker-compose.yml points to the correct registry (e.g., docker.io/<username>/bluetooth-manager:latest or ghcr.io/<username>/bluetooth-manager:latest).
Custom UID/GID: Set via .env or environment variables to match the host system (check with id <username>).
Loki Logging: Optional. Remove python-logging-loki from requirements.txt and related code in app.py if not using Loki. Uncomment the loki service in docker-compose.yml to enable.
ARM Compatibility: Build for linux/arm64 (Raspberry Pi 4 or newer) or linux/arm/v7 (older models like Pi 3) via GitHub Actions.
Security: The D-Bus configuration is restricted to essential BlueZ interfaces. Avoid running with --privileged.
PyGObject Dependency: Requires libgirepository1.0-dev, gir1.2-glib-2.0, and libcairo2-dev for pycairo and gi module.

Troubleshooting

GitHub Actions Build Takes Over an Hour:

Cause: Slow dependency installation (PyGObject, pycairo), multi-architecture builds, or network/bandwidth issues.
Fix:
Limit GitHub Actions to linux/arm64 (or linux/arm/v7 for older Pi) in the workflow:platforms: linux/arm64


Enable Docker layer caching in the workflow:- name: Cache Docker layers
  uses: actions/cache@v3
  with:
    path: /tmp/.buildx-cache
    key: ${{ runner.os }}-buildx-${{ github.sha }}
    restore-keys: |
      ${{ runner.os }}-buildx-


Use a PyPI mirror to speed up pip install:RUN pip3 install --no-cache-dir -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple


Check GitHub Actions logs for slow steps (e.g., apt-get update, pip install).
Test locally to isolate the issue:docker build -t bluetooth-manager .


If timeouts occur, set a job timeout in the workflow:timeout-minutes: 30


Check GitHub status (https://www.githubstatus.com/) for service issues.




ERROR: failed to solve: process "/bin/sh -c pip3 install --no-cache-dir -r requirements.txt ..." did not complete successfully: exit code: 1:

Cause: Failure to install pycairo or PyGObject due to missing libcairo2-dev.
Fix:
Ensure libcairo2-dev is in the Dockerfile.
Add pycairo before PyGObject in requirements.txt.
Test locally:docker run -it python:3.9-slim bash
apt-get update && apt-get install -y libcairo2-dev libgirepository1.0-dev gir1.2-glib-2.0 gcc g++ pkg-config
pip3 install pycairo==1.25.1 PyGObject==3.42.2






ModuleNotFoundError: No module named 'gi':

Cause: PyGObject is missing.
Fix: Verify PyGObject in requirements.txt and libgirepository1.0-dev, gir1.2-glib-2.0 in Dockerfile. Rebuild:docker-compose build

Check:docker exec <container_id> python3 -c "import gi; print(gi.__version__)"




Can't open HCI socket: Address family not supported by protocol:

Cause: Bluetooth adapter is disabled or container lacks permissions.
Fix:
Enable adapter:sudo hciconfig hci0 up


Verify kernel modules:lsmod | grep bluetooth
sudo modprobe bluetooth
sudo modprobe btusb


Ensure docker-compose.yml has network_mode: host and cap_add: NET_ADMIN.




sudo: /usr/lib/bluetooth/bluetoothd: command not found:

Cause: bluetoothd binary is missing or at a different path.
Fix:
Verify bluez in Dockerfile:docker exec <container_id> dpkg -l | grep bluez


Check path in entrypoint.sh (/usr/libexec/bluetooth/bluetoothd).
Find path:docker exec <container_id> find / -name bluetoothd






Traceback involving dasbus and gi:

Cause: dasbus fails due to missing gi.
Fix: Same as ModuleNotFoundError: No module named 'gi'.


Image Not Found: Verify image in docker-compose.yml. Pull manually:
docker pull docker.io/<username>/bluetooth-manager:latest


Bluetooth Adapter Not Found: Enable adapter (hciconfig hci0 up).

D-Bus Errors: Verify /etc/dbus-1/system.d/bluezuser.conf permissions (644).

Web Interface Unreachable: Check port 5000 and Raspberry Pi IP.

Loki Not Working: Verify loki service and URL in app.py (http://loki:3100/loki/api/v1/push).


Future Improvements

Add support for GATT characteristic read/write and notifications.
Enhance web interface with WebSockets for real-time updates.
Implement authentication for web interface and API.
Optimize scanning duration and device filtering.

For issues or feature requests, please contact the project maintainer.
