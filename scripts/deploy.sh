#!/bin/bash

set -euo pipefail

APP_DIR="/opt/python-app"
SERVICE_NAME="python-app"

# Locate the app directory in the checked-out repository
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_APP_DIR="${SCRIPT_DIR}/../app"

echo "Starting Python application deployment..."

# Create application directory
sudo mkdir -p "$APP_DIR"

# Copy application files
sudo cp "$SOURCE_APP_DIR/app.py" "$APP_DIR/"
sudo cp "$SOURCE_APP_DIR/requirements.txt" "$APP_DIR/"

# Create Python virtual environment
sudo python3 -m venv "$APP_DIR/venv"

# Install dependencies
sudo "$APP_DIR/venv/bin/pip" install --upgrade pip
sudo "$APP_DIR/venv/bin/pip" install -r "$APP_DIR/requirements.txt"

# Create systemd service
sudo tee "/etc/systemd/system/${SERVICE_NAME}.service" > /dev/null <<EOF
[Unit]
Description=Python Flask Application
After=network.target

[Service]
User=ubuntu
WorkingDirectory=${APP_DIR}
ExecStart=${APP_DIR}/venv/bin/gunicorn --workers 2 --bind 0.0.0.0:5000 app:app
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Set ownership
sudo chown -R ubuntu:ubuntu "$APP_DIR"

# Start application service
sudo systemctl daemon-reload
sudo systemctl enable "$SERVICE_NAME"
sudo systemctl restart "$SERVICE_NAME"

echo "Deployment completed successfully."
sudo systemctl status "$SERVICE_NAME" --no-pager