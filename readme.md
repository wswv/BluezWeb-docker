Bluetooth Manager Docker for Raspberry Pi
This project provides a Dockerized solution for managing Bluetooth devices on a Raspberry Pi using BlueZ (Linux Bluetooth protocol stack) and a Flask-based web interface. The web interface allows users to discover, pair, connect, disconnect, and browse GATT services of Bluetooth devices.
Features

Bluetooth Management: Discover, pair, connect, and disconnect Bluetooth devices via BlueZ.
Web Interface: A user-friendly interface built with Flask and styled with Tailwind CSS.
GATT Service Browsing: View GATT services of paired devices.
Logging: Integrated logging with support for Loki (optional) for debugging and monitoring.
Custom UID/GID: Support for custom user and group IDs to match host system permissions.
Secure D-Bus Configuration: Fine-grained D-Bus permissions for non-root user bluezuser.
Dockerized: Runs in a lightweight container, optimized for Raspberry Pi (ARM architecture).

Prerequisites

Raspberry Pi with a Bluetooth adapter (e.g., Raspberry Pi 4).
Docker and Docker Compose installed on the Raspberry Pi.
Access to the internet for building the Docker image and pulling dependencies.

Installation
1. Install Docker and Docker Compose
Run the following commands to install Docker and Docker Compose:
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker pi
sudo apt-get update && sudo apt-get install -y docker-compose
sudo reboot

2. Clone or Create Project Directory
Create a project directory and save the following files:
mkdir bluetooth-manager
cd bluetooth-manager
mkdir templates

Required files:

Dockerfile
requirements.txt
bluezuser.conf
entrypoint.sh
app.py
templates/index.html
docker-compose.yml

Ensure these files are placed in the correct directory structure:
bluetooth-manager/
├── Dockerfile
├── requirements.txt
├── bluezuser.conf
├── entrypoint.sh
├── app.py
├── docker-compose.yml
└── templates/
    └── index.html

3. (Optional) Configure Custom UID/GID
To match the Raspberry Pi's user (e.g., pi with UID=1000, GID=1000), create a .env file:
echo "USER_UID=1000" >> .env
echo "USER_GID=1000" >> .env

Check your UID/GID with id pi. If not specified, defaults to USER_UID=1000 and USER_GID=1000.
4. Build and Run with Docker Compose
Build and start the services:
docker-compose up -d

Alternatively, specify UID/GID directly:
USER_UID=1001 USER_GID=1001 docker-compose up -d

To enable Loki logging, uncomment the loki service and volumes in docker-compose.yml before running.
5. Build with Docker (Alternative)
If not using Docker Compose, build the image manually:
docker build --build-arg USER_UID=1000 --build-arg USER_GID=1000 -t bluetooth-manager .

Run the container:
docker run --net=host --cap-add=NET_ADMIN -v /var/run/dbus:/var/run/dbus -p 5000:5000 -t bluetooth-manager

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

Dockerfile: Defines the Docker image, including BlueZ, Python dependencies, and custom UID/GID support.
requirements.txt: Lists Python dependencies (flask, dasbus, python-logging-loki).
bluezuser.conf: D-Bus configuration for bluezuser to access BlueZ interfaces, located at /etc/dbus-1/system.d/bluezuser.conf.
entrypoint.sh: Script to initialize the Bluetooth adapter and start the Flask app.
app.py: Flask application with Bluetooth management logic and logging.
templates/index.html: Web interface styled with Tailwind CSS for device management.
docker-compose.yml: Defines services for bluetooth-manager and optional loki logging.

Notes

Custom UID/GID: Ensure the specified UID/GID match the host system to avoid permission issues. Check with id <username> on the Raspberry Pi.
Loki Logging: Optional. Remove python-logging-loki from requirements.txt and related code in app.py if not using Loki. Uncomment the loki service in docker-compose.yml to enable.
ARM Compatibility: Build the image on the Raspberry Pi to ensure ARM architecture compatibility.
Security: The D-Bus configuration is restricted to essential BlueZ interfaces. Avoid running the container with --privileged for better security.
Health Check: The bluetooth-manager service includes a health check to monitor the Flask server (curl http://localhost:5000).

Troubleshooting

Bluetooth Adapter Not Found: Ensure the Raspberry Pi's Bluetooth adapter is enabled (hciconfig hci0 up).
D-Bus Errors: Verify /etc/dbus-1/system.d/bluezuser.conf is correctly copied and permissions are set (644).
Web Interface Unreachable: Check if port 5000 is open and the Raspberry Pi's IP is correct.
Permission Issues: Confirm the container has NET_ADMIN capability and the D-Bus socket is mounted.
Loki Not Working: Ensure the loki service is uncommented in docker-compose.yml and the URL in app.py matches (http://loki:3100/loki/api/v1/push).

Future Improvements

Add support for GATT characteristic read/write and notifications.
Enhance the web interface with real-time updates using WebSockets.
Implement authentication for the web interface and API.
Optimize scanning duration and device filtering.

For issues or feature requests, please contact the project maintainer.
