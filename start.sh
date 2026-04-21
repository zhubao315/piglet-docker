#!/bin/bash
set -e

echo "=========================================="
echo "  Piglet Runtime - Starting Services"
echo "=========================================="

# 安装 Claude Code (如果未安装)
if ! command -v claude &> /dev/null; then
    echo "[0/7] Installing Claude Code..."
    npm config set registry https://registry.npmmirror.com
    npm install -g @anthropic-ai/claude-code@latest || true
fi

# 初始化 PostgreSQL
echo "[1/7] Initializing PostgreSQL..."
service postgresql start
sudo -u postgres psql -c "ALTER USER postgres PASSWORD '${POSTGRES_PASSWORD:-Vibe.Coding}';" 2>/dev/null || true
sudo -u postgres createdb vibe 2>/dev/null || true
service postgresql stop

# 启动 PostgreSQL (后台)
echo "[2/7] Starting PostgreSQL..."
su - postgres -c "/usr/lib/postgresql/*/bin/postgres -D /var/lib/postgresql/data" &
sleep 2

# 启动 Claude API 代理
echo "[3/7] Starting Claude API Proxy..."
cd ${PIGSTY_HOME}
python proxy.py &
sleep 2

# 启动 Code-Server
echo "[4/7] Starting VS Code Server..."
code-server \
    --port ${CODE_PORT} \
    --password ${CODE_PASSWORD} \
    --auth password \
    --user-data-dir /data/code \
    &
sleep 2

# 启动 JupyterLab
echo "[5/7] Starting JupyterLab..."
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
echo "[6/7] Starting Nginx..."
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
