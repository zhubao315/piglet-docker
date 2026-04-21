#!/bin/bash
# PostgreSQL 初始化脚本

service postgresql start

# 设置 postgres 密码
sudo -u postgres psql -c "ALTER USER postgres PASSWORD '${POSTGRES_PASSWORD:-Vibe.Coding}';"

# 创建 vibe 数据库
sudo -u postgres createdb vibe 2>/dev/null || true

# 创建 vibe 用户
sudo -u postgres psql -c "CREATE USER vibe WITH PASSWORD '${POSTGRES_PASSWORD:-Vibe.Coding}';" 2>/dev/null || true
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE vibe TO vibe;" 2>/dev/null || true

# 启用扩展
sudo -u postgres psql -d vibe -c "CREATE EXTENSION IF NOT EXISTS vector;" 2>/dev/null || true
sudo -u postgres psql -d vibe -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;" 2>/dev/null || true
sudo -u postgres psql -d vibe -c "CREATE EXTENSION IF NOT EXISTS hstore;" 2>/dev/null || true

service postgresql stop
