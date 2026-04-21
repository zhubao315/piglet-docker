#!/bin/bash
set -e

echo "=========================================="
echo "  Piglet Runtime - Starting Services"
echo "=========================================="

# 检查 Claude Code
if command -v claude &> /dev/null; then
    echo "[0/5] Claude Code: installed"
else
    echo "[0/5] Claude Code: not found (optional)"
fi

# 启动 PostgreSQL (后台)
echo "[1/5] Starting PostgreSQL..."
su - postgres -c "/usr/lib/postgresql/*/bin/postgres -D /var/lib/postgresql/data" &
sleep 3

# 配置 PostgreSQL
echo "[2/5] Configuring PostgreSQL..."
su - postgres -c "psql -c \"ALTER USER postgres PASSWORD '${POSTGRES_PASSWORD:-Vibe.Coding}';\"" 2>/dev/null || true
su - postgres -c "createdb vibe" 2>/dev/null || true
su - postgres -c "psql -c 'CREATE EXTENSION IF NOT EXISTS vector;'" 2>/dev/null || true

# 启动 Claude API 代理
echo "[3/5] Starting Claude API Proxy..."
cd ${PIGSTY_HOME}
python3 proxy.py &
sleep 2

# 启动 Code-Server
echo "[4/5] Starting VS Code Server..."
code-server \
    --port ${CODE_PORT} \
    --password ${CODE_PASSWORD} \
    --auth password \
    --user-data-dir /data/code \
    &
sleep 2

# 启动 JupyterLab
echo "[5/5] Starting JupyterLab..."
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
