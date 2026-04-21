#!/bin/bash
set -e

echo "=========================================="
echo "  Piglet Runtime - Starting Services"
echo "=========================================="

# 初始化 PostgreSQL
echo "[1/6] Initializing PostgreSQL..."
service postgresql start
sudo -u postgres psql -c "ALTER USER postgres PASSWORD '${POSTGRES_PASSWORD:-Vibe.Coding}';" 2>/dev/null || true
sudo -u postgres createdb vibe 2>/dev/null || true
service postgresql stop

# 启动 PostgreSQL (后台)
echo "[2/6] Starting PostgreSQL..."
su - postgres -c "/usr/lib/postgresql/*/bin/postgres -D /var/lib/postgresql/data" &
sleep 2

# 启动 Claude API 代理
echo "[3/6] Starting Claude API Proxy..."
cd ${PIGSTY_HOME}
python proxy.py &
sleep 2

# 启动 Code-Server
echo "[4/6] Starting VS Code Server..."
code-server \
    --port ${CODE_PORT} \
    --password ${CODE_PASSWORD} \
    --auth password \
    --user-data-dir /data/code \
    &
sleep 2

# 启动 JupyterLab
echo "[5/6] Starting JupyterLab..."
cd /data/jupyter
${PIGSTY_HOME}/../jupytervenv/bin/jupyter lab \
    --ip=0.0.0.0 \
    --port=${JUPYTER_PORT} \
    --no-browser \
    --NotebookApp.password="${JUPYTER_PASSWORD}" \
    --NotebookApp.allow_origin='*' \
    &
sleep 2

# 启动 Nginx
echo "[6/6] Starting Nginx..."
nginx

echo ""
echo "=========================================="
echo "  Piglet Runtime Started!"
echo "=========================================="
echo "  API Proxy:  http://localhost:${API_PORT}/v1/messages"
echo "  Code-Server: http://localhost:${CODE_PORT}/"
echo "  JupyterLab:  http://localhost:${JUPYTER_PORT}/"
echo "  PostgreSQL: localhost:${PG_PORT} (postgres/${POSTGRES_PASSWORD})"
echo "=========================================="

# 保持容器运行
tail -f /dev/null
