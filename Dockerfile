FROM python:3.9-slim

# 设置工作目录
WORKDIR /app

# 升级 pip 以确保依赖解析
RUN pip3 install --no-cache-dir --upgrade pip

# 安装系统依赖，包括 gi 和 pycairo 所需的依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    bluez \
    bluetooth \
    libglib2.0-dev \
    python3-dev \
    libbluetooth-dev \
    sudo \
    libgirepository1.0-dev \
    gir1.2-glib-2.0 \
    libcairo2-dev \
    gcc \
    g++ \
    pkg-config \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 先复制 requirements.txt 以优化层缓存
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt \
    && apt-get purge -y --auto-remove gcc g++ pkg-config

# 创建默认组和用户（UID/GID 将在运行时动态调整）
RUN groupadd -g 1000 bluezgroup && \
    useradd -m -u 1000 -g 1000 -s /bin/bash bluezuser

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
    CMD curl -f http://localhost:5000 || exit 1

# 设置入口点
ENTRYPOINT ["./entrypoint.sh"]