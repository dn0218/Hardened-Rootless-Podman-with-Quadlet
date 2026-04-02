#!/bin/bash
# Description: Deploy Hardened Nginx using Quadlet
# Usage: ./deploy-container.sh (Run as sysadmin)

# 确保不在 root 下运行
if [ "$(id -u)" -eq 0 ]; then
    echo "Error: Do not run this script as root. Run as the container-owner user."
    exit 1
fi

QUADLET_DIR="$HOME/.config/containers/systemd"
CONF_FILE="$QUADLET_DIR/app-server.container"

echo "--- Deploying Quadlet Container ---"

# 1. 创建目录
mkdir -p "$QUADLET_DIR"

# 2. 写入 Quadlet 配置 (使用 EOF 避免手动编辑)
cat <<EOF > "$CONF_FILE"
[Unit]
Description=Hardened Nginx Rootless Container

[Container]
Image=docker.io/library/nginx:latest
ContainerName=app-server
PublishPort=8080:80
AutoUpdate=image

[Service]
Restart=always

[Install]
WantedBy=default.target
EOF

echo "[1/2] Configuration written to $CONF_FILE"

# 3. 加载并启动
echo "[2/2] Reloading systemd and starting service..."
systemctl --user daemon-reload
systemctl --user reset-failed app-server.service
systemctl --user start app-server.service

# 4. 验证
if systemctl --user is-active --quiet app-server.service; then
    echo "SUCCESS: app-server.service is now running!"
    echo "Access your app at http://$(hostname -I | awk '{print $1}'):8080"
else
    echo "FAILED: Service did not start correctly. Check 'journalctl --user -xeu app-server.service'"
fi
