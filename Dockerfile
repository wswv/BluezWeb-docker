FROM python:3.9-slim

# 设置工作目录
WORKDIR /app

# 定义构建参数以支持自定义 UID 和 GID
ARG USER_UID=1000
ARG USER_GID=1000

# 安装系统依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    bluez \
    bluetooth \
    libglib2.0-dev \
    python3-dev \
    libbluetooth-dev \
    sudo \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 先复制 requirements.txt 以优化层缓存
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# 创建组和用户，基于指定的 UID 和 GID
RUN groupadd -g ${USER_GID} bluezgroup && \
    useradd -m -u ${USER_UID} -g ${USER_GID} -s /bin/bash bluezuser && \
    echo "bluezuser ALL=(ALL) NOPASSWD: /usr/lib/bluetooth/bluetoothd" >> /etc/sudoers.d/bluezuser

# 复制 D-Bus 配置文件
COPY bluezuser.conf /etc/dbus-1/system.d/bluezuser.conf

# 复制应用代码
COPY app.py .
COPY templates/ ./templates/
COPY entrypoint.sh .

# 设置入口脚本权限
RUN chmod +x entrypoint.sh

# 暴露 Flask 端口
EXPOSE 5000

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:5000/ || exit 1

# 设置入口点
ENTRYPOINT ["./entrypoint.sh"]